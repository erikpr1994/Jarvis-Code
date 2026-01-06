---
name: add-component
description: Create a new component with tests, types, and optional Storybook/documentation following project patterns
disable-model-invocation: false
---

# /add-component - Create Component with Tests

Create a new UI component complete with tests, types, and optional Storybook stories following your project's established patterns.

## What It Does

1. **Detects patterns** - Analyzes existing components for conventions
2. **Creates component** - Generates component file with proper structure
3. **Adds tests** - Creates test file with appropriate framework
4. **Includes types** - Adds TypeScript interfaces for props
5. **Adds stories** - Creates Storybook story if applicable
6. **Updates exports** - Adds to barrel exports if used

## Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | Component name and optional flags | "Button", "UserCard --story" |

## Process

### Phase 1: Pattern Detection

1. **Analyze existing components**
   - Find component directory (`components/`, `src/components/`, etc.)
   - Detect component file structure (single file vs folder)
   - Identify naming conventions (PascalCase, index exports, etc.)
   - Check for CSS-in-JS, CSS Modules, or other styling

2. **Detect test patterns**
   - Test file location (co-located vs `__tests__/`)
   - Test framework (Jest, Vitest, React Testing Library)
   - Test file naming (`*.test.tsx`, `*.spec.tsx`)

3. **Check for Storybook**
   - Look for `.storybook/` directory
   - Detect story format (CSF2 vs CSF3)
   - Find story file patterns (`*.stories.tsx`)

4. **Load conventions from CLAUDE.md**

### Phase 2: Structure Planning

5. **Determine component structure**

   **Single File Pattern:**
   ```
   components/
   └── ComponentName.tsx
   └── ComponentName.test.tsx
   └── ComponentName.stories.tsx (if Storybook)
   ```

   **Folder Pattern:**
   ```
   components/
   └── ComponentName/
       ├── index.tsx
       ├── ComponentName.tsx
       ├── ComponentName.test.tsx
       ├── ComponentName.stories.tsx
       ├── ComponentName.module.css (if CSS Modules)
       └── types.ts (optional)
   ```

6. **Confirm with user**
   - Show proposed structure
   - Allow customization
   - Confirm location

### Phase 3: Component Generation

7. **Create component file**

   **React Functional Component:**
   ```tsx
   import { type FC } from 'react';

   export interface [ComponentName]Props {
     /** Description of prop */
     children?: React.ReactNode;
     /** Additional class names */
     className?: string;
   }

   /**
    * [ComponentName] - Brief description
    *
    * @example
    * <[ComponentName]>Content</[ComponentName]>
    */
   export const [ComponentName]: FC<[ComponentName]Props> = ({
     children,
     className,
   }) => {
     return (
       <div className={className}>
         {children}
       </div>
     );
   };

   [ComponentName].displayName = '[ComponentName]';
   ```

   **With forwardRef (if pattern detected):**
   ```tsx
   import { forwardRef, type HTMLAttributes } from 'react';

   export interface [ComponentName]Props extends HTMLAttributes<HTMLDivElement> {
     /** Description */
   }

   export const [ComponentName] = forwardRef<HTMLDivElement, [ComponentName]Props>(
     ({ className, children, ...props }, ref) => {
       return (
         <div ref={ref} className={className} {...props}>
           {children}
         </div>
       );
     }
   );

   [ComponentName].displayName = '[ComponentName]';
   ```

### Phase 4: Test Generation

8. **Create test file**

   **React Testing Library + Vitest:**
   ```tsx
   import { describe, it, expect } from 'vitest';
   import { render, screen } from '@testing-library/react';
   import userEvent from '@testing-library/user-event';
   import { [ComponentName] } from './[ComponentName]';

   describe('[ComponentName]', () => {
     it('renders children correctly', () => {
       render(<[ComponentName]>Test content</[ComponentName]>);

       expect(screen.getByText('Test content')).toBeInTheDocument();
     });

     it('applies custom className', () => {
       render(<[ComponentName] className="custom">Content</[ComponentName]>);

       expect(screen.getByText('Content')).toHaveClass('custom');
     });

     it('handles user interaction', async () => {
       const user = userEvent.setup();
       // TODO: Add interaction tests

       expect(true).toBe(true);
     });
   });
   ```

   **Jest (if detected):**
   ```tsx
   import { render, screen } from '@testing-library/react';
   import { [ComponentName] } from './[ComponentName]';

   describe('[ComponentName]', () => {
     it('renders without crashing', () => {
       render(<[ComponentName] />);
       // Add assertions
     });
   });
   ```

