---
name: Dependency Injection
category: core
language: typescript
framework: none
keywords: [dependency-injection, di, ioc, testing, decoupling, interfaces]
confidence: 0.85
---

# Dependency Injection Pattern

## Problem

Without dependency injection:
- Components are tightly coupled to their dependencies
- Unit testing requires mocking module imports
- Swapping implementations requires code changes
- Code is harder to understand and maintain

## Solution

Pass dependencies explicitly through constructors or function parameters, program to interfaces, and use a composition root to wire everything together.

## Implementation

### Basic Dependency Injection

```typescript
// Without DI - tightly coupled
class UserService {
  private db = new PrismaClient(); // Hardcoded dependency

  async getUser(id: string) {
    return this.db.user.findUnique({ where: { id } });
  }
}

// With DI - loosely coupled
interface UserRepository {
  findById(id: string): Promise<User | null>;
  create(data: CreateUserInput): Promise<User>;
  update(id: string, data: UpdateUserInput): Promise<User>;
  delete(id: string): Promise<void>;
}

class UserService {
  constructor(private repository: UserRepository) {} // Injected

  async getUser(id: string) {
    return this.repository.findById(id);
  }
}

// Implementation
class PrismaUserRepository implements UserRepository {
  constructor(private db: PrismaClient) {}

  async findById(id: string): Promise<User | null> {
    return this.db.user.findUnique({ where: { id } });
  }

  async create(data: CreateUserInput): Promise<User> {
    return this.db.user.create({ data });
  }

  // ... other methods
}
```

### Factory Functions

```typescript
// lib/factories.ts

// Create user service with all dependencies
export function createUserService(db: PrismaClient): UserService {
  const repository = new PrismaUserRepository(db);
  const emailService = new SendGridEmailService(config.sendgridApiKey);
  const logger = createLogger('UserService');

  return new UserService(repository, emailService, logger);
}

// Usage
const userService = createUserService(prisma);
```

### Composition Root

```typescript
// lib/container.ts

import { PrismaClient } from '@prisma/client';
import { config } from './config';

// Singleton instances
let prisma: PrismaClient | null = null;
let userService: UserService | null = null;
let orderService: OrderService | null = null;

// Lazy initialization
function getDb(): PrismaClient {
  if (!prisma) {
    prisma = new PrismaClient({
      log: config.isDevelopment ? ['query'] : [],
    });
  }
  return prisma;
}

export function getUserService(): UserService {
  if (!userService) {
    const db = getDb();
    const repository = new PrismaUserRepository(db);
    const emailService = new SendGridEmailService(config.sendgridApiKey);
    userService = new UserService(repository, emailService);
  }
  return userService;
}

export function getOrderService(): OrderService {
  if (!orderService) {
    const db = getDb();
    const orderRepo = new PrismaOrderRepository(db);
    const paymentService = new StripePaymentService(config.stripeSecretKey);
    const users = getUserService();
    orderService = new OrderService(orderRepo, paymentService, users);
  }
  return orderService;
}

// Cleanup for tests
export function resetContainer(): void {
  prisma?.disconnect();
  prisma = null;
  userService = null;
  orderService = null;
}
```

### Context-Based Injection (React)

```typescript
// contexts/services.tsx
'use client';

import { createContext, useContext, useMemo, type ReactNode } from 'react';

interface Services {
  api: ApiClient;
  analytics: AnalyticsService;
  storage: StorageService;
}

const ServicesContext = createContext<Services | null>(null);

export function ServicesProvider({
  children,
  overrides = {},
}: {
  children: ReactNode;
  overrides?: Partial<Services>;
}) {
  const services = useMemo(() => ({
    api: overrides.api ?? new ApiClient(),
    analytics: overrides.analytics ?? new AnalyticsService(),
    storage: overrides.storage ?? new LocalStorageService(),
  }), [overrides]);

  return (
    <ServicesContext.Provider value={services}>
      {children}
    </ServicesContext.Provider>
  );
}

export function useServices(): Services {
  const context = useContext(ServicesContext);
  if (!context) {
    throw new Error('useServices must be used within ServicesProvider');
  }
  return context;
}

// Usage in components
function UserProfile() {
  const { api, analytics } = useServices();

  useEffect(() => {
    analytics.track('profile_viewed');
  }, [analytics]);

  // ...
}

// In tests - inject mock services
<ServicesProvider overrides={{ api: mockApi }}>
  <UserProfile />
</ServicesProvider>
```

