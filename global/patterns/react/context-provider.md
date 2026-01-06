---
name: React Context Provider
category: framework
language: typescript
framework: react
keywords: [react, context, provider, state-management, global-state]
confidence: 0.85
---

# React Context Provider Pattern

## Problem

Prop drilling becomes unwieldy:
- Passing props through many component levels
- Components receive props they don't use
- Hard to track data flow
- Difficult to refactor

## Solution

Use React Context to provide values to a subtree without explicit prop passing. Combine with custom hooks for type-safe access.

## Implementation

### Basic Context with Custom Hook

```typescript
// contexts/theme-context.tsx
'use client';

import {
  createContext,
  useContext,
  useState,
  useCallback,
  type ReactNode,
} from 'react';

type Theme = 'light' | 'dark' | 'system';

interface ThemeContextValue {
  theme: Theme;
  setTheme: (theme: Theme) => void;
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>('system');

  const toggleTheme = useCallback(() => {
    setTheme((current) => (current === 'light' ? 'dark' : 'light'));
  }, []);

  return (
    <ThemeContext.Provider value={{ theme, setTheme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

// Custom hook with type safety
export function useTheme(): ThemeContextValue {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
}

// Usage
function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();
  return (
    <button onClick={toggleTheme}>
      Current: {theme}
    </button>
  );
}
```

### Context with Reducer

```typescript
// contexts/cart-context.tsx
'use client';

import {
  createContext,
  useContext,
  useReducer,
  type ReactNode,
  type Dispatch,
} from 'react';

// Types
interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  total: number;
}

type CartAction =
  | { type: 'ADD_ITEM'; payload: Omit<CartItem, 'quantity'> }
  | { type: 'REMOVE_ITEM'; payload: { id: string } }
  | { type: 'UPDATE_QUANTITY'; payload: { id: string; quantity: number } }
  | { type: 'CLEAR_CART' };

// Reducer
function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existingIndex = state.items.findIndex(
        (item) => item.id === action.payload.id,
      );

      let newItems: CartItem[];
      if (existingIndex >= 0) {
        newItems = state.items.map((item, index) =>
          index === existingIndex
            ? { ...item, quantity: item.quantity + 1 }
            : item,
        );
      } else {
        newItems = [...state.items, { ...action.payload, quantity: 1 }];
      }

      return {
        items: newItems,
        total: calculateTotal(newItems),
      };
    }

    case 'REMOVE_ITEM': {
      const newItems = state.items.filter(
        (item) => item.id !== action.payload.id,
      );
      return {
        items: newItems,
        total: calculateTotal(newItems),
      };
    }

    case 'UPDATE_QUANTITY': {
      const newItems = state.items
        .map((item) =>
          item.id === action.payload.id
            ? { ...item, quantity: action.payload.quantity }
            : item,
        )
        .filter((item) => item.quantity > 0);

      return {
        items: newItems,
        total: calculateTotal(newItems),
      };
    }

    case 'CLEAR_CART':
      return { items: [], total: 0 };

    default:
      return state;
  }
}

function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// Context
interface CartContextValue {
  state: CartState;
  dispatch: Dispatch<CartAction>;
  addItem: (item: Omit<CartItem, 'quantity'>) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  itemCount: number;
}

const CartContext = createContext<CartContextValue | null>(null);

// Provider
export function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, { items: [], total: 0 });

  // Convenience actions
  const addItem = (item: Omit<CartItem, 'quantity'>) => {
    dispatch({ type: 'ADD_ITEM', payload: item });
  };

  const removeItem = (id: string) => {
    dispatch({ type: 'REMOVE_ITEM', payload: { id } });
  };

  const updateQuantity = (id: string, quantity: number) => {
    dispatch({ type: 'UPDATE_QUANTITY', payload: { id, quantity } });
  };

  const clearCart = () => {
    dispatch({ type: 'CLEAR_CART' });
  };

  const itemCount = state.items.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <CartContext.Provider
      value={{
        state,
        dispatch,
        addItem,
        removeItem,
        updateQuantity,
        clearCart,
        itemCount,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

// Hook
export function useCart(): CartContextValue {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
}

// Usage
function AddToCartButton({ product }: { product: Product }) {
  const { addItem } = useCart();

  return (
    <button onClick={() => addItem(product)}>
      Add to Cart
    </button>
  );
}

function CartBadge() {
  const { itemCount } = useCart();
  return <span className="badge">{itemCount}</span>;
}
```

### Split Context for Performance

```typescript
// contexts/user-context.tsx
'use client';

import {
  createContext,
  useContext,
  useState,
  useCallback,
  type ReactNode,
} from 'react';

interface User {
  id: string;
  name: string;
  email: string;
  avatar: string;
}

// Split into separate contexts
const UserStateContext = createContext<User | null>(null);
const UserActionsContext = createContext<{
  login: (user: User) => void;
  logout: () => void;
  updateUser: (updates: Partial<User>) => void;
} | null>(null);

export function UserProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = useCallback((userData: User) => {
    setUser(userData);
  }, []);

  const logout = useCallback(() => {
    setUser(null);
  }, []);

  const updateUser = useCallback((updates: Partial<User>) => {
    setUser((current) => (current ? { ...current, ...updates } : null));
  }, []);

  // Actions are stable (memoized callbacks)
  const actions = { login, logout, updateUser };

  return (
    <UserStateContext.Provider value={user}>
      <UserActionsContext.Provider value={actions}>
        {children}
      </UserActionsContext.Provider>
    </UserStateContext.Provider>
  );
}

// Separate hooks - components can subscribe to only what they need
export function useUser(): User | null {
  return useContext(UserStateContext);
}

export function useUserActions() {
  const context = useContext(UserActionsContext);
  if (!context) {
    throw new Error('useUserActions must be used within a UserProvider');
  }
  return context;
}

// Usage - This component only re-renders when user changes
function UserAvatar() {
  const user = useUser();
  if (!user) return null;
  return <img src={user.avatar} alt={user.name} />;
}

// Usage - This component never re-renders from user changes
function LogoutButton() {
  const { logout } = useUserActions(); // Actions are stable
  return <button onClick={logout}>Logout</button>;
}
```

