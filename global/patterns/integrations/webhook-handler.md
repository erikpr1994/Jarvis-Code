---
name: Webhook Handler
category: integration
language: typescript
framework: nextjs
keywords: [webhook, callback, event, stripe, github, external-api]
confidence: 0.9
---

# Webhook Handler Pattern

## Problem

Webhooks from external services require:
- Signature verification for security
- Idempotent processing
- Error handling without exposing internals
- Reliable event processing

## Solution

Implement secure webhook handlers with signature verification, idempotency keys, and proper error handling.

## Implementation

### Stripe Webhook Handler

```typescript
// app/api/webhooks/stripe/route.ts
import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';
import { db } from '@/lib/db';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!;

export async function POST(request: NextRequest) {
  const body = await request.text();
  const signature = request.headers.get('stripe-signature');

  if (!signature) {
    return NextResponse.json(
      { error: 'Missing signature' },
      { status: 400 },
    );
  }

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (error) {
    console.error('Webhook signature verification failed:', error);
    return NextResponse.json(
      { error: 'Invalid signature' },
      { status: 400 },
    );
  }

  // Idempotency check
  const existing = await db.webhookEvent.findUnique({
    where: { externalId: event.id },
  });

  if (existing) {
    // Already processed
    return NextResponse.json({ received: true });
  }

  // Record event
  await db.webhookEvent.create({
    data: {
      externalId: event.id,
      type: event.type,
      payload: event.data.object as any,
      status: 'processing',
    },
  });

  try {
    await handleStripeEvent(event);

    await db.webhookEvent.update({
      where: { externalId: event.id },
      data: { status: 'completed' },
    });
  } catch (error) {
    console.error('Webhook processing error:', error);

    await db.webhookEvent.update({
      where: { externalId: event.id },
      data: {
        status: 'failed',
        error: error instanceof Error ? error.message : 'Unknown error',
      },
    });

    // Return 200 to prevent Stripe from retrying
    // We'll handle retries ourselves
  }

  return NextResponse.json({ received: true });
}

async function handleStripeEvent(event: Stripe.Event) {
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutCompleted(event.data.object as Stripe.Checkout.Session);
      break;

    case 'customer.subscription.created':
    case 'customer.subscription.updated':
      await handleSubscriptionChange(event.data.object as Stripe.Subscription);
      break;

    case 'customer.subscription.deleted':
      await handleSubscriptionCanceled(event.data.object as Stripe.Subscription);
      break;

    case 'invoice.payment_failed':
      await handlePaymentFailed(event.data.object as Stripe.Invoice);
      break;

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }
}

async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  const userId = session.metadata?.userId;
  if (!userId) {
    throw new Error('No userId in session metadata');
  }

  await db.user.update({
    where: { id: userId },
    data: {
      stripeCustomerId: session.customer as string,
      subscriptionStatus: 'active',
    },
  });
}

async function handleSubscriptionChange(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  await db.user.updateMany({
    where: { stripeCustomerId: customerId },
    data: {
      subscriptionId: subscription.id,
      subscriptionStatus: subscription.status,
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    },
  });
}

async function handleSubscriptionCanceled(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  await db.user.updateMany({
    where: { stripeCustomerId: customerId },
    data: {
      subscriptionStatus: 'canceled',
    },
  });
}

async function handlePaymentFailed(invoice: Stripe.Invoice) {
  const customerId = invoice.customer as string;

  const user = await db.user.findFirst({
    where: { stripeCustomerId: customerId },
  });

  if (user) {
    // Send notification email
    await sendPaymentFailedEmail(user.email);
  }
}
```

### GitHub Webhook Handler

```typescript
// app/api/webhooks/github/route.ts
import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';
import { db } from '@/lib/db';

const webhookSecret = process.env.GITHUB_WEBHOOK_SECRET!;

function verifyGitHubSignature(
  payload: string,
  signature: string | null,
): boolean {
  if (!signature) return false;

  const expectedSignature = `sha256=${crypto
    .createHmac('sha256', webhookSecret)
    .update(payload)
    .digest('hex')}`;

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature),
  );
}

export async function POST(request: NextRequest) {
  const body = await request.text();
  const signature = request.headers.get('x-hub-signature-256');
  const event = request.headers.get('x-github-event');
  const deliveryId = request.headers.get('x-github-delivery');

  // Verify signature
  if (!verifyGitHubSignature(body, signature)) {
    return NextResponse.json(
      { error: 'Invalid signature' },
      { status: 401 },
    );
  }

  // Idempotency check
  if (deliveryId) {
    const existing = await db.webhookEvent.findUnique({
      where: { externalId: deliveryId },
    });

    if (existing) {
      return NextResponse.json({ received: true });
    }

    await db.webhookEvent.create({
      data: {
        externalId: deliveryId,
        type: `github.${event}`,
        payload: JSON.parse(body),
        status: 'processing',
      },
    });
  }

  const payload = JSON.parse(body);

  try {
    switch (event) {
      case 'push':
        await handlePush(payload);
        break;

      case 'pull_request':
        await handlePullRequest(payload);
        break;

      case 'issues':
        await handleIssue(payload);
        break;

      default:
        console.log(`Unhandled GitHub event: ${event}`);
    }

    if (deliveryId) {
      await db.webhookEvent.update({
        where: { externalId: deliveryId },
        data: { status: 'completed' },
      });
    }
  } catch (error) {
    console.error('GitHub webhook error:', error);

    if (deliveryId) {
      await db.webhookEvent.update({
        where: { externalId: deliveryId },
        data: {
          status: 'failed',
          error: error instanceof Error ? error.message : 'Unknown error',
        },
      });
    }
  }

  return NextResponse.json({ received: true });
}

async function handlePush(payload: any) {
  const { repository, commits, ref } = payload;

  // Only process main branch pushes
  if (ref !== 'refs/heads/main') return;

  // Trigger deployment or other actions
  await db.deployment.create({
    data: {
      repositoryId: repository.id.toString(),
      commitSha: payload.after,
      status: 'pending',
    },
  });
}

async function handlePullRequest(payload: any) {
  const { action, pull_request, repository } = payload;

  await db.pullRequest.upsert({
    where: {
      repositoryId_number: {
        repositoryId: repository.id.toString(),
        number: pull_request.number,
      },
    },
    create: {
      repositoryId: repository.id.toString(),
      number: pull_request.number,
      title: pull_request.title,
      status: action,
    },
    update: {
      title: pull_request.title,
      status: action,
    },
  });
}

async function handleIssue(payload: any) {
  // Handle issue events
}
```