### Interface Definitions

```typescript
// interfaces/repository.ts

export interface Repository<T, CreateInput, UpdateInput> {
  findById(id: string): Promise<T | null>;
  findMany(query: QueryOptions): Promise<T[]>;
  create(data: CreateInput): Promise<T>;
  update(id: string, data: UpdateInput): Promise<T>;
  delete(id: string): Promise<void>;
  count(query?: QueryOptions): Promise<number>;
}

export interface QueryOptions {
  where?: Record<string, unknown>;
  orderBy?: Record<string, 'asc' | 'desc'>;
  skip?: number;
  take?: number;
}

// interfaces/email-service.ts
export interface EmailService {
  send(to: string, subject: string, body: string): Promise<void>;
  sendTemplate(to: string, template: string, data: object): Promise<void>;
}

// interfaces/payment-service.ts
export interface PaymentService {
  createCharge(amount: number, currency: string, token: string): Promise<ChargeResult>;
  refund(chargeId: string, amount?: number): Promise<RefundResult>;
  createSubscription(customerId: string, priceId: string): Promise<Subscription>;
}
```

### Testing with Injected Dependencies

```typescript
// __tests__/user-service.test.ts
import { describe, it, expect, vi } from 'vitest';
import { UserService } from '@/services/user-service';

describe('UserService', () => {
  // Create mock repository
  const mockRepository = {
    findById: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  };

  const mockEmailService = {
    send: vi.fn(),
    sendTemplate: vi.fn(),
  };

  // Inject mocks
  const service = new UserService(mockRepository, mockEmailService);

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('creates user and sends welcome email', async () => {
    const userData = { email: 'test@example.com', name: 'Test' };
    const createdUser = { id: '1', ...userData };

    mockRepository.create.mockResolvedValue(createdUser);
    mockEmailService.sendTemplate.mockResolvedValue(undefined);

    const result = await service.createUser(userData);

    expect(result).toEqual(createdUser);
    expect(mockRepository.create).toHaveBeenCalledWith(userData);
    expect(mockEmailService.sendTemplate).toHaveBeenCalledWith(
      userData.email,
      'welcome',
      expect.any(Object),
    );
  });

  it('returns null when user not found', async () => {
    mockRepository.findById.mockResolvedValue(null);

    const result = await service.getUser('nonexistent');

    expect(result).toBeNull();
  });
});
```

## When to Use

- Services that depend on external resources (database, APIs)
- Components that need different implementations in test vs production
- When you need to swap implementations without code changes
- When building reusable libraries

## Anti-patterns

```typescript
// BAD: Hardcoded dependencies
class OrderService {
  private db = new PrismaClient();
  private stripe = new Stripe(process.env.STRIPE_KEY);
  // Can't test without real database and Stripe!
}

// BAD: Service locator pattern
class UserService {
  async getUser(id: string) {
    const db = Container.get('database'); // Hidden dependency
    return db.user.find(id);
  }
}

// BAD: Passing everything through props
// 10 levels of prop drilling
<App db={db} stripe={stripe} email={email} cache={cache} ...>

// BAD: Importing concrete implementations everywhere
import { PrismaUserRepository } from './prisma-user-repository';
// Every file that imports this is coupled to Prisma
```

```typescript
// GOOD: Constructor injection
class OrderService {
  constructor(
    private orderRepo: OrderRepository,
    private paymentService: PaymentService,
    private notificationService: NotificationService,
  ) {}
}

// GOOD: Program to interfaces
function createOrderService(
  repo: OrderRepository, // Interface, not implementation
  payment: PaymentService,
): OrderService {
  return new OrderService(repo, payment);
}

// GOOD: Context for React components
const { api } = useServices();

// GOOD: Composition root wires everything
// lib/container.ts is the only place that knows about implementations
```

## Related Patterns

- Service Pattern - Often uses dependency injection
- Testing Pattern - DI makes testing easier
- Configuration Pattern - Config often injected as dependency
