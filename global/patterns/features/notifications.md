---
name: Notifications
category: feature
language: typescript
framework: nextjs
keywords: [notifications, toast, alerts, real-time, push, websocket]
confidence: 0.85
---

# Notifications Pattern

## Problem

Users need to be informed about:
- Action results (success/error)
- Background events
- Important updates
- System messages

## Solution

Implement a notification system with toast messages for immediate feedback and persistent notifications for important updates.

## Implementation

### Toast Notifications with Sonner

```typescript
// components/providers/toast-provider.tsx
'use client';

import { Toaster } from 'sonner';

export function ToastProvider() {
  return (
    <Toaster
      position="bottom-right"
      toastOptions={{
        duration: 4000,
        classNames: {
          toast: 'bg-background border shadow-lg',
          title: 'text-foreground',
          description: 'text-muted-foreground',
          success: 'border-green-500',
          error: 'border-red-500',
          warning: 'border-yellow-500',
        },
      }}
    />
  );
}

// app/layout.tsx
import { ToastProvider } from '@/components/providers/toast-provider';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <ToastProvider />
      </body>
    </html>
  );
}
```

### Using Toast in Components

```typescript
// components/delete-button.tsx
'use client';

import { toast } from 'sonner';
import { deleteItem } from '@/actions/item-actions';

export function DeleteButton({ itemId }: { itemId: string }) {
  const handleDelete = async () => {
    // Show loading toast
    const toastId = toast.loading('Deleting item...');

    try {
      await deleteItem(itemId);
      toast.success('Item deleted successfully', { id: toastId });
    } catch (error) {
      toast.error('Failed to delete item', {
        id: toastId,
        description: 'Please try again later',
      });
    }
  };

  return <button onClick={handleDelete}>Delete</button>;
}
```

### Toast with Actions

```typescript
// lib/notifications.ts
import { toast } from 'sonner';

export function showUndoToast(
  message: string,
  onUndo: () => void | Promise<void>,
) {
  toast(message, {
    duration: 5000,
    action: {
      label: 'Undo',
      onClick: async () => {
        try {
          await onUndo();
          toast.success('Action undone');
        } catch {
          toast.error('Failed to undo');
        }
      },
    },
  });
}

// Usage
async function archiveEmail(emailId: string) {
  await archiveEmailAction(emailId);

  showUndoToast('Email archived', async () => {
    await unarchiveEmailAction(emailId);
  });
}
```

### Persistent Notifications System

```typescript
// Database schema
// schema.prisma
model Notification {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id])
  type      String   // 'info' | 'success' | 'warning' | 'error'
  title     String
  message   String?
  link      String?
  read      Boolean  @default(false)
  createdAt DateTime @default(now())

  @@index([userId, read])
}
```

```typescript
// lib/notifications.server.ts
import { db } from './db';

export async function createNotification({
  userId,
  type,
  title,
  message,
  link,
}: {
  userId: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message?: string;
  link?: string;
}) {
  return db.notification.create({
    data: {
      userId,
      type,
      title,
      message,
      link,
    },
  });
}

export async function getUserNotifications(userId: string) {
  return db.notification.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });
}

export async function getUnreadCount(userId: string) {
  return db.notification.count({
    where: { userId, read: false },
  });
}

export async function markAsRead(notificationId: string, userId: string) {
  return db.notification.updateMany({
    where: { id: notificationId, userId },
    data: { read: true },
  });
}

export async function markAllAsRead(userId: string) {
  return db.notification.updateMany({
    where: { userId, read: false },
    data: { read: true },
  });
}
```

### Notification Bell Component

