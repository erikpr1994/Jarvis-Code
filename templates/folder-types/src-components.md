# Components Directory

> Inherits from: parent CLAUDE.md
> Level: L3 (typically src/components or components/)
> Token budget: ~400 tokens

## Purpose

Reusable UI components for this application/package.

## Organization

```
components/
├── ui/                  # Base UI components (buttons, inputs, cards)
│   ├── button.tsx
│   ├── input.tsx
│   └── index.ts
├── layout/              # Layout components (header, footer, sidebar)
│   ├── header.tsx
│   └── index.ts
├── features/            # Feature-specific components
│   └── [feature]/
│       ├── component.tsx
│       └── index.ts
└── index.ts             # Re-exports
```

## Component Pattern

### File Structure

Each component should follow this structure:

```typescript
// component-name.tsx

import { type ComponentProps } from 'react';

// Types first
interface ComponentNameProps {
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}

// Component
export function ComponentName({
  variant = 'primary',
  size = 'md',
  children,
}: ComponentNameProps) {
  return (
    <div className={cn(
      'base-styles',
      variantStyles[variant],
      sizeStyles[size]
    )}>
      {children}
    </div>
  );
}

// Variant/size maps if needed
const variantStyles = { ... };
const sizeStyles = { ... };
```

### Naming Conventions

| Pattern | Example |
|---------|---------|
| Component files | `component-name.tsx` (kebab-case) |
| Component names | `ComponentName` (PascalCase) |
| Props interface | `ComponentNameProps` |
| Hooks | `use-component-logic.ts` |
| Utilities | `component-utils.ts` |
| Tests | `component-name.test.tsx` |

## Key Patterns

### Composition over Configuration

```typescript
// Good - composable
<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
  </CardHeader>
  <CardContent>Content</CardContent>
</Card>

// Avoid - over-configured
<Card title="Title" content="Content" showHeader={true} />
```

### Forward Refs for DOM Access

```typescript
export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, ...props }, ref) => (
    <input ref={ref} className={cn('...', className)} {...props} />
  )
);
Input.displayName = 'Input';
```

### Accessibility Requirements

- All interactive elements must be keyboard accessible
- Use semantic HTML elements
- Include ARIA attributes when needed
- Maintain focus management for modals/dropdowns

## Styling

{{STYLING_APPROACH}}

```typescript
// Example with Tailwind
<div className={cn(
  'rounded-lg border bg-card text-card-foreground shadow-sm',
  className
)} />

// Example with CSS Modules
import styles from './component.module.css';
<div className={styles.container} />
```

## Testing

```typescript
import { render, screen, fireEvent } from '@testing-library/react';

describe('ComponentName', () => {
  it('renders correctly', () => {
    render(<ComponentName>Content</ComponentName>);
    expect(screen.getByText('Content')).toBeInTheDocument();
  });

  it('handles click events', () => {
    const onClick = vi.fn();
    render(<ComponentName onClick={onClick}>Click me</ComponentName>);
    fireEvent.click(screen.getByText('Click me'));
    expect(onClick).toHaveBeenCalled();
  });
});
```

## DO NOT

- Create components larger than 200 lines (split them)
- Add business logic to UI components
- Use inline styles (use styling system)
- Skip accessibility attributes
- Create deeply nested component trees (max 3-4 levels)
- Duplicate components that exist in ui/ folder

## When to Extract

Extract to a shared component when:

- Used in 3+ places
- Likely to be reused in other features
- Has stable API and behavior

Keep local when:

- Feature-specific styling/behavior
- Still evolving/unstable
- Only used in one feature
