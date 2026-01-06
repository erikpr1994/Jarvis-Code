---
name: Queue Processing
category: integration
language: typescript
framework: none
keywords: [queue, job, worker, background, async, bull, redis]
confidence: 0.85
---

# Queue Processing Pattern

## Problem

Long-running or resource-intensive tasks block requests:
- Email sending delays response
- Image processing times out
- Report generation is too slow
- Webhook processing needs reliability

## Solution

Use message queues to offload work to background workers with proper error handling, retries, and monitoring.

## Implementation

### Queue Setup with BullMQ

```typescript
// lib/queue/connection.ts
import { Queue, Worker, Job } from 'bullmq';
import Redis from 'ioredis';

const connection = new Redis(process.env.REDIS_URL!, {
  maxRetriesPerRequest: null,
});

export { connection };

// lib/queue/queues.ts
import { Queue } from 'bullmq';
import { connection } from './connection';

export const emailQueue = new Queue('email', { connection });
export const imageQueue = new Queue('image-processing', { connection });
export const webhookQueue = new Queue('webhooks', { connection });
export const reportQueue = new Queue('reports', { connection });
```

### Job Types

```typescript
// lib/queue/types.ts

export interface EmailJob {
  type: 'welcome' | 'password-reset' | 'notification';
  to: string;
  subject: string;
  data: Record<string, unknown>;
}

export interface ImageProcessingJob {
  imageId: string;
  userId: string;
  operations: Array<{
    type: 'resize' | 'compress' | 'watermark';
    params: Record<string, unknown>;
  }>;
}

export interface WebhookJob {
  eventId: string;
  type: string;
  payload: Record<string, unknown>;
}

export interface ReportJob {
  reportId: string;
  userId: string;
  type: 'sales' | 'analytics' | 'users';
  dateRange: {
    start: string;
    end: string;
  };
}
```

### Adding Jobs to Queue

```typescript
// lib/queue/producers.ts
import { emailQueue, imageQueue, reportQueue } from './queues';
import type { EmailJob, ImageProcessingJob, ReportJob } from './types';

export async function sendEmail(job: EmailJob) {
  await emailQueue.add('send-email', job, {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 5000,
    },
  });
}

export async function processImage(job: ImageProcessingJob) {
  await imageQueue.add('process-image', job, {
    attempts: 2,
    timeout: 60000, // 1 minute timeout
  });
}

export async function generateReport(job: ReportJob) {
  // Add with unique job ID to prevent duplicates
  await reportQueue.add('generate-report', job, {
    jobId: job.reportId,
    attempts: 1,
    removeOnComplete: {
      age: 3600, // Keep completed jobs for 1 hour
    },
    removeOnFail: {
      age: 86400, // Keep failed jobs for 24 hours
    },
  });

  return job.reportId;
}

// Scheduled/Delayed jobs
export async function scheduleReminder(
  userId: string,
  message: string,
  sendAt: Date,
) {
  const delay = sendAt.getTime() - Date.now();

  await emailQueue.add(
    'send-reminder',
    { userId, message },
    { delay: Math.max(0, delay) },
  );
}

// Repeatable jobs (cron)
export async function scheduleReportGeneration() {
  await reportQueue.add(
    'daily-report',
    { type: 'daily-summary' },
    {
      repeat: {
        pattern: '0 9 * * *', // Every day at 9 AM
      },
    },
  );
}
```

### Worker Implementation

```typescript
// workers/email-worker.ts
import { Worker, Job } from 'bullmq';
import { connection } from '@/lib/queue/connection';
import { sendEmailTemplate } from '@/lib/email';
import type { EmailJob } from '@/lib/queue/types';

const emailWorker = new Worker<EmailJob>(
  'email',
  async (job: Job<EmailJob>) => {
    const { type, to, subject, data } = job.data;

    console.log(`Processing email job ${job.id}: ${type} to ${to}`);

    try {
      await sendEmailTemplate(type, {
        to,
        subject,
        data,
      });

      return { sent: true, to };
    } catch (error) {
      console.error(`Email job ${job.id} failed:`, error);
      throw error; // Will trigger retry
    }
  },
  {
    connection,
    concurrency: 5, // Process 5 emails at a time
  },
);

emailWorker.on('completed', (job) => {
  console.log(`Email job ${job.id} completed`);
});

emailWorker.on('failed', (job, error) => {
  console.error(`Email job ${job?.id} failed:`, error);

  // Send to error tracking
  if (job?.attemptsMade === job?.opts.attempts) {
    // Final failure
    reportError('email-failed', { jobId: job?.id, error: error.message });
  }
});

export { emailWorker };
```

### Complex Worker with Progress

