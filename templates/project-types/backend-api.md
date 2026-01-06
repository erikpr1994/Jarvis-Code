# Backend API Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~850 tokens

This template extends the base CLAUDE.md with backend API-specific patterns.

## Tech Stack Additions

```yaml
runtime:
  - {{RUNTIME}}  # node | python | go

framework:
  - {{FRAMEWORK}}  # express | fastify | fastapi | gin | django

database:
  - {{DATABASE}}  # postgresql | mysql | mongodb

orm:
  - {{ORM}}  # prisma | drizzle | sqlalchemy | typeorm

authentication:
  - {{AUTH_METHOD}}  # jwt | session | oauth2
```

## Project Structure

### Node.js (Express/Fastify)

```
src/
├── index.ts                 # App entry point
├── app.ts                   # Express/Fastify setup
├── config/
│   ├── index.ts             # Configuration loader
│   ├── database.ts          # Database config
│   └── env.ts               # Environment validation
├── api/
│   ├── routes/
│   │   ├── index.ts         # Route aggregator
│   │   ├── auth.routes.ts
│   │   └── users.routes.ts
│   ├── controllers/
│   │   ├── auth.controller.ts
│   │   └── users.controller.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── error.middleware.ts
│   │   └── validate.middleware.ts
│   └── validators/
│       ├── auth.validator.ts
│       └── users.validator.ts
├── services/
│   ├── auth.service.ts
│   └── users.service.ts
├── repositories/
│   ├── base.repository.ts
│   └── users.repository.ts
├── models/
│   └── user.model.ts
├── types/
│   └── index.ts
└── utils/
    ├── errors.ts
    └── logger.ts
```

### Python (FastAPI)

```
app/
├── main.py                  # FastAPI entry point
├── config.py                # Configuration
├── api/
│   ├── __init__.py
│   ├── deps.py              # Dependencies (DB, auth)
│   └── routes/
│       ├── auth.py
│       └── users.py
├── services/
│   ├── auth.py
│   └── users.py
├── repositories/
│   └── users.py
├── models/
│   └── user.py
├── schemas/
│   ├── auth.py
│   └── users.py
└── utils/
    ├── errors.py
    └── security.py
```

## Key Patterns

### Controller Layer (Node.js)

```typescript
import { Request, Response, NextFunction } from 'express';
import { UserService } from '../services/user.service';
import { CreateUserDto, UpdateUserDto } from '../validators/user.validator';
import { NotFoundError, ValidationError } from '../utils/errors';

export class UserController {
  constructor(private userService: UserService) {}

  getUsers = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { page = 1, limit = 10 } = req.query;
      const users = await this.userService.findAll({
        page: Number(page),
        limit: Number(limit),
      });
      res.json(users);
    } catch (error) {
      next(error);
    }
  };

  getUserById = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      const user = await this.userService.findById(id);
      if (!user) throw new NotFoundError('User not found');
      res.json(user);
    } catch (error) {
      next(error);
    }
  };

  createUser = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const dto: CreateUserDto = req.body;
      const user = await this.userService.create(dto);
      res.status(201).json(user);
    } catch (error) {
      next(error);
    }
  };
}
```

### Service Layer

```typescript
import { UserRepository } from '../repositories/user.repository';
import { CreateUserDto, UpdateUserDto } from '../validators/user.validator';
import { hashPassword } from '../utils/security';
import { ConflictError } from '../utils/errors';

export class UserService {
  constructor(private userRepo: UserRepository) {}

  async findAll(options: { page: number; limit: number }) {
    const { page, limit } = options;
    const offset = (page - 1) * limit;

    const [users, total] = await Promise.all([
      this.userRepo.findMany({ skip: offset, take: limit }),
      this.userRepo.count(),
    ]);

    return {
      data: users,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async create(dto: CreateUserDto) {
    const existing = await this.userRepo.findByEmail(dto.email);
    if (existing) throw new ConflictError('Email already exists');

    const hashedPassword = await hashPassword(dto.password);
    return this.userRepo.create({
      ...dto,
      password: hashedPassword,
    });
  }
}
```

### Repository Layer

```typescript
import { db } from '../config/database';
import { users, User, NewUser } from '../models/user.model';
import { eq } from 'drizzle-orm';

export class UserRepository {
  async findMany(options: { skip: number; take: number }) {
    return db.query.users.findMany({
      offset: options.skip,
      limit: options.take,
      orderBy: (users, { desc }) => [desc(users.createdAt)],
    });
  }

  async findById(id: string): Promise<User | null> {
    const result = await db.query.users.findFirst({
      where: eq(users.id, id),
    });
    return result ?? null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const result = await db.query.users.findFirst({
      where: eq(users.email, email),
    });
    return result ?? null;
  }

  async create(data: NewUser): Promise<User> {
    const [user] = await db.insert(users).values(data).returning();
    return user;
  }
}
```

### Validation (Zod)

```typescript
import { z } from 'zod';

export const createUserSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(8).max(100),
    name: z.string().min(1).max(100),
  }),
});

export const updateUserSchema = z.object({
  params: z.object({
    id: z.string().uuid(),
  }),
  body: z.object({
    name: z.string().min(1).max(100).optional(),
    avatar: z.string().url().optional(),
  }),
});

export type CreateUserDto = z.infer<typeof createUserSchema>['body'];
export type UpdateUserDto = z.infer<typeof updateUserSchema>['body'];
```

### Error Handling

```typescript
export class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number,
    public code?: string
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(message, 404, 'NOT_FOUND');
  }
}

export class ValidationError extends AppError {
  constructor(message = 'Validation failed', public details?: unknown) {
    super(message, 400, 'VALIDATION_ERROR');
  }
}

// Error middleware
export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: err.message,
      code: err.code,
      ...(err instanceof ValidationError && { details: err.details }),
    });
  }

  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
}
```

### Authentication Middleware

```typescript
import { verify } from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

export interface AuthRequest extends Request {
  user?: { id: string; email: string };
}

export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization header' });
  }

  const token = authHeader.substring(7);

  try {
    const decoded = verify(token, process.env.JWT_SECRET!) as { id: string; email: string };
    req.user = decoded;
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
```

## Testing

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest';
import request from 'supertest';
import { app } from '../app';

describe('POST /api/users', () => {
  it('creates a user with valid data', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({
        email: 'test@example.com',
        password: 'securepassword123',
        name: 'Test User',
      });

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('id');
    expect(response.body.email).toBe('test@example.com');
  });

  it('returns 400 for invalid email', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'invalid', password: 'password123', name: 'Test' });

    expect(response.status).toBe(400);
  });
});
```

## Common Commands

```bash
# Development
{{DEV_CMD}}

# Build
{{BUILD_CMD}}

# Run migrations
{{MIGRATE_CMD}}

# Run tests
{{TEST_CMD}}

# Lint
{{LINT_CMD}}

# Generate types (if using ORM)
{{GENERATE_CMD}}
```

## DO NOT

- Skip input validation on any endpoint
- Return stack traces in production
- Store passwords in plain text
- Skip authentication on protected routes
- Use `SELECT *` in production queries
- Log sensitive data (passwords, tokens)
- Skip rate limiting on public endpoints
- Use synchronous operations for I/O

## Response Format

```json
// Success (single item)
{ "data": { "id": "...", "name": "..." } }

// Success (list)
{
  "data": [...],
  "meta": { "page": 1, "limit": 10, "total": 100, "totalPages": 10 }
}

// Error
{ "error": "Error message", "code": "ERROR_CODE", "details": {...} }
```
