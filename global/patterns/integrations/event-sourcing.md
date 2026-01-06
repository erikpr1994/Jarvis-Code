---
name: Event Sourcing
category: integration
language: typescript
framework: none
keywords: [events, sourcing, audit, history, cqrs, domain-events]
confidence: 0.8
---

# Event Sourcing Pattern

## Problem

Traditional CRUD operations lose history:
- No audit trail of changes
- Can't replay or undo operations
- Difficult to debug state issues
- Limited analytics on behavior

## Solution

Store state changes as a sequence of events. Current state is derived by replaying events, providing full audit trail and temporal query capability.

## Implementation

### Event Store Schema

```typescript
// schema.prisma
model Event {
  id            String   @id @default(cuid())
  aggregateId   String
  aggregateType String
  eventType     String
  version       Int
  payload       Json
  metadata      Json?
  createdAt     DateTime @default(now())
  createdBy     String?

  @@unique([aggregateId, version])
  @@index([aggregateId])
  @@index([aggregateType])
  @@index([eventType])
  @@index([createdAt])
}

// Snapshot for performance (optional)
model Snapshot {
  id            String   @id @default(cuid())
  aggregateId   String   @unique
  aggregateType String
  version       Int
  state         Json
  createdAt     DateTime @default(now())

  @@index([aggregateId])
}
```

### Event Types

```typescript
// lib/events/types.ts

export interface DomainEvent<T = unknown> {
  id: string;
  aggregateId: string;
  aggregateType: string;
  eventType: string;
  version: number;
  payload: T;
  metadata?: {
    userId?: string;
    correlationId?: string;
    causationId?: string;
    timestamp: string;
  };
}

// Order events
export type OrderCreatedEvent = DomainEvent<{
  customerId: string;
  items: Array<{
    productId: string;
    quantity: number;
    price: number;
  }>;
  total: number;
}>;

export type OrderItemAddedEvent = DomainEvent<{
  productId: string;
  quantity: number;
  price: number;
}>;

export type OrderSubmittedEvent = DomainEvent<{
  submittedAt: string;
}>;

export type OrderPaidEvent = DomainEvent<{
  paymentId: string;
  amount: number;
  method: string;
}>;

export type OrderShippedEvent = DomainEvent<{
  trackingNumber: string;
  carrier: string;
  shippedAt: string;
}>;

export type OrderCanceledEvent = DomainEvent<{
  reason: string;
  canceledAt: string;
}>;

export type OrderEvent =
  | OrderCreatedEvent
  | OrderItemAddedEvent
  | OrderSubmittedEvent
  | OrderPaidEvent
  | OrderShippedEvent
  | OrderCanceledEvent;
```

### Event Store

```typescript
// lib/events/event-store.ts
import { db } from '@/lib/db';
import { nanoid } from 'nanoid';
import type { DomainEvent } from './types';

export class EventStore {
  async append<T>(
    aggregateId: string,
    aggregateType: string,
    eventType: string,
    payload: T,
    expectedVersion: number,
    metadata?: Record<string, unknown>,
  ): Promise<DomainEvent<T>> {
    const event: DomainEvent<T> = {
      id: nanoid(),
      aggregateId,
      aggregateType,
      eventType,
      version: expectedVersion + 1,
      payload,
      metadata: {
        ...metadata,
        timestamp: new Date().toISOString(),
      },
    };

    try {
      await db.event.create({
        data: {
          id: event.id,
          aggregateId: event.aggregateId,
          aggregateType: event.aggregateType,
          eventType: event.eventType,
          version: event.version,
          payload: event.payload as any,
          metadata: event.metadata as any,
          createdBy: metadata?.userId as string,
        },
      });

      return event;
    } catch (error: any) {
      // Unique constraint violation = concurrent modification
      if (error.code === 'P2002') {
        throw new ConcurrencyError(
          `Aggregate ${aggregateId} was modified concurrently`,
        );
      }
      throw error;
    }
  }

  async getEvents(
    aggregateId: string,
    fromVersion: number = 0,
  ): Promise<DomainEvent[]> {
    const events = await db.event.findMany({
      where: {
        aggregateId,
        version: { gt: fromVersion },
      },
      orderBy: { version: 'asc' },
    });

    return events.map((e) => ({
      id: e.id,
      aggregateId: e.aggregateId,
      aggregateType: e.aggregateType,
      eventType: e.eventType,
      version: e.version,
      payload: e.payload,
      metadata: e.metadata as any,
    }));
  }

  async getSnapshot<T>(aggregateId: string): Promise<{
    state: T;
    version: number;
  } | null> {
    const snapshot = await db.snapshot.findUnique({
      where: { aggregateId },
    });

    if (!snapshot) return null;

    return {
      state: snapshot.state as T,
      version: snapshot.version,
    };
  }

  async saveSnapshot<T>(
    aggregateId: string,
    aggregateType: string,
    state: T,
    version: number,
  ): Promise<void> {
    await db.snapshot.upsert({
      where: { aggregateId },
      create: {
        aggregateId,
        aggregateType,
        state: state as any,
        version,
      },
      update: {
        state: state as any,
        version,
      },
    });
  }
}

export class ConcurrencyError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ConcurrencyError';
  }
}

export const eventStore = new EventStore();
```