```typescript
// workers/image-worker.ts
import { Worker, Job } from 'bullmq';
import { connection } from '@/lib/queue/connection';
import { db } from '@/lib/db';
import type { ImageProcessingJob } from '@/lib/queue/types';

const imageWorker = new Worker<ImageProcessingJob>(
  'image-processing',
  async (job: Job<ImageProcessingJob>) => {
    const { imageId, operations } = job.data;

    // Update job progress
    await job.updateProgress(0);

    // Get image
    const image = await db.image.findUnique({ where: { id: imageId } });
    if (!image) {
      throw new Error(`Image ${imageId} not found`);
    }

    let processedUrl = image.url;
    const totalOps = operations.length;

    for (let i = 0; i < operations.length; i++) {
      const operation = operations[i];

      // Process each operation
      switch (operation.type) {
        case 'resize':
          processedUrl = await resizeImage(processedUrl, operation.params);
          break;
        case 'compress':
          processedUrl = await compressImage(processedUrl, operation.params);
          break;
        case 'watermark':
          processedUrl = await addWatermark(processedUrl, operation.params);
          break;
      }

      // Update progress
      await job.updateProgress(((i + 1) / totalOps) * 100);

      // Log step for debugging
      await job.log(`Completed ${operation.type} operation`);
    }

    // Update database
    await db.image.update({
      where: { id: imageId },
      data: {
        processedUrl,
        status: 'processed',
      },
    });

    return { imageId, processedUrl };
  },
  {
    connection,
    concurrency: 2, // Heavy operations, limit concurrency
    limiter: {
      max: 10,
      duration: 60000, // Max 10 jobs per minute
    },
  },
);

export { imageWorker };
```

### API Integration

```typescript
// app/api/images/[id]/process/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { requireAuth } from '@/lib/auth';
import { processImage } from '@/lib/queue/producers';
import { db } from '@/lib/db';

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const session = await requireAuth();
  const { id } = await params;

  // Validate image ownership
  const image = await db.image.findUnique({ where: { id } });
  if (!image || image.userId !== session.user.id) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  // Get operations from request
  const { operations } = await request.json();

  // Queue the job
  await processImage({
    imageId: id,
    userId: session.user.id,
    operations,
  });

  // Update status
  await db.image.update({
    where: { id },
    data: { status: 'processing' },
  });

  return NextResponse.json({
    message: 'Processing started',
    imageId: id,
  });
}
```

### Job Status Endpoint

```typescript
// app/api/jobs/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { Queue } from 'bullmq';
import { connection } from '@/lib/queue/connection';

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const queueName = request.nextUrl.searchParams.get('queue') || 'default';

  const queue = new Queue(queueName, { connection });
  const job = await queue.getJob(id);

  if (!job) {
    return NextResponse.json({ error: 'Job not found' }, { status: 404 });
  }

  const state = await job.getState();
  const progress = job.progress;

  return NextResponse.json({
    id: job.id,
    state,
    progress,
    data: job.data,
    result: job.returnvalue,
    failedReason: job.failedReason,
    attempts: job.attemptsMade,
    timestamp: job.timestamp,
  });
}
```

### Worker Startup Script

```typescript
// scripts/start-workers.ts
import { emailWorker } from '@/workers/email-worker';
import { imageWorker } from '@/workers/image-worker';
import { reportWorker } from '@/workers/report-worker';

console.log('Starting workers...');

// Graceful shutdown
const shutdown = async () => {
  console.log('Shutting down workers...');

  await Promise.all([
    emailWorker.close(),
    imageWorker.close(),
    reportWorker.close(),
  ]);

  process.exit(0);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

console.log('Workers started successfully');
```

## When to Use

- Email sending
- File/image processing
- Report generation
- Webhook processing
- Data imports/exports
- Any slow or unreliable operation

## Anti-patterns

```typescript
// BAD: Blocking the request
export async function POST(request) {
  await sendEmail(data); // User waits for email
  await processImage(image); // More waiting
  return Response.json({ success: true });
}

// BAD: No retry logic
worker.on('failed', () => {
  // Job lost forever
});

// BAD: No concurrency limits
new Worker('queue', handler, { concurrency: 1000 });
// May overwhelm resources

// BAD: Sensitive data in job
await queue.add('job', { password: 'secret' });
// Job data is stored in Redis!
```

```typescript
// GOOD: Queue and respond immediately
export async function POST(request) {
  await emailQueue.add('send', data);
  return Response.json({ queued: true });
}

// GOOD: Retry with backoff
await queue.add('job', data, {
  attempts: 3,
  backoff: { type: 'exponential', delay: 5000 },
});

// GOOD: Appropriate concurrency
new Worker('queue', handler, {
  concurrency: 5,
  limiter: { max: 10, duration: 60000 },
});

// GOOD: Reference IDs, not sensitive data
await queue.add('job', { userId: user.id });
// Worker fetches user data from DB
```

## Related Patterns

- Webhook Handler Pattern - Uses queues for reliability
- Error Handling Pattern - For job error handling
- Logging Pattern - For job monitoring
