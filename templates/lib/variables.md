# Template Variables Reference

> Documentation for all available template variables in the Jarvis CLAUDE.md system.
> Last updated: 2025

This document lists all template variables that can be used in project templates. Variables are replaced during CLAUDE.md generation based on project detection and user configuration.

## Variable Syntax

Variables use the Mustache-style double curly brace syntax:

```
{{VARIABLE_NAME}}
```

Variables are case-sensitive and should be UPPER_SNAKE_CASE.

## Core Variables

### Project Identification

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{PROJECT_NAME}}` | Project name from package.json, Cargo.toml, etc. | `my-awesome-app` |
| `{{PROJECT_VERSION}}` | Project version string | `1.0.0`, `0.1.0-beta` |
| `{{PROJECT_DESCRIPTION}}` | Project description | `A CLI tool for...` |
| `{{PROJECT_AUTHOR}}` | Primary author name | `John Doe` |
| `{{PROJECT_LICENSE}}` | License type | `MIT`, `Apache-2.0` |

### Framework & Language

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{FRAMEWORK}}` | Primary framework | `nextjs`, `express`, `fastapi` |
| `{{FRAMEWORK_VERSION}}` | Framework version | `14.0.0`, `4.18.0` |
| `{{LANGUAGE}}` | Primary language | `typescript`, `python`, `rust` |
| `{{LANGUAGE_VERSION}}` | Language version | `5.3`, `3.11`, `1.75` |

### Package Management

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{PACKAGE_MANAGER}}` | Package manager in use | `npm`, `pnpm`, `yarn`, `bun`, `uv`, `poetry` |
| `{{INSTALL_CMD}}` | Command to install dependencies | `pnpm install`, `uv sync` |
| `{{ADD_DEP_CMD}}` | Command to add a dependency | `pnpm add`, `uv add` |
| `{{ADD_DEV_DEP_CMD}}` | Command to add a dev dependency | `pnpm add -D`, `uv add --dev` |
| `{{UPDATE_CMD}}` | Command to update dependencies | `pnpm update`, `uv sync --upgrade` |
| `{{AUDIT_CMD}}` | Command to audit dependencies | `pnpm audit`, `pip-audit` |

### Build & Development

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{DEV_CMD}}` | Start development server | `pnpm dev`, `python manage.py runserver` |
| `{{BUILD_CMD}}` | Build for production | `pnpm build`, `cargo build --release` |
| `{{START_CMD}}` | Start production server | `pnpm start`, `gunicorn app:app` |
| `{{BUNDLER}}` | JavaScript/TypeScript bundler | `vite`, `webpack`, `esbuild`, `turbopack` |

### Testing

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{TEST_FRAMEWORK}}` | Testing framework | `vitest`, `jest`, `pytest`, `cargo test` |
| `{{TEST_CMD}}` | Run tests command | `pnpm test`, `pytest`, `cargo test` |
| `{{TEST_WATCH_CMD}}` | Run tests in watch mode | `pnpm test:watch`, `pytest-watch` |
| `{{TEST_COVERAGE_CMD}}` | Run tests with coverage | `pnpm test:coverage`, `pytest --cov` |
| `{{E2E_FRAMEWORK}}` | E2E testing framework | `playwright`, `cypress`, `detox` |
| `{{E2E_CMD}}` | Run E2E tests | `pnpm e2e`, `playwright test` |

### Code Quality

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{LINTER}}` | Linting tool | `eslint`, `biome`, `ruff`, `clippy` |
| `{{LINT_CMD}}` | Run linter | `pnpm lint`, `ruff check .` |
| `{{FORMATTER}}` | Code formatter | `prettier`, `biome`, `black`, `rustfmt` |
| `{{FORMAT_CMD}}` | Format code | `pnpm format`, `black .` |
| `{{TYPE_CHECKER}}` | Type checking tool | `tsc`, `mypy`, `pyright` |
| `{{TYPE_CHECK_CMD}}` | Run type checker | `pnpm typecheck`, `mypy .` |

## TypeScript-Specific Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{TS_VERSION}}` | TypeScript version | `5.3.0` |
| `{{TS_STRICT}}` | Strict mode enabled | `true`, `false` |
| `{{TS_TARGET}}` | Compilation target | `ES2022`, `ESNext` |
| `{{TS_MODULE}}` | Module system | `ESNext`, `CommonJS`, `NodeNext` |
| `{{TS_MODULE_RESOLUTION}}` | Module resolution | `Bundler`, `NodeNext` |
| `{{PATH_ALIASES}}` | Path alias configuration | `@/* -> src/*` |
| `{{TS_CHECK_CMD}}` | Type check command | `tsc --noEmit` |
| `{{TS_BUILD_CMD}}` | Build command | `tsc -b` |
| `{{TS_WATCH_CMD}}` | Watch mode command | `tsc -w` |
| `{{TS_GENERATE_CMD}}` | Type generation command | `prisma generate` |

