# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Invesvault** is an inventory management system consisting of two repositories:

1. **Invesvault API** (`E:/Proyectos/invesvault_api`) - REST API built with Express.js and Sequelize ORM for PostgreSQL
2. **Invesvault App** (`E:/Proyectos/Invesvault_App`) - Flutter mobile application for Android/iOS

The system provides warehouse stock tracking, product management, shopping lists, notifications, and stock change history.

---

# BACKEND (invesvault_api)

## Development Commands

```bash
# Start development server (uses nodemon)
npm run dev

# Start with explicit env file
npm run dev:env

# Run all tests (requires .env.test configured)
npm test

# Run specific test file
npm test -- auth.test.js

# Run tests with watch mode
npm run test:watch

# Run tests with coverage report
npm run test:coverage

# Initialize test database tables
npm run init-test-db

# Production start
npm start
```

## Environment Setup

Copy `.env.template` to `.env` and configure:

- `PORT` - Server port (default: 7860)
- `DATABASE_URL` - PostgreSQL connection string (Neon in production)
- `JWT_SECRET` - Secret for JWT signing
- `APP_API_KEY` - API key for `x-api-key` header validation
- `NODE_ENV` - development | production | test

For testing, copy `.env.test.example` to `.env.test` with separate database credentials.

## Architecture

### Layer Structure

```
src/
├── index.js              # Entry point, Express setup, routes mounting
├── config/
│   └── sequelize.js      # Database connection, SSL config for production
├── database/
│   └── models/           # Sequelize models with associations
├── api/
│   ├── controllers/      # HTTP request handlers (validation, calls services)
│   ├── routes/           # Route definitions
│   ├── middlewares/      # authMiddleware.js (JWT), apiKeyMiddleware.js
│   └── validators/       # Joi validation schemas
├── services/             # Business logic, database operations
└── utils/
    └── queryBuilder.js   # parseQueryParams, buildFindOptions, search helpers
```

### Key Patterns

**Controllers** handle HTTP concerns (status codes, headers) and delegate to services:
- Use `parseQueryParams(req.query, { allowedOrderFields: [...] })` for list endpoints
- Return `X-Total-Count` header for list responses
- Handle `SequelizeUniqueConstraintError` with 409 status

**Services** contain business logic and Sequelize queries:
- Import models from `../database/models/index.js` or individual files
- Use `buildFindOptions()` and `buildSearchCondition()` from queryBuilder for pagination/search
- Throw errors with descriptive messages; controllers map to HTTP status codes

**Models** use `src/database/models/index.js` for association setup:
- Models are imported there first, then associations defined
- Import models via `import { User, Warehouse } from '../database/models/index.js'`

### Security

- **API Key**: All `/api/*` routes require `x-api-key` header (timing-safe comparison)
- **JWT Auth**: Protected routes use `authenticate` middleware; tokens expire in 7 days with sliding renewal (new token returned in `X-Refreshed-Token` header)
- **CORS**: Hybrid mode allows native apps (no Origin) but blocks web origins
- **Passwords**: Hashed with bcrypt (10 rounds)

### Query Parameter Parsing

Controllers use `parseQueryParams()` from `src/utils/queryBuilder.js` to handle:
- `search` - case-insensitive search on specified columns
- `orderBy`/`orderDir` - sorting with whitelist validation
- `page`/`limit` - pagination (max 500)
- Date filtering: `date_from`, `date_to`
- Boolean filters: `is_read`, `is_low_stock`, `is_shared`, `is_auto`
- Foreign keys: `brand_id`, `store_id`

## Testing

Tests use Jest with Supertest for HTTP assertions:
- **Test database**: Separate Neon/Postgres database (drops and recreates tables per run)
- **Test utilities**: `tests/testUtils.js` provides `createTestUser()`, `createTestWarehouse()`, `generateToken()`, etc.
- **Setup**: `tests/setup.test.js` configures test environment, `tests/jest.setup.js` loads env vars
- Run `npm run init-test-db` if schema changes are needed

## Deployment

- **Hugging Face Space**: Automatic deployment via GitHub Actions (`.github/workflows/deploy-to-hf.yml`) on push to `main`
- **Container**: Uses `node:18-slim`, runs as UID 1000, port 7860
- **Production**: Database SSL enabled; `sequelize.sync()` skipped

## Database

PostgreSQL with Sequelize ORM. Key entities:
- User → Warehouse (owner), WarehouseUser (membership with roles: viewer/editor/admin)
- Warehouse → WarehouseProduct (stock), StockChange (history), ShoppingList, Notification
- Product → Brand, Store (last purchase location tracking)

Models define `onDelete: CASCADE` for ownership relationships; `SET NULL` for reference relationships.

---

# FRONTEND (Invesvault_App)

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode (Android emulator)
flutter run

# Run with specific API configuration
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7860/api/v1 --dart-define=APP_API_KEY=your_key

# Build APK
flutter build apk

# Build app bundle for Play Store
flutter build appbundle

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

## Environment Configuration

The app uses compile-time environment variables via `--dart-define`:

- `API_BASE_URL` - Backend API URL (default: `http://10.0.2.2:3000/api` for Android emulator)
- `APP_API_KEY` - API key for `x-api-key` header (required for production)
- `ENV_NAME` - Environment name (development, staging, production)

**Note**: `10.0.2.2` is the special IP for Android emulator to access host machine localhost.

## Architecture

The Flutter app follows **Clean Architecture** with BLoC pattern for state management.

