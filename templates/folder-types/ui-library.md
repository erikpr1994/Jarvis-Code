# UI Library

> Inherits from: parent CLAUDE.md
> Level: L2 (packages/ui/ or similar)
> Token budget: ~400 tokens

## Purpose

Shared component library for use across applications. Contains base UI primitives, design system components, and accessibility patterns.

## Organization

```
ui/
├── src/
│   ├── components/
│   │   ├── button/
│   │   │   ├── button.tsx
│   │   │   ├── button.test.tsx
│   │   │   └── index.ts
│   │   ├── input/
│   │   └── card/
│   ├── primitives/        # Unstyled base components
│   │   ├── dialog/
│   │   └── popover/
│   ├── hooks/             # Shared hooks
│   │   ├── use-media-query.ts
│   │   └── use-click-outside.ts
│   ├── utils/
│   │   └── cn.ts          # Class name utility
│   └── index.ts           # Public exports
├── package.json
├── tsconfig.json
└── README.md
```

## Component Structure

### Standard Component

```typescript
// button/button.tsx
import { forwardRef, type ComponentProps } from 'react';
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '../utils/cn';

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        outline: 'border border-input bg-background hover:bg-accent',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
      },
      size: {
        sm: 'h-9 px-3 text-sm',
        md: 'h-10 px-4',
        lg: 'h-11 px-8 text-lg',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
    },
  }
);

export interface ButtonProps
  extends ComponentProps<'button'>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button';
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = 'Button';
```

### Export Pattern

```typescript
// button/index.ts
export { Button, type ButtonProps } from './button';

// src/index.ts (public API)
export * from './components/button';
export * from './components/input';
export * from './components/card';
export * from './hooks';
export { cn } from './utils/cn';
```

## Key Patterns

### Accessibility First

- Use semantic HTML elements
- Include ARIA attributes
- Support keyboard navigation
- Test with screen readers

### Composability

```typescript
// Prefer composition
<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
    <CardDescription>Description</CardDescription>
  </CardHeader>
  <CardContent>Content</CardContent>
  <CardFooter>Actions</CardFooter>
</Card>
```

### Forward Refs

Always use forwardRef for DOM element access:

```typescript
export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => (
    <input type={type} className={cn('...', className)} ref={ref} {...props} />
  )
);
```

## Testing

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('Button', () => {
  it('renders with correct variant', () => {
    render(<Button variant="outline">Click me</Button>);
    expect(screen.getByRole('button')).toHaveClass('border');
  });

  it('supports asChild pattern', () => {
    render(<Button asChild><a href="/link">Link</a></Button>);
    expect(screen.getByRole('link')).toBeInTheDocument();
  });
});
```

## DO NOT

- Add business logic to UI components
- Create non-accessible components
- Use component-specific colors (use CSS variables)
- Skip displayName for forwardRef components
- Export internal utilities
- Break existing prop APIs (backwards compatibility)

## Documentation

Each component should have:
- JSDoc comments on props
- Storybook stories (if applicable)
- Usage examples in README