## Python-Specific Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{PYTHON_VERSION}}` | Python version | `3.11`, `3.12` |
| `{{PYTHON_MIN_VERSION}}` | Minimum Python version | `3.10` |
| `{{ENV_MANAGER}}` | Virtual environment tool | `venv`, `virtualenv`, `conda`, `uv` |
| `{{CREATE_ENV_CMD}}` | Create venv command | `python -m venv .venv`, `uv venv` |
| `{{ACTIVATE_ENV_CMD}}` | Activate venv command | `source .venv/bin/activate` |
| `{{INSTALL_DEPS_CMD}}` | Install dependencies | `pip install -r requirements.txt` |
| `{{INSTALL_DEV_DEPS_CMD}}` | Install dev dependencies | `pip install -r requirements-dev.txt` |
| `{{UPDATE_DEPS_CMD}}` | Update dependencies | `pip install -U -r requirements.txt` |
| `{{RUN_CMD}}` | Run application | `python main.py`, `uvicorn app:app` |
| `{{TYPE_CHECKER_CONFIG}}` | Type checker config | `strict = true` |
| `{{LINTER_CONFIG}}` | Linter configuration | `line-length = 88` |
| `{{FORMATTER_CONFIG}}` | Formatter configuration | `line-length = 88` |
| `{{PROJECT_STRUCTURE}}` | Directory structure | Generated tree |
| `{{UPDATE_VULNERABLE_CMD}}` | Update vulnerable packages | `pip-audit --fix` |

## Next.js-Specific Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{NEXTJS_VERSION}}` | Next.js version | `14.0.0`, `15.0.0` |
| `{{REACT_VERSION}}` | React version | `18.2.0`, `19.0.0` |
| `{{ROUTER_TYPE}}` | Router type in use | `app`, `pages` |
| `{{DEFAULT_RENDERING}}` | Default rendering mode | `SSR`, `SSG`, `ISR`, `CSR` |
| `{{STYLING_SOLUTION}}` | CSS solution | `tailwind`, `css-modules`, `styled-components` |
| `{{TYPECHECK_CMD}}` | Type check command | `next lint && tsc --noEmit` |

## React Native-Specific Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{RN_VERSION}}` | React Native version | `0.73.0` |
| `{{EXPO_VERSION}}` | Expo SDK version | `50.0.0` |
| `{{NAVIGATION_LIBRARY}}` | Navigation library | `react-navigation`, `expo-router` |
| `{{STATE_LIBRARY}}` | State management | `zustand`, `redux-toolkit`, `react-query` |
| `{{STYLING_APPROACH}}` | Styling approach | `StyleSheet`, `nativewind`, `styled-components` |
| `{{IOS_CMD}}` | Run iOS simulator | `npx expo run:ios`, `npx react-native run-ios` |
| `{{ANDROID_CMD}}` | Run Android emulator | `npx expo run:android`, `npx react-native run-android` |

## Flutter-Specific Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{FLUTTER_VERSION}}` | Flutter SDK version | `3.16.0` |
| `{{DART_VERSION}}` | Dart version | `3.2.0` |
| `{{STATE_MANAGEMENT}}` | State management | `riverpod`, `bloc`, `provider`, `getx` |
| `{{FLUTTER_TEST_CMD}}` | Run tests | `flutter test` |
| `{{FLUTTER_BUILD_CMD}}` | Build command | `flutter build apk`, `flutter build ios` |
| `{{FLUTTER_RUN_CMD}}` | Run app | `flutter run` |
| `{{FLUTTER_ANALYZE_CMD}}` | Analyze code | `flutter analyze` |

## iOS-Specific Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{SWIFT_VERSION}}` | Swift version | `5.9`, `5.10` |
| `{{IOS_MIN_VERSION}}` | Minimum iOS version | `15.0`, `16.0` |
| `{{UI_FRAMEWORK}}` | UI framework | `SwiftUI`, `UIKit` |
| `{{DEPENDENCY_MANAGER}}` | Dependency manager | `spm`, `cocoapods`, `carthage` |
| `{{XCODE_VERSION}}` | Xcode version | `15.0`, `15.2` |
| `{{XCTEST_CMD}}` | Run tests | `xcodebuild test -scheme MyApp` |
| `{{BUILD_SCHEME}}` | Build scheme name | `MyApp`, `MyApp-Debug` |

