---
name: comments-policy
category: quality
confidence: 0.8
description: Policy for code comments - prevent useless "slop" comments on self-documenting code
source: https://x.com/jarrodwatts/status/2008761427805544674
---

# Comment Policy

## Principle

> **Code should be self-documenting.** If you need a comment to explain WHAT the code does, consider refactoring to make it clearer.

Comments should explain **WHY**, not **WHAT**.

> 📝 **Note:** Examples use JavaScript/TypeScript syntax but the principles apply across all programming languages.

---

## Unacceptable Comments

### 1. Comments That Restate What Code Does

```typescript
// BAD: Restates the obvious
// Increment counter
counter++;

// Get user by ID
const user = getUserById(id);

// Check if user exists
if (user) { }

// Loop through items
for (const item of items) { }
```

### 2. Captain Obvious Comments

```typescript
// BAD: Adds no information
// Define variables
let name = "John";
let age = 30;

// Return the result
return result;

// Import dependencies
import { useState } from 'react';
```

### 3. Useless Placeholder Comments

```typescript
// BAD: Empty or meaningless
// TODO
// Fix this
// Handle error
// Process data
```

### 4. Comments Instead of Good Naming

```typescript
// BAD: Comment compensates for bad naming
// Calculate the total price including tax
const x = calculateX(items);

// GOOD: Name is self-documenting
const totalPriceWithTax = calculateTotalWithTax(items);
```

### 5. Changelog Comments in Code

```typescript
// BAD: Version history in code
// v2.0 - Now supports async
// v1.5 - Added error handling
// v1.0 - Initial implementation
function processData() { }
```

Use git history for this, not comments.

---

## Acceptable Comments

### 1. Explain WHY, Not WHAT

```typescript
// GOOD: Explains reasoning
// Rate limit to prevent abuse - max 10 requests per minute per IP
const rateLimiter = createRateLimiter({ max: 10, window: '1m' });

// GOOD: Explains business logic
// Users get 3 free trials before requiring payment (per product decision 2024-01)
if (user.trialCount >= 3) {
  requirePayment();
}
```

### 2. Warn About Non-Obvious Behavior

```typescript
// GOOD: Warns about gotcha
// NOTE: This mutates the original array - use [...arr].sort() if immutability needed
arr.sort();

// GOOD: Explains workaround
// Safari doesn't support date parsing in this format, so we normalize first
const normalizedDate = date.replace(/-/g, '/');
```

### 3. Document Complex Algorithms

```typescript
// GOOD: Explains algorithm choice
// Using binary search for O(log n) lookup - array must be pre-sorted
function findItem(sortedArray, target) { }
```

### 4. API Documentation (JSDoc)

```typescript
// GOOD: Documents public API
/**
 * Creates a new user account.
 * 
 * @param email - Must be unique and valid email format
 * @param password - Minimum 8 characters
 * @returns The created user object
 * @throws {ValidationError} If email already exists
 */
function createUser(email: string, password: string): User { }
```

### 5. TODO with Context

```typescript
// GOOD: Actionable TODO
// TODO(erik): Refactor to use the new auth service after Q1 migration
// See: https://linear.app/team/issue/AUTH-123

// BAD: Vague TODO
// TODO: fix this
```

### 6. Disabled/Commented-Out Code

Commented-out code is acceptable **only** when accompanied by a NOTE with date, owner, and a tracked issue/link. If obsolete, remove it entirely.

```typescript
// GOOD: Disabled with context and tracking
// NOTE: Disabled 2026-01-08 - Waiting for AUTH-123 to ship before re-enabling OAuth flow
// Owner: @erik | See: https://linear.app/team/issue/AUTH-123
// const oauthHandler = initializeOAuth(config);

// BAD: No context - is this obsolete or waiting for something?
// const oauthHandler = initializeOAuth(config);
```

**When to keep vs remove:**
- ✅ **Keep** if blocked by a tracked issue or feature flag
- ❌ **Remove** if obsolete or no longer needed

---

## Quick Test

Before writing a comment, ask:

1. **Does the code speak for itself?** → Don't comment
2. **Could I rename something to eliminate the need?** → Rename instead
3. **Am I explaining WHAT?** → Refactor or delete comment
4. **Am I explaining WHY?** → Good comment, keep it
5. **Is this a warning about non-obvious behavior?** → Good comment, keep it

---

## Summary

| Comment Type | Verdict |
|--------------|---------|
| Explains WHAT code does | ❌ Delete or refactor |
| Explains WHY code exists | ✅ Keep |
| Captain Obvious | ❌ Delete |
| Warns about gotchas | ✅ Keep |
| Compensates for bad naming | ❌ Rename instead |
| Documents public API | ✅ Keep |
| Changelog in code | ❌ Use git history |
| Vague TODO | ❌ Add context or delete |
| Disabled code with tracking | ✅ Keep |
| Disabled code without context | ❌ Remove or add context |