### Layer Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # App widget with dependency injection
├── core/
│   ├── constants/
│   │   └── api_constants.dart   # API endpoints, base URL config
│   ├── models/
│   │   └── filter_params.dart   # Query parameter models
│   ├── network/
│   │   └── dio_client.dart      # Dio configuration, interceptors
│   ├── router/
│   │   └── app_router.dart      # Navigation, route generation
│   ├── services/
│   │   ├── storage_service.dart # Secure storage (token, user data)
│   │   └── notification_service.dart # Local notifications
│   ├── theme/
│   │   ├── app_theme.dart       # Material theme configuration
│   │   └── app_colors.dart      # Color palette
│   └── utils/
│       ├── error_messages.dart  # Error message mapping
│       └── validators.dart      # Form validators
├── data/
│   ├── datasources/             # Remote API calls (one per entity)
│   │   ├── auth_remote_datasource.dart
│   │   ├── warehouse_remote_datasource.dart
│   │   ├── product_remote_datasource.dart
│   │   └── ...
│   ├── models/                  # Data models with JSON serialization
│   │   ├── user_model.dart
│   │   ├── warehouse_model.dart
│   │   ├── product_model.dart
│   │   └── ...
│   └── repositories/            # Repository pattern wrappers
│       ├── auth_repository.dart
│       ├── warehouse_repository.dart
│       └── ...
└── presentation/
    ├── cubits/                  # BLoC pattern (Cubit + State)
    │   ├── auth/
    │   ├── warehouse/
    │   ├── product_list/
    │   └── ...
    ├── screens/                 # UI screens organized by feature
    │   ├── auth/
    │   ├── warehouses/
    │   ├── products/
    │   └── ...
    └── widgets/                 # Reusable UI components
```

### Key Patterns

**State Management (BLoC/Cubit)**:
- Each feature has a Cubit in `presentation/cubits/<feature>/`
- State classes extend `Equatable` for value equality
- Cubits emit states; UI listens via `BlocBuilder` or `BlocListener`
- Example: `AuthCubit` manages login/register/logout state

**Data Layer**:
- **Datasources**: Direct API calls using Dio, return raw JSON
- **Models**: Parse JSON with `fromJson()`/`toJson()` methods
- **Repositories**: Abstract data operations, used by Cubits

**Navigation**:
- Centralized in `core/router/app_router.dart`
- Uses `AppNavigator` singleton for programmatic navigation
- Routes: `/splash`, `/login`, `/register`, `/dashboard`, `/warehouses`, `/products`, etc.
- Shell routes (with bottom nav) use `AppShell` wrapper

**HTTP Client (Dio)**:
- Singleton pattern via `DioClient.getInstance()`
- Interceptors handle:
  - Adding JWT token from secure storage
  - Adding `x-api-key` header
  - Silent token refresh from `X-Refreshed-Token` response header
  - Logging in debug mode
  - Clearing storage on 401 errors

**Secure Storage**:
- `StorageService` uses `flutter_secure_storage`
- Stores: JWT token, user info (id, name, email, role), last active timestamp
- Session expires after 7 days of inactivity

### API Integration

The app communicates with the backend via REST API:

- **Base URL**: Configured via `API_BASE_URL` compile-time variable
- **Authentication**: JWT Bearer token + API key header
- **Token Refresh**: Automatic via `X-Refreshed-Token` header handling
- **Endpoints**: Defined in `core/constants/api_constants.dart`

### Key Dependencies

- **flutter_bloc**: State management (BLoC pattern)
- **dio**: HTTP client with interceptors
- **flutter_secure_storage**: Encrypted local storage for tokens
- **mobile_scanner**: Barcode scanning for products
- **flutter_local_notifications**: Local push notifications
- **google_fonts**: Typography
- **intl**: Internationalization and date formatting
- **cached_network_image**: Image caching

### Platform Support

- **Android**: Minimum SDK 21, uses encrypted shared preferences
- **iOS**: Standard secure storage
- **Web**: Supported (see `web/` directory)
- **Windows**: Supported (see `windows/` directory)

### Build Configuration

**Android**:
- Package: `com.example.invesvault_app`
- Min SDK: 21
- Icons configured in `pubspec.yaml` via `flutter_launcher_icons`

**Environment-specific builds**:
```bash
# Development (local API)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7860/api/v1

# Production (Hugging Face)
flutter run --dart-define=API_BASE_URL=https://angelpereirar-invesvault-api.hf.space/api/v1 --dart-define=APP_API_KEY=your_production_key
```

---

# API-APP Integration

## Authentication Flow

1. App sends login request with email/password
2. API returns JWT token + user data
3. App stores token in secure storage
4. Dio interceptor adds token to subsequent requests
5. API returns refreshed token in `X-Refreshed-Token` header
6. App silently updates stored token

## Entity Mapping

| Backend (Sequelize) | Frontend (Flutter) |
|---------------------|-------------------|
| User | UserModel |
| Warehouse | WarehouseModel |
| Product | ProductModel |
| WarehouseProduct | WarehouseProductModel |
| Brand | BrandModel |
| Store | StoreModel |
| ShoppingList | ShoppingListItemModel |
| StockChange | StockChangeModel |
| Notification | NotificationModel |

## Common Workflows

**Adding a new feature** (e.g., Reports):
1. Backend: Add model → migration → service → controller → route
2. Backend: Add tests in `tests/`
3. Frontend: Add datasource → model → repository → cubit → screen
4. Frontend: Add route in `app_router.dart`
5. Frontend: Add API constants

**Modifying an API endpoint**:
1. Update backend controller/service
2. Update tests
3. Update frontend datasource and model if response changed
4. Update cubit logic if needed

**Database schema changes**:
1. Modify Sequelize model in backend
2. Run `npm run init-test-db` to update test schema
3. Update Flutter model's `fromJson()` if field names/types changed
