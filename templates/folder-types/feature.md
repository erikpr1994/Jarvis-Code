# Feature Directory

> Inherits from: parent CLAUDE.md
> Level: L2 (features/*/ or modules/*/)
> Token budget: ~400 tokens

## Purpose

Self-contained feature module with its own components, hooks, services, and types. Represents a vertical slice of functionality.

## Organization

```
features/
└── [feature-name]/
    ├── components/          # Feature-specific components
    │   ├── feature-list.tsx
    │   ├── feature-card.tsx
    │   └── index.ts
    ├── hooks/               # Feature-specific hooks
    │   ├── use-feature.ts
    │   └── index.ts
    ├── services/            # API calls, business logic
    │   ├── feature.service.ts
    │   └── index.ts
    ├── types/               # Feature-specific types
    │   └── index.ts
    ├── utils/               # Feature-specific utilities
    │   └── index.ts
    ├── __tests__/           # Tests (or co-located)
    │   └── feature.test.ts
    └── index.ts             # Public exports
```

## Feature Boundaries

### What Belongs in a Feature

- Components only used by this feature
- Hooks specific to feature logic
- Service functions for feature API calls
- Types/interfaces for feature data
- Feature-specific utilities

### What Goes in Shared

- Components used by 2+ features → `components/`
- Hooks used by 2+ features → `hooks/`
- Types used across features → `types/`

## Export Pattern

```typescript
// features/auth/index.ts
// Only export the public API

// Components
export { LoginForm } from './components/login-form';
export { AuthProvider, useAuth } from './components/auth-provider';

// Hooks
export { useSession } from './hooks/use-session';

// Types
export type { User, Session } from './types';

// DO NOT export internal components, utilities, or services
```

## Component Pattern

```typescript
// features/tasks/components/task-list.tsx
import { useTasks } from '../hooks/use-tasks';
import { TaskCard } from './task-card';
import type { Task } from '../types';

export function TaskList({ projectId }: { projectId: string }) {
  const { tasks, isLoading, error } = useTasks(projectId);

  if (isLoading) return <TaskListSkeleton />;
  if (error) return <TaskListError error={error} />;

  return (
    <div className="space-y-2">
      {tasks.map((task) => (
        <TaskCard key={task.id} task={task} />
      ))}
    </div>
  );
}
```

## Service Pattern

```typescript
// features/tasks/services/task.service.ts
import { api } from '@/lib/api';
import type { Task, CreateTaskInput } from '../types';

export const taskService = {
  async getAll(projectId: string): Promise<Task[]> {
    return api.get(`/projects/${projectId}/tasks`);
  },

  async create(projectId: string, input: CreateTaskInput): Promise<Task> {
    return api.post(`/projects/${projectId}/tasks`, input);
  },

  async update(taskId: string, input: Partial<Task>): Promise<Task> {
    return api.patch(`/tasks/${taskId}`, input);
  },

  async delete(taskId: string): Promise<void> {
    return api.delete(`/tasks/${taskId}`);
  },
};
```

## Hook Pattern

```typescript
// features/tasks/hooks/use-tasks.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { taskService } from '../services/task.service';

export function useTasks(projectId: string) {
  return useQuery({
    queryKey: ['tasks', projectId],
    queryFn: () => taskService.getAll(projectId),
  });
}

export function useCreateTask(projectId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: CreateTaskInput) => taskService.create(projectId, input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks', projectId] });
    },
  });
}
```

## Cross-Feature Communication

Features should communicate through:

1. **Props** - Parent passes data down
2. **Context** - Shared state providers
3. **Events** - Custom events or event bus
4. **URL State** - Search params, route params

```typescript
// Using context for cross-feature state
import { useAuth } from '@/features/auth';

function TaskList() {
  const { user } = useAuth(); // From auth feature
  // Use user context in task feature
}
```

## Testing

```typescript
// features/tasks/__tests__/task-list.test.tsx
import { render, screen } from '@testing-library/react';
import { TaskList } from '../components/task-list';
import { mockTasks } from '../__fixtures__/tasks';

// Mock the hook
vi.mock('../hooks/use-tasks', () => ({
  useTasks: () => ({ tasks: mockTasks, isLoading: false }),
}));

describe('TaskList', () => {
  it('renders tasks', () => {
    render(<TaskList projectId="1" />);
    expect(screen.getAllByRole('article')).toHaveLength(mockTasks.length);
  });
});
```

## DO NOT

- Import from another feature's internal files (use public exports)
- Create circular dependencies between features
- Put shared components in a feature folder
- Export implementation details (services, internal hooks)
- Mix feature logic with UI library components
- Create features with less than 3 files (too small)