```typescript
// components/notification-bell.tsx
'use client';

import { useState, useEffect } from 'react';
import { Bell } from 'lucide-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';

interface Notification {
  id: string;
  type: string;
  title: string;
  message?: string;
  link?: string;
  read: boolean;
  createdAt: string;
}

export function NotificationBell() {
  const [isOpen, setIsOpen] = useState(false);
  const queryClient = useQueryClient();

  const { data: notifications = [], isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: async () => {
      const res = await fetch('/api/notifications');
      return res.json() as Promise<Notification[]>;
    },
    refetchInterval: 30000, // Poll every 30s
  });

  const unreadCount = notifications.filter((n) => !n.read).length;

  const markAsReadMutation = useMutation({
    mutationFn: async (id: string) => {
      await fetch(`/api/notifications/${id}/read`, { method: 'POST' });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
  });

  const markAllAsReadMutation = useMutation({
    mutationFn: async () => {
      await fetch('/api/notifications/read-all', { method: 'POST' });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
  });

  return (
    <Popover open={isOpen} onOpenChange={setIsOpen}>
      <PopoverTrigger asChild>
        <button className="relative p-2 hover:bg-muted rounded-lg">
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 h-5 w-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </button>
      </PopoverTrigger>

      <PopoverContent className="w-80 p-0" align="end">
        <div className="flex items-center justify-between p-4 border-b">
          <h3 className="font-semibold">Notifications</h3>
          {unreadCount > 0 && (
            <button
              onClick={() => markAllAsReadMutation.mutate()}
              className="text-sm text-blue-600 hover:underline"
            >
              Mark all read
            </button>
          )}
        </div>

        <div className="max-h-[400px] overflow-y-auto">
          {notifications.length === 0 ? (
            <div className="p-4 text-center text-muted-foreground">
              No notifications
            </div>
          ) : (
            notifications.map((notification) => (
              <NotificationItem
                key={notification.id}
                notification={notification}
                onRead={() => markAsReadMutation.mutate(notification.id)}
              />
            ))
          )}
        </div>
      </PopoverContent>
    </Popover>
  );
}

function NotificationItem({
  notification,
  onRead,
}: {
  notification: Notification;
  onRead: () => void;
}) {
  const handleClick = () => {
    if (!notification.read) {
      onRead();
    }
    if (notification.link) {
      window.location.href = notification.link;
    }
  };

  return (
    <button
      onClick={handleClick}
      className={`w-full p-4 text-left border-b hover:bg-muted transition-colors ${
        !notification.read ? 'bg-blue-50' : ''
      }`}
    >
      <div className="flex items-start gap-3">
        <div
          className={`w-2 h-2 mt-2 rounded-full ${
            notification.read ? 'bg-transparent' : 'bg-blue-500'
          }`}
        />
        <div className="flex-1 min-w-0">
          <p className="font-medium text-sm">{notification.title}</p>
          {notification.message && (
            <p className="text-sm text-muted-foreground mt-1">
              {notification.message}
            </p>
          )}
          <p className="text-xs text-muted-foreground mt-1">
            {formatRelativeTime(notification.createdAt)}
          </p>
        </div>
      </div>
    </button>
  );
}

function formatRelativeTime(date: string): string {
  const seconds = Math.floor(
    (new Date().getTime() - new Date(date).getTime()) / 1000,
  );

  if (seconds < 60) return 'Just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}
```

### Real-Time Notifications with SSE

```typescript
// app/api/notifications/stream/route.ts
import { requireAuth } from '@/lib/auth';

export async function GET() {
  const session = await requireAuth();

  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    async start(controller) {
      // Send initial connection message
      controller.enqueue(
        encoder.encode(`data: ${JSON.stringify({ type: 'connected' })}\n\n`),
      );

      // Subscribe to notifications for this user
      const unsubscribe = subscribeToNotifications(
        session.user.id,
        (notification) => {
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify(notification)}\n\n`),
          );
        },
      );

      // Keep connection alive with heartbeat
      const heartbeat = setInterval(() => {
        controller.enqueue(encoder.encode(': heartbeat\n\n'));
      }, 30000);

      // Cleanup on close
      return () => {
        clearInterval(heartbeat);
        unsubscribe();
      };
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  });
}
```

```typescript
// hooks/use-realtime-notifications.ts
'use client';

import { useEffect, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';

export function useRealtimeNotifications() {
  const queryClient = useQueryClient();

  const handleNotification = useCallback(
    (notification: any) => {
      // Show toast for new notification
      toast(notification.title, {
        description: notification.message,
      });

      // Update notification list
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
    },
    [queryClient],
  );

  useEffect(() => {
    const eventSource = new EventSource('/api/notifications/stream');

    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.type !== 'connected') {
        handleNotification(data);
      }
    };

    eventSource.onerror = () => {
      // Reconnect handled automatically by EventSource
      console.error('SSE connection error');
    };

    return () => {
      eventSource.close();
    };
  }, [handleNotification]);
}
```

## When to Use

- Form submission feedback
- Background task completion
- System updates and alerts
- Social features (likes, comments, follows)
- Error reporting

## Anti-patterns

```typescript
// BAD: Alert for everything
alert('Item saved!'); // Blocks UI, bad UX

// BAD: No feedback at all
await saveItem(); // User doesn't know if it worked

// BAD: Too many notifications
notifications.forEach(n => toast(n)); // Overwhelming

// BAD: Notifications without context
toast('Error'); // What error? What should user do?
```

```typescript
// GOOD: Non-blocking toast
toast.success('Item saved');

// GOOD: Clear feedback
const toastId = toast.loading('Saving...');
try {
  await saveItem();
  toast.success('Saved', { id: toastId });
} catch {
  toast.error('Failed to save', { id: toastId });
}

// GOOD: Batch notifications
toast(`${count} items updated`);

// GOOD: Actionable messages
toast.error('Connection lost', {
  action: {
    label: 'Retry',
    onClick: reconnect,
  },
});
```

## Related Patterns

- Error Handling Pattern - For error notifications
- Server Action Pattern - For showing action results
- Real-Time Pattern - For live notifications