### Context with Persistence

```typescript
// contexts/settings-context.tsx
'use client';

import {
  createContext,
  useContext,
  useState,
  useEffect,
  type ReactNode,
} from 'react';

interface Settings {
  notifications: boolean;
  language: string;
  timezone: string;
}

const defaultSettings: Settings = {
  notifications: true,
  language: 'en',
  timezone: 'UTC',
};

interface SettingsContextValue {
  settings: Settings;
  updateSettings: (updates: Partial<Settings>) => void;
  resetSettings: () => void;
}

const SettingsContext = createContext<SettingsContextValue | null>(null);

const STORAGE_KEY = 'app-settings';

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<Settings>(defaultSettings);
  const [isLoaded, setIsLoaded] = useState(false);

  // Load from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        setSettings({ ...defaultSettings, ...JSON.parse(stored) });
      } catch (e) {
        console.error('Failed to parse settings:', e);
      }
    }
    setIsLoaded(true);
  }, []);

  // Persist to localStorage on change
  useEffect(() => {
    if (isLoaded) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
    }
  }, [settings, isLoaded]);

  const updateSettings = (updates: Partial<Settings>) => {
    setSettings((current) => ({ ...current, ...updates }));
  };

  const resetSettings = () => {
    setSettings(defaultSettings);
    localStorage.removeItem(STORAGE_KEY);
  };

  // Don't render until loaded to prevent flash
  if (!isLoaded) {
    return null; // Or a loading spinner
  }

  return (
    <SettingsContext.Provider
      value={{ settings, updateSettings, resetSettings }}
    >
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings(): SettingsContextValue {
  const context = useContext(SettingsContext);
  if (!context) {
    throw new Error('useSettings must be used within a SettingsProvider');
  }
  return context;
}
```

### Composing Multiple Providers

```typescript
// contexts/app-providers.tsx
'use client';

import { type ReactNode } from 'react';
import { ThemeProvider } from './theme-context';
import { UserProvider } from './user-context';
import { CartProvider } from './cart-context';
import { SettingsProvider } from './settings-context';

interface AppProvidersProps {
  children: ReactNode;
}

export function AppProviders({ children }: AppProvidersProps) {
  return (
    <ThemeProvider>
      <SettingsProvider>
        <UserProvider>
          <CartProvider>
            {children}
          </CartProvider>
        </UserProvider>
      </SettingsProvider>
    </ThemeProvider>
  );
}

// Usage in layout.tsx
// app/layout.tsx
import { AppProviders } from '@/contexts/app-providers';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  );
}
```

## When to Use

- Theme, language, authentication state
- Shopping cart, form state across routes
- Feature flags, configuration
- Any data needed by many components at different levels

## Anti-patterns

```typescript
// BAD: No custom hook, direct context usage
const context = useContext(MyContext);
if (!context) throw new Error('...'); // Repeated everywhere

// BAD: Everything in one context
const AppContext = createContext({
  user: null,
  theme: 'light',
  cart: [],
  notifications: [],
  settings: {},
  // Everything re-renders when anything changes
});

// BAD: Unstable values in provider
function Provider({ children }) {
  const value = { // New object every render!
    doSomething: () => {}, // New function every render!
  };
  return <Context.Provider value={value}>{children}</Context.Provider>;
}

// BAD: Using context for frequently updating values
function MousePositionProvider({ children }) {
  const [position, setPosition] = useState({ x: 0, y: 0 });
  // Updates 60+ times per second - all consumers re-render
}
```

```typescript
// GOOD: Custom hook with error handling
export function useMyContext() {
  const context = useContext(MyContext);
  if (!context) {
    throw new Error('useMyContext must be used within MyProvider');
  }
  return context;
}

// GOOD: Split contexts by update frequency
const UserStateContext = createContext(null); // Changes rarely
const UserActionsContext = createContext(null); // Never changes

// GOOD: Memoize provider values
function Provider({ children }) {
  const [state, dispatch] = useReducer(reducer, initial);
  const actions = useMemo(() => ({ dispatch }), []);

  return (
    <StateContext.Provider value={state}>
      <ActionsContext.Provider value={actions}>
        {children}
      </ActionsContext.Provider>
    </StateContext.Provider>
  );
}

// GOOD: Use refs or external stores for frequent updates
const mousePosition = useRef({ x: 0, y: 0 });
```

## Related Patterns

- React Hooks Pattern - Custom hooks for context access
- Dependency Injection Pattern - Similar concept, different implementation
- React Component Pattern - Components that use context
