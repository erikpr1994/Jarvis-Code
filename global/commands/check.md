---
name: check
description: Quick checks for specific code quality aspects
disable-model-invocation: false
---

# /check - Quick Quality Checks

Run focused quality checks on specific aspects of code.

## What It Does

1. **Targeted checking** - Focus on one aspect at a time
2. **Fast feedback** - Quick results for specific concerns
3. **Detailed output** - Shows exactly what to fix
4. **Auto-fix option** - Can fix some issues automatically

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Check type and optional path | "types", "lint src/", "format --fix" |

## Check Types

| Type | Command | What It Checks |
|------|---------|----------------|
| `types` | tsc --noEmit | TypeScript errors |
| `lint` | eslint/biome | Code quality rules |
| `format` | prettier | Code formatting |
| `test` | vitest run | Unit test failures |
| `deps` | npm audit | Dependency vulnerabilities |
| `size` | analyze | Bundle size |
| `a11y` | axe | Accessibility issues |
| `perf` | lighthouse | Performance metrics |

## Usage

### Check types
```
/check types
```

Output:
```
## TypeScript Check

✅ No errors found

Files checked: 142
Time: 2.3s
```

Or with errors:
```
## TypeScript Check

❌ 3 errors found

src/components/Button.tsx:15:3
  error TS2322: Type 'string' is not assignable to type 'number'.

src/utils/api.ts:42:10
  error TS2345: Argument of type 'undefined' is not assignable.

src/hooks/useAuth.ts:28:5
  error TS2339: Property 'user' does not exist on type 'null'.

Files checked: 142
Time: 2.3s
```

### Check lint
```
/check lint
```

Output:
```
## Lint Check

⚠️ 5 warnings, 2 errors

Errors:
  src/api/client.ts:45:5
    error: Unexpected console.log statement (no-console)

  src/components/Modal.tsx:12:3
    error: Missing return type on function (explicit-function-return-type)

Warnings:
  src/utils/helpers.ts:23:1
    warn: Prefer const over let (prefer-const)
  ...

Fixable: 4 (run with --fix)
```

### Check format
```
/check format
```

Output:
```
## Format Check

❌ 8 files need formatting

Files:
  - src/components/Button.tsx
  - src/components/Modal.tsx
  - src/utils/helpers.ts
  - src/hooks/useAuth.ts
  - src/api/client.ts
  - src/pages/Home.tsx
  - src/pages/Settings.tsx
  - src/config/env.ts

Run '/check format --fix' to fix automatically
```

### Check with auto-fix
```
/check lint --fix
/check format --fix
```

### Check specific path
```
/check types src/components/
/check lint src/api/
```

### Check dependencies
```
/check deps
```

Output:
```
## Dependency Check

⚠️ 2 vulnerabilities found

High:
  lodash < 4.17.21
    Prototype pollution
    Fix: npm update lodash

Moderate:
  axios < 1.6.0
    SSRF vulnerability
    Fix: npm update axios

Run 'npm audit fix' to resolve
```

### Check bundle size
```
/check size
```

Output:
```
## Bundle Size Check

Total: 245 KB (gzipped: 78 KB)

Breakdown:
  - react: 42 KB
  - react-dom: 38 KB
  - lodash: 25 KB (consider tree-shaking)
  - moment: 67 KB (consider day.js)
  - app code: 73 KB

Recommendations:
  - Replace moment.js with day.js (-60 KB)
  - Use lodash-es for tree-shaking (-15 KB)
```

### Check accessibility
```
/check a11y
```

Output:
```
## Accessibility Check

⚠️ 4 issues found

Critical:
  - Button missing aria-label (src/components/IconButton.tsx)

Serious:
  - Color contrast too low (src/components/Badge.tsx)
  - Missing alt text on image (src/pages/Profile.tsx)

Moderate:
  - Heading levels skipped (src/pages/Home.tsx)

Passes: 142 rules
```

## Examples

**Check everything quickly:**
```
/check all
```

**Check types only:**
```
/check types
```

**Check and fix lint:**
```
/check lint --fix
```

**Check specific file:**
```
/check types src/components/Button.tsx
```

**Check format and fix:**
```
/check format --fix
```

**Check for vulnerabilities:**
```
/check deps
```

## Options

| Option | Description |
|--------|-------------|
| `--fix` | Auto-fix issues where possible |
| `--strict` | Fail on warnings |
| `--json` | Output as JSON |
| `--quiet` | Only show errors |
| `--watch` | Watch mode for continuous checking |

## Configuration

Configure in `settings.json`:

```json
{
  "check": {
    "types": {
      "strict": true,
      "skipLibCheck": true
    },
    "lint": {
      "fix_on_save": true,
      "rules": "recommended"
    },
    "format": {
      "on_save": true
    }
  }
}
```

## Integration

**Use in workflow:**
```
/check types && /check lint && /check test
```

**Combined with verify:**
- `/check` - Single aspect, fast feedback
- `/verify` - Full pipeline, comprehensive
