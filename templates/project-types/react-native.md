# React Native Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template + typescript.md
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~800 tokens

This template extends the base CLAUDE.md with React Native-specific patterns.

## Tech Stack Additions

```yaml
framework:
  - React Native {{RN_VERSION}}
  - React {{REACT_VERSION}}
  - Expo {{EXPO_VERSION}}  # if using Expo

navigation:
  - {{NAVIGATION_LIBRARY}}  # react-navigation | expo-router

state_management:
  - {{STATE_LIBRARY}}  # zustand | redux-toolkit | react-query

styling:
  - {{STYLING_APPROACH}}  # StyleSheet | nativewind | styled-components
```

## Project Structure

### Expo Router (if applicable)

```
app/
├── _layout.tsx          # Root layout
├── index.tsx            # Home screen
├── (tabs)/              # Tab navigator group
│   ├── _layout.tsx      # Tab bar config
│   ├── index.tsx        # First tab
│   └── profile.tsx      # Profile tab
├── [id].tsx             # Dynamic route
└── modal.tsx            # Modal screen

src/
├── components/          # Shared components
├── hooks/               # Custom hooks
├── lib/                 # Utilities
├── stores/              # State management
└── types/               # TypeScript types
```

### React Navigation (if applicable)

```
src/
├── screens/             # Screen components
│   ├── HomeScreen.tsx
│   └── ProfileScreen.tsx
├── navigation/          # Navigation config
│   ├── AppNavigator.tsx
│   └── types.ts
├── components/          # Shared components
├── hooks/               # Custom hooks
└── lib/                 # Utilities
```

## Key Patterns

### Component Structure

```typescript
import { View, Text, StyleSheet, Pressable } from 'react-native';
import type { ComponentProps } from 'react';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
}

export function Button({
  title,
  onPress,
  variant = 'primary',
  disabled = false
}: ButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.button,
        styles[variant],
        pressed && styles.pressed,
        disabled && styles.disabled,
      ]}
    >
      <Text style={[styles.text, styles[`${variant}Text`]]}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    alignItems: 'center',
  },
  primary: {
    backgroundColor: '#007AFF',
  },
  secondary: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#007AFF',
  },
  pressed: {
    opacity: 0.8,
  },
  disabled: {
    opacity: 0.5,
  },
  text: {
    fontSize: 16,
    fontWeight: '600',
  },
  primaryText: {
    color: '#FFFFFF',
  },
  secondaryText: {
    color: '#007AFF',
  },
});
```

### Navigation (Expo Router)

```typescript
// app/_layout.tsx
import { Stack } from 'expo-router';

export default function RootLayout() {
  return (
    <Stack>
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="modal" options={{ presentation: 'modal' }} />
    </Stack>
  );
}

// Navigation in components
import { Link, useRouter } from 'expo-router';

function HomeScreen() {
  const router = useRouter();

  return (
    <View>
      <Link href="/profile">Go to Profile</Link>
      <Button
        title="Details"
        onPress={() => router.push({ pathname: '/[id]', params: { id: '123' } })}
      />
    </View>
  );
}
```

### Data Fetching with React Query

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// Fetch hook
export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

// Mutation hook
export function useUpdateUser() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: updateUser,
    onSuccess: (data, variables) => {
      queryClient.setQueryData(['user', variables.userId], data);
    },
  });
}

// Usage in component
function ProfileScreen() {
  const { data: user, isLoading, error } = useUser('123');
  const updateUser = useUpdateUser();

  if (isLoading) return <ActivityIndicator />;
  if (error) return <Text>Error: {error.message}</Text>;

  return (
    <View>
      <Text>{user.name}</Text>
      <Button
        title="Update"
        onPress={() => updateUser.mutate({ userId: '123', name: 'New Name' })}
        disabled={updateUser.isPending}
      />
    </View>
  );
}
```

### Platform-Specific Code

```typescript
import { Platform, StyleSheet } from 'react-native';

const styles = StyleSheet.create({
  container: {
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.25,
        shadowRadius: 4,
      },
      android: {
        elevation: 5,
      },
    }),
  },
});

// Or use file extensions
// Button.ios.tsx
// Button.android.tsx
```

### Safe Area Handling

```typescript
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

function Screen({ children }) {
  const insets = useSafeAreaInsets();

  return (
    <View style={{
      flex: 1,
      paddingTop: insets.top,
      paddingBottom: insets.bottom
    }}>
      {children}
    </View>
  );
}
```

## Testing

### Component Testing

```typescript
import { render, fireEvent, screen } from '@testing-library/react-native';
import { Button } from './Button';

describe('Button', () => {
  it('calls onPress when pressed', () => {
    const onPress = jest.fn();
    render(<Button title="Press Me" onPress={onPress} />);

    fireEvent.press(screen.getByText('Press Me'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('shows disabled state', () => {
    render(<Button title="Disabled" onPress={() => {}} disabled />);
    expect(screen.getByText('Disabled')).toBeDisabled();
  });
});
```

### Navigation Testing

```typescript
import { renderRouter, screen } from 'expo-router/testing-library';

describe('Navigation', () => {
  it('navigates to profile', async () => {
    renderRouter({
      index: () => <HomeScreen />,
      'profile': () => <ProfileScreen />,
    });

    fireEvent.press(screen.getByText('Go to Profile'));
    expect(screen).toHavePathname('/profile');
  });
});
```

## Common Commands

```bash
# Development
{{DEV_CMD}}

# iOS simulator
{{IOS_CMD}}

# Android emulator
{{ANDROID_CMD}}

# Build (Expo)
{{BUILD_CMD}}

# Type check
{{TYPECHECK_CMD}}

# Run tests
{{TEST_CMD}}
```

## DO NOT

- Use web-specific APIs (window, document)
- Forget to handle platform differences (iOS vs Android)
- Use fixed pixel values without considering screen density
- Skip safe area handling for notched devices
- Nest ScrollViews without careful consideration
- Use heavy animations without native driver
- Forget to handle keyboard avoiding on forms
- Import from react-native-web accidentally

## Performance Considerations

- Use `React.memo` for expensive list items
- Use `FlatList` over `ScrollView` for long lists
- Enable Hermes for faster JS execution
- Use native driver for animations: `useNativeDriver: true`
- Avoid inline styles in frequently re-rendered components
- Use `Image.prefetch()` for critical images

## File Conventions

| Pattern | Purpose |
|---------|---------|
| `*.tsx` | React Native components |
| `*.ios.tsx` | iOS-specific component |
| `*.android.tsx` | Android-specific component |
| `*.native.tsx` | Native platform (iOS + Android) |
| `*.web.tsx` | Web-specific (if using Expo Web) |
| `__tests__/*.test.tsx` | Test files |