## Backend API-Specific Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{API_FRAMEWORK}}` | API framework | `express`, `fastify`, `fastapi`, `actix-web` |
| `{{DATABASE}}` | Database type | `postgresql`, `mysql`, `mongodb`, `sqlite` |
| `{{ORM}}` | ORM/Query builder | `prisma`, `drizzle`, `sqlalchemy`, `diesel` |
| `{{AUTH_METHOD}}` | Authentication method | `jwt`, `session`, `oauth2` |
| `{{CACHE}}` | Caching solution | `redis`, `memcached`, `in-memory` |
| `{{QUEUE}}` | Queue system | `bullmq`, `celery`, `rabbitmq` |
| `{{DOCS_GENERATOR}}` | API docs generator | `swagger`, `openapi`, `redoc` |
| `{{MIGRATION_CMD}}` | Run migrations | `prisma migrate dev`, `alembic upgrade head` |
| `{{SEED_CMD}}` | Seed database | `prisma db seed`, `python seed.py` |

## Supabase-Specific Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{SUPABASE_VERSION}}` | Supabase version | `2.0.0` |
| `{{PROJECT_ID}}` | Supabase project ID | `abcdefghijkl` |
| `{{MIGRATION_NAME}}` | Migration name | `create_users_table` |

## Database Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{DATABASE_URL}}` | Database connection string | `postgresql://...` |
| `{{DATABASE_HOST}}` | Database host | `localhost`, `db.example.com` |
| `{{DATABASE_PORT}}` | Database port | `5432`, `3306`, `27017` |
| `{{DATABASE_NAME}}` | Database name | `myapp_dev` |

## System Variables

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{OVERRIDE_PARENT}}` | Override parent template | `true`, `false` |
| `{{TOKEN_BUDGET}}` | Token limit for this level | `800`, `1500`, `2000` |
| `{{GENERATED_DATE}}` | Template generation date | `2025-01-05` |
| `{{JARVIS_VERSION}}` | Jarvis system version | `1.0.0` |

## Conditional Variables

Some variables are conditional and only available when certain features are detected:

### Docker Variables (when Dockerfile/compose.yml present)

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{DOCKER_CMD}}` | Docker run command | `docker compose up` |
| `{{DOCKER_BUILD_CMD}}` | Docker build command | `docker build -t myapp .` |
| `{{DOCKER_DEV_CMD}}` | Docker dev command | `docker compose -f docker-compose.dev.yml up` |

### CI/CD Variables (when workflow files present)

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `{{CI_PLATFORM}}` | CI/CD platform | `github-actions`, `gitlab-ci`, `circleci` |
| `{{CI_BUILD_CMD}}` | CI build command | `npm run build` |
| `{{CI_TEST_CMD}}` | CI test command | `npm run test:ci` |

## Custom Variables

Projects can define custom variables in their `.jarvis/config.yaml`:

```yaml
variables:
  CUSTOM_VAR: "custom value"
  TEAM_NAME: "Engineering"
  DEPLOY_TARGET: "production"
```

These can then be used in templates as `{{CUSTOM_VAR}}`, `{{TEAM_NAME}}`, etc.

## Variable Resolution Order

Variables are resolved in the following order (later overrides earlier):

1. Default values from template
2. Auto-detected values from project files
3. User-defined values in `.jarvis/config.yaml`
4. Environment variables (prefixed with `JARVIS_`)
5. Command-line arguments during generation

## Missing Variables

When a variable cannot be resolved:

1. **Required variables**: Generation fails with an error
2. **Optional variables**: Empty string is substituted
3. **Variables with defaults**: Default value is used

To mark a variable as optional, use the syntax:

```
{{OPTIONAL_VAR|default_value}}
```

Example:
```
Test Framework: {{TEST_FRAMEWORK|vitest}}
```

## Best Practices

1. **Use semantic variable names**: `{{DATABASE}}` not `{{DB}}`
2. **Document custom variables**: Add them to project's `.jarvis/config.yaml`
3. **Provide sensible defaults**: Use the `|default` syntax
4. **Keep variables DRY**: Define once, reuse across templates
5. **Version your variables**: Track changes in variable definitions
