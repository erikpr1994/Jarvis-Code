---
name: add-feature
description: Scaffold a new feature structure with tests, implementation files, and types following project patterns
disable-model-invocation: false
---

# /add-feature - Scaffold New Feature

Create a complete feature structure including implementation files, tests, types, and documentation following your project's established patterns.

## What It Does

1. **Analyzes patterns** - Detects existing feature structure in your project
2. **Creates scaffolding** - Generates all necessary files and folders
3. **Adds tests** - Creates test files with proper setup
4. **Includes types** - Adds TypeScript types/interfaces if applicable
5. **Follows conventions** - Matches your project's naming and organization

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Feature name and optional type hint | "user-profile", "payment --api" |

## Process

### Phase 1: Pattern Detection

1. **Analyze project structure**
   - Scan for existing features
   - Identify directory patterns
   - Detect naming conventions
   - Find test file locations

2. **Determine feature type**
   - Full-stack feature (API + UI)
   - API-only feature
   - UI-only feature
   - Utility/library feature

3. **Load project conventions from CLAUDE.md**
   - File naming patterns
   - Directory organization
   - Test conventions
   - Type definitions location

### Phase 2: Structure Planning

4. **Map feature structure based on project patterns**

   **Next.js/React Project:**
   ```
   src/
   ├── features/[feature-name]/
   │   ├── components/
   │   │   ├── [Component].tsx
   │   │   └── [Component].test.tsx
   │   ├── hooks/
   │   │   ├── use[Feature].ts
   │   │   └── use[Feature].test.ts
   │   ├── api/
   │   │   ├── [feature].ts
   │   │   └── [feature].test.ts
   │   ├── types/
   │   │   └── index.ts
   │   └── index.ts
   ```

   **Express/API Project:**
   ```
   src/
   ├── modules/[feature-name]/
   │   ├── [feature].controller.ts
   │   ├── [feature].service.ts
   │   ├── [feature].repository.ts
   │   ├── [feature].types.ts
   │   ├── [feature].routes.ts
   │   └── __tests__/
   │       ├── [feature].controller.test.ts
   │       └── [feature].service.test.ts
   ```

   **Python Project:**
   ```
   src/[feature_name]/
   ├── __init__.py
   ├── models.py
   ├── services.py
   ├── routes.py
   └── tests/
       ├── __init__.py
       ├── test_models.py
       └── test_services.py
   ```

5. **Confirm structure with user**
   - Show proposed file structure
   - Allow customization
   - Confirm before creation

### Phase 3: File Generation

6. **Create directory structure**
   - Create feature directory
   - Create subdirectories as needed

7. **Generate implementation files**

   **Main module (index.ts):**
   ```typescript
   // Feature: [FeatureName]
   // Created: [date]

   export * from './types';
   export * from './components';
   export * from './hooks';
   ```

   **Types file:**
   ```typescript
   // Types for [FeatureName] feature

   export interface [FeatureName] {
     id: string;
     // Add properties
   }

   export interface [FeatureName]CreateInput {
     // Add input properties
   }

   export interface [FeatureName]UpdateInput {
     // Add update properties
   }
   ```

8. **Generate test files**

   **Test file template:**
   ```typescript
   import { describe, it, expect, beforeEach } from 'vitest';
   // or jest, depending on project

   describe('[FeatureName]', () => {
     beforeEach(() => {
       // Setup
     });

     describe('[functionality]', () => {
       it('should [expected behavior]', () => {
         // Arrange
         // Act
         // Assert
         expect(true).toBe(true); // TODO: Implement
       });
     });
   });
   ```

9. **Add boilerplate based on feature type**

   **API endpoint:**
   ```typescript
   // [feature].controller.ts
   export async function get[Feature](req: Request, res: Response) {
     // TODO: Implement
   }

   export async function create[Feature](req: Request, res: Response) {
     // TODO: Implement
   }
   ```

   **React component:**
   ```typescript
   // [Feature].tsx
   interface [Feature]Props {
     // Add props
   }

   export function [Feature]({ }: [Feature]Props) {
     return (
       <div>
         {/* TODO: Implement */}
       </div>
     );
   }
   ```

### Phase 4: Integration

10. **Update barrel exports**
    - Add to parent index.ts if exists
    - Update module registry if applicable

11. **Add route registration** (if API)
    - Add to router configuration
    - Register middleware if needed

12. **Update type exports** (if TypeScript)
    - Add to global types index
    - Update module declarations

### Phase 5: Documentation

13. **Create feature README** (optional, if requested)
    ```markdown
    # [FeatureName] Feature

    ## Overview
    [Brief description]

    ## Usage
    [How to use this feature]

    ## API
    [Exported functions/components]
    ```

14. **Add TODO comments**
    - Mark implementation points
    - Note integration requirements
    - List pending decisions

## Output

```markdown
## Feature Scaffolded

**Feature**: [feature-name]
**Type**: [full-stack/api/ui/utility]
**Location**: [path]

### Files Created
- `src/features/[name]/index.ts` - Main export
- `src/features/[name]/types/index.ts` - Type definitions
- `src/features/[name]/components/[Name].tsx` - Main component
- `src/features/[name]/components/[Name].test.tsx` - Component tests
- `src/features/[name]/hooks/use[Name].ts` - Custom hook
- `src/features/[name]/hooks/use[Name].test.ts` - Hook tests

### Next Steps
1. Define types in `types/index.ts`
2. Implement component logic
3. Write tests (TDD recommended)
4. Integrate with existing code

### Quick Commands
- Run tests: `npm test src/features/[name]`
- Type check: `npm run typecheck`
```

## Feature Type Flags

**Full-stack (default):**
```
/add-feature user-profile
```

**API only:**
```
/add-feature payments --api
```

**UI only:**
```
/add-feature dashboard --ui
```

**Utility/library:**
```
/add-feature date-utils --util
```

## Examples

**Create user profile feature:**
```
/add-feature user-profile
```

**Create API-only feature:**
```
/add-feature notifications --api
```

**Create with specific path:**
```
/add-feature analytics --path src/modules
```

**Create minimal structure:**
```
/add-feature auth --minimal
```

## Pattern Matching

The command adapts to your project:

| Project Type | Detection | Structure |
|--------------|-----------|-----------|
| Next.js App Router | `app/` directory | `app/[feature]/` route groups |
| Next.js Pages | `pages/` directory | `src/features/` + `pages/` |
| React SPA | `src/components/` | `src/features/` or `src/modules/` |
| Express | `routes/` + `controllers/` | `src/modules/[feature]/` |
| Python | `__init__.py` files | `src/[feature]/` package |
| Go | `go.mod` | `internal/[feature]/` |

## Notes

- Always analyzes existing patterns before scaffolding
- Creates test files alongside implementation files
- Follows project naming conventions (camelCase, kebab-case, etc.)
- Adds TypeScript types if project uses TypeScript
- Includes TODO comments for implementation guidance
- Does not overwrite existing files without confirmation