### Phase 5: Story Generation (if Storybook)

9. **Create Storybook story**

   **CSF3 Format (modern):**
   ```tsx
   import type { Meta, StoryObj } from '@storybook/react';
   import { [ComponentName] } from './[ComponentName]';

   const meta: Meta<typeof [ComponentName]> = {
     title: 'Components/[ComponentName]',
     component: [ComponentName],
     tags: ['autodocs'],
     argTypes: {
       // Define controls
     },
   };

   export default meta;
   type Story = StoryObj<typeof [ComponentName]>;

   export const Default: Story = {
     args: {
       children: 'Default content',
     },
   };

   export const WithCustomClass: Story = {
     args: {
       children: 'Custom styled',
       className: 'custom-class',
     },
   };
   ```

### Phase 6: Styling (if applicable)

10. **Create styles based on project pattern**

    **CSS Modules:**
    ```css
    /* [ComponentName].module.css */
    .root {
      /* Base styles */
    }

    .variant-primary {
      /* Primary variant */
    }
    ```

    **Tailwind (no file needed, classes in component):**
    ```tsx
    <div className="flex items-center justify-center p-4">
    ```

    **Styled Components:**
    ```tsx
    const StyledWrapper = styled.div`
      /* Styles */
    `;
    ```

### Phase 7: Integration

11. **Update barrel exports**

    **If index.ts exists:**
    ```typescript
    // components/index.ts
    export * from './[ComponentName]';
    ```

12. **Update component registry** (if applicable)

## Output

```markdown
## Component Created

**Name**: [ComponentName]
**Location**: [path]
**Pattern**: [single-file/folder]

### Files Created
- `[path]/[ComponentName].tsx` - Component implementation
- `[path]/[ComponentName].test.tsx` - Component tests
- `[path]/[ComponentName].stories.tsx` - Storybook stories (if applicable)
- `[path]/[ComponentName].module.css` - Styles (if CSS Modules)

### Exports Updated
- `components/index.ts` - Added export

### Next Steps
1. Implement component logic
2. Add prop types and documentation
3. Write additional test cases
4. Run tests: `npm test [ComponentName]`
5. View in Storybook: `npm run storybook`

### Usage
\`\`\`tsx
import { [ComponentName] } from '@/components';

<[ComponentName]>Content</[ComponentName]>
\`\`\`
```

## Flags

| Flag | Description |
|------|-------------|
| `--story` | Force create Storybook story |
| `--no-story` | Skip Storybook story |
| `--no-test` | Skip test file |
| `--folder` | Force folder structure |
| `--flat` | Force single file structure |
| `--path <path>` | Specify custom location |

## Examples

**Basic component:**
```
/add-component Button
```

**With Storybook story:**
```
/add-component UserCard --story
```

**In specific directory:**
```
/add-component Modal --path src/components/ui
```

**Folder structure:**
```
/add-component DataTable --folder
```

**Multiple components:**
```
/add-component Header Footer Sidebar
```

## Pattern Adaptation

| Pattern Detected | Structure Created |
|------------------|-------------------|
| Flat components | `Component.tsx` + `Component.test.tsx` |
| Folder components | `Component/index.tsx` + subfiles |
| CSS Modules | Add `.module.css` file |
| Tailwind | Use utility classes in component |
| Styled Components | Add styled wrappers |
| Storybook v6 | CSF2 format stories |
| Storybook v7+ | CSF3 format stories |

## Notes

- Analyzes existing components to match patterns
- Uses project's test framework configuration
- Respects existing naming conventions
- Creates minimal but complete boilerplate
- Test file includes basic smoke tests
- Storybook stories include common variants
- Does not overwrite existing files