### Aggregate Implementation

```typescript
// lib/aggregates/order.ts
import { eventStore } from '@/lib/events/event-store';
import type { OrderEvent } from '@/lib/events/types';

interface OrderState {
  id: string;
  customerId: string;
  items: Array<{
    productId: string;
    quantity: number;
    price: number;
  }>;
  total: number;
  status: 'draft' | 'submitted' | 'paid' | 'shipped' | 'canceled';
  version: number;
}

export class Order {
  private state: OrderState;

  private constructor(state: OrderState) {
    this.state = state;
  }

  // Factory method to create new order
  static async create(
    id: string,
    customerId: string,
    userId: string,
  ): Promise<Order> {
    const initialState: OrderState = {
      id,
      customerId,
      items: [],
      total: 0,
      status: 'draft',
      version: 0,
    };

    const order = new Order(initialState);

    await eventStore.append(
      id,
      'Order',
      'OrderCreated',
      { customerId, items: [], total: 0 },
      0,
      { userId },
    );

    return order;
  }

  // Factory method to load existing order
  static async load(id: string): Promise<Order | null> {
    // Try snapshot first
    const snapshot = await eventStore.getSnapshot<OrderState>(id);
    let state: OrderState;
    let fromVersion = 0;

    if (snapshot) {
      state = snapshot.state;
      fromVersion = snapshot.version;
    } else {
      state = {
        id,
        customerId: '',
        items: [],
        total: 0,
        status: 'draft',
        version: 0,
      };
    }

    // Apply events since snapshot
    const events = await eventStore.getEvents(id, fromVersion);

    if (events.length === 0 && !snapshot) {
      return null; // Order doesn't exist
    }

    for (const event of events) {
      state = Order.applyEvent(state, event as OrderEvent);
    }

    const order = new Order(state);

    // Create snapshot if many events
    if (events.length > 10) {
      await eventStore.saveSnapshot(id, 'Order', state, state.version);
    }

    return order;
  }

  // Apply event to state (pure function)
  private static applyEvent(
    state: OrderState,
    event: OrderEvent,
  ): OrderState {
    switch (event.eventType) {
      case 'OrderCreated':
        return {
          ...state,
          customerId: event.payload.customerId,
          items: event.payload.items,
          total: event.payload.total,
          status: 'draft',
          version: event.version,
        };

      case 'OrderItemAdded':
        const newItems = [...state.items, event.payload];
        return {
          ...state,
          items: newItems,
          total: newItems.reduce(
            (sum, item) => sum + item.price * item.quantity,
            0,
          ),
          version: event.version,
        };

      case 'OrderSubmitted':
        return {
          ...state,
          status: 'submitted',
          version: event.version,
        };

      case 'OrderPaid':
        return {
          ...state,
          status: 'paid',
          version: event.version,
        };

      case 'OrderShipped':
        return {
          ...state,
          status: 'shipped',
          version: event.version,
        };

      case 'OrderCanceled':
        return {
          ...state,
          status: 'canceled',
          version: event.version,
        };

      default:
        return state;
    }
  }

  // Commands
  async addItem(
    productId: string,
    quantity: number,
    price: number,
    userId: string,
  ): Promise<void> {
    if (this.state.status !== 'draft') {
      throw new Error('Cannot modify non-draft order');
    }

    await eventStore.append(
      this.state.id,
      'Order',
      'OrderItemAdded',
      { productId, quantity, price },
      this.state.version,
      { userId },
    );

    this.state = Order.applyEvent(this.state, {
      id: '',
      aggregateId: this.state.id,
      aggregateType: 'Order',
      eventType: 'OrderItemAdded',
      version: this.state.version + 1,
      payload: { productId, quantity, price },
    });
  }

  async submit(userId: string): Promise<void> {
    if (this.state.status !== 'draft') {
      throw new Error('Order already submitted');
    }
    if (this.state.items.length === 0) {
      throw new Error('Cannot submit empty order');
    }

    await eventStore.append(
      this.state.id,
      'Order',
      'OrderSubmitted',
      { submittedAt: new Date().toISOString() },
      this.state.version,
      { userId },
    );

    this.state.status = 'submitted';
    this.state.version++;
  }

  // Queries
  getState(): Readonly<OrderState> {
    return { ...this.state };
  }

  canBeCanceled(): boolean {
    return ['draft', 'submitted'].includes(this.state.status);
  }
}
```

