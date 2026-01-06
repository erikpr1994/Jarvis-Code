# Flutter Project Additions

> Inherits from: global-claude.md + CLAUDE.md.template
> Override: {{OVERRIDE_PARENT}} (set to true for complete override, false for merge)
> Token budget: ~800 tokens

This template extends the base CLAUDE.md with Flutter-specific patterns.

## Tech Stack Additions

```yaml
framework:
  - Flutter {{FLUTTER_VERSION}}
  - Dart {{DART_VERSION}}

platforms:
  - iOS
  - Android
  - {{ADDITIONAL_PLATFORMS}}  # web | macos | windows | linux

state_management:
  - {{STATE_SOLUTION}}  # riverpod | bloc | provider | getx

backend:
  - {{BACKEND_SOLUTION}}  # supabase | firebase | custom
```

## Project Structure

```
lib/
├── main.dart                # App entry point
├── app/
│   ├── app.dart             # MaterialApp configuration
│   └── router.dart          # Navigation setup
├── core/
│   ├── constants/           # App-wide constants
│   ├── extensions/          # Dart extensions
│   ├── theme/               # App theming
│   └── utils/               # Utility functions
├── features/                # Feature-first organization
│   ├── auth/
│   │   ├── data/            # Data sources, repositories
│   │   ├── domain/          # Entities, use cases
│   │   └── presentation/    # Screens, widgets, controllers
│   └── home/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── widgets/             # Reusable widgets
│   └── services/            # Shared services
└── l10n/                    # Localization files
```

## Key Patterns

### Widget Structure

```dart
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
```

### State Management (Riverpod)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class
@immutable
class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});

  final User? user;
  final bool isLoading;
  final String? error;

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authRepository) : super(const AuthState());

  final AuthRepository _authRepository;

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.signIn(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
```

### Navigation (go_router)

```dart
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
```

### Repository Pattern

```dart
abstract class AuthRepository {
  Future<User> signIn(String email, String password);
  Future<void> signOut();
  Stream<User?> authStateChanges();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<User> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Sign in failed');
    return User.fromSupabase(response.user!);
  }
}
```

### Error Handling

```dart
import 'package:fpdart/fpdart.dart';

typedef AsyncResult<T> = Future<Either<Failure, T>>;

abstract class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

// Usage in repository
AsyncResult<User> getUser(String id) async {
  try {
    final data = await _client.from('users').select().eq('id', id).single();
    return Right(User.fromJson(data));
  } on PostgrestException catch (e) {
    return Left(DatabaseFailure(e.message));
  } catch (e) {
    return Left(UnknownFailure(e.toString()));
  }
}
```

## Testing

### Widget Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('LoginScreen shows error on invalid credentials', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'invalid@email.com');
    await tester.enterText(find.byType(TextField).last, 'wrongpass');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
```

### Integration Testing

```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can complete login flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
```

## Common Commands

```bash
# Development
{{DEV_CMD}}

# Run on specific device
{{RUN_DEVICE_CMD}}

# Build APK
{{BUILD_APK_CMD}}

# Build iOS
{{BUILD_IOS_CMD}}

# Run tests
{{TEST_CMD}}

# Generate code (freezed, json_serializable)
{{CODEGEN_CMD}}

# Analyze code
{{ANALYZE_CMD}}
```

## DO NOT

- Use `setState` in complex widgets (use proper state management)
- Create deeply nested widget trees (extract widgets)
- Use `BuildContext` across async gaps
- Skip `const` constructors where possible
- Use `.then()` over `async/await` unnecessarily
- Forget to dispose controllers and streams
- Use hardcoded strings (use localization)
- Skip null safety assertions

## Performance Guidelines

- Use `const` constructors for immutable widgets
- Use `ListView.builder` for long lists
- Cache network images with `cached_network_image`
- Use `RepaintBoundary` for complex animations
- Avoid rebuilding entire widget trees
- Profile with Flutter DevTools

## File Conventions

| Pattern | Purpose |
|---------|---------|
| `*_screen.dart` | Full page widgets |
| `*_widget.dart` | Reusable components |
| `*_controller.dart` | Business logic |
| `*_repository.dart` | Data access layer |
| `*_model.dart` | Data models |
| `*_provider.dart` | State providers |
| `*_test.dart` | Test files |