### Generic Webhook Handler Factory

```typescript
// lib/webhook-handler.ts
import crypto from 'crypto';
import { NextRequest, NextResponse } from 'next/server';
import { db } from './db';

interface WebhookConfig {
  secret: string;
  signatureHeader: string;
  signaturePrefix?: string;
  idHeader?: string;
  typeHeader?: string;
  algorithm?: 'sha256' | 'sha1';
}

interface WebhookHandlers {
  [eventType: string]: (payload: any) => Promise<void>;
}

export function createWebhookHandler(
  config: WebhookConfig,
  handlers: WebhookHandlers,
) {
  return async function handler(request: NextRequest) {
    const body = await request.text();
    const signature = request.headers.get(config.signatureHeader);
    const eventId = config.idHeader
      ? request.headers.get(config.idHeader)
      : null;
    const eventType = config.typeHeader
      ? request.headers.get(config.typeHeader)
      : null;

    // Verify signature
    if (!verifySignature(body, signature, config)) {
      return NextResponse.json(
        { error: 'Invalid signature' },
        { status: 401 },
      );
    }

    // Idempotency check
    if (eventId) {
      const existing = await db.webhookEvent.findUnique({
        where: { externalId: eventId },
      });

      if (existing) {
        return NextResponse.json({ received: true });
      }

      await db.webhookEvent.create({
        data: {
          externalId: eventId,
          type: eventType || 'unknown',
          payload: JSON.parse(body),
          status: 'processing',
        },
      });
    }

    const payload = JSON.parse(body);

    try {
      // Find and execute handler
      const handler = eventType ? handlers[eventType] : handlers.default;

      if (handler) {
        await handler(payload);
      }

      if (eventId) {
        await db.webhookEvent.update({
          where: { externalId: eventId },
          data: { status: 'completed' },
        });
      }
    } catch (error) {
      console.error('Webhook processing error:', error);

      if (eventId) {
        await db.webhookEvent.update({
          where: { externalId: eventId },
          data: {
            status: 'failed',
            error: error instanceof Error ? error.message : 'Unknown',
          },
        });
      }
    }

    return NextResponse.json({ received: true });
  };
}

function verifySignature(
  payload: string,
  signature: string | null,
  config: WebhookConfig,
): boolean {
  if (!signature) return false;

  const algorithm = config.algorithm || 'sha256';
  const expectedSignature = crypto
    .createHmac(algorithm, config.secret)
    .update(payload)
    .digest('hex');

  const expected = config.signaturePrefix
    ? `${config.signaturePrefix}${expectedSignature}`
    : expectedSignature;

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected),
  );
}
```

### Webhook Event Model

```prisma
// schema.prisma
model WebhookEvent {
  id         String   @id @default(cuid())
  externalId String   @unique
  type       String
  payload    Json
  status     String   @default("pending") // pending, processing, completed, failed
  error      String?
  createdAt  DateTime @default(now())
  processedAt DateTime?

  @@index([type])
  @@index([status])
  @@index([createdAt])
}
```

## When to Use

- Payment processing (Stripe, PayPal)
- Repository events (GitHub, GitLab)
- Communication services (Twilio, SendGrid)
- Any external service callbacks

## Anti-patterns

```typescript
// BAD: No signature verification
export async function POST(request: NextRequest) {
  const body = await request.json();
  await processWebhook(body); // Anyone can call this!
}

// BAD: Exposing errors
catch (error) {
  return NextResponse.json({ error: error.message }, { status: 500 });
  // Leaks internal details
}

// BAD: No idempotency
async function handlePayment(payment: Payment) {
  await db.user.update({ credits: { increment: 100 } });
  // Double-processing on retry adds credits twice!
}

// BAD: Synchronous processing
await longRunningTask(payload);
return NextResponse.json({ received: true });
// Times out, Stripe retries, causes duplicates
```

```typescript
// GOOD: Verify signatures
const event = stripe.webhooks.constructEvent(body, signature, secret);

// GOOD: Generic error response
catch (error) {
  console.error('Webhook error:', error);
  // Don't expose details to caller
}
return NextResponse.json({ received: true });

// GOOD: Idempotent with event tracking
const existing = await db.webhookEvent.findUnique({ where: { externalId } });
if (existing) return; // Already processed

// GOOD: Async processing for long tasks
await queue.add('process-webhook', payload);
return NextResponse.json({ received: true }); // Respond immediately
```

## Related Patterns

- Queue Processing Pattern - For async webhook processing
- Error Handling Pattern - For webhook errors
- Logging Pattern - For webhook event logging