### Event Handlers (Projections)

```typescript
// lib/events/handlers.ts
import { db } from '@/lib/db';
import type { DomainEvent, OrderEvent } from './types';

// Update read model when events occur
export async function handleOrderEvent(event: OrderEvent): Promise<void> {
  switch (event.eventType) {
    case 'OrderCreated':
      await db.orderReadModel.create({
        data: {
          id: event.aggregateId,
          customerId: event.payload.customerId,
          status: 'draft',
          total: 0,
          itemCount: 0,
          createdAt: new Date(event.metadata!.timestamp),
        },
      });
      break;

    case 'OrderItemAdded':
      await db.orderReadModel.update({
        where: { id: event.aggregateId },
        data: {
          total: { increment: event.payload.price * event.payload.quantity },
          itemCount: { increment: 1 },
        },
      });
      break;

    case 'OrderSubmitted':
      await db.orderReadModel.update({
        where: { id: event.aggregateId },
        data: {
          status: 'submitted',
          submittedAt: new Date(event.payload.submittedAt),
        },
      });
      break;

    case 'OrderPaid':
      await db.orderReadModel.update({
        where: { id: event.aggregateId },
        data: { status: 'paid' },
      });
      break;

    case 'OrderShipped':
      await db.orderReadModel.update({
        where: { id: event.aggregateId },
        data: {
          status: 'shipped',
          trackingNumber: event.payload.trackingNumber,
        },
      });
      break;

    case 'OrderCanceled':
      await db.orderReadModel.update({
        where: { id: event.aggregateId },
        data: {
          status: 'canceled',
          canceledAt: new Date(event.payload.canceledAt),
          cancelReason: event.payload.reason,
        },
      });
      break;
  }
}
```

### API Usage

```typescript
// app/api/orders/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { nanoid } from 'nanoid';
import { requireAuth } from '@/lib/auth';
import { Order } from '@/lib/aggregates/order';

export async function POST(request: NextRequest) {
  const session = await requireAuth();

  const orderId = nanoid();
  const order = await Order.create(orderId, session.user.id, session.user.id);

  return NextResponse.json({
    id: orderId,
    ...order.getState(),
  });
}

// app/api/orders/[id]/items/route.ts
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const session = await requireAuth();
  const { id } = await params;
  const { productId, quantity, price } = await request.json();

  const order = await Order.load(id);
  if (!order) {
    return NextResponse.json({ error: 'Order not found' }, { status: 404 });
  }

  await order.addItem(productId, quantity, price, session.user.id);

  return NextResponse.json(order.getState());
}
```

## When to Use

- Audit requirements
- Complex domain logic
- Need for undo/replay
- Analytics on state changes
- Financial transactions

## Anti-patterns

```typescript
// BAD: Mutable events
event.payload.total = newTotal; // Events are immutable!

// BAD: Business logic in event handlers
async function handleOrderCreated(event) {
  if (event.payload.total > 1000) {
    await applyDiscount(event); // Logic belongs in aggregate
  }
}

// BAD: Large event payloads
await append('OrderCreated', { fullOrderObject }); // Store minimal data

// BAD: No version control
await db.event.create({ version: 1 }); // Always increment
```

```typescript
// GOOD: Immutable events
const newEvent = { ...event, payload: { ...event.payload, total: newTotal } };

// GOOD: Business logic in aggregate
class Order {
  async submit() {
    if (this.total > 1000) {
      // Apply discount
    }
    await eventStore.append(...);
  }
}

// GOOD: Minimal event payload
await append('OrderCreated', { customerId, items: [] });

// GOOD: Optimistic concurrency
await append(id, type, event, expectedVersion); // Throws on conflict
```

## Related Patterns

- Queue Processing Pattern - For async event handling
- Error Handling Pattern - For event handling errors
- Logging Pattern - Events are natural audit logs
