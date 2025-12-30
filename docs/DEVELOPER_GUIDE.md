# Silni App - Developer Onboarding and Contribution Guide

## Overview

This comprehensive guide helps new developers get started with Silni app development and provides guidelines for contributing to the project. It covers setup, development workflow, coding standards, and contribution processes.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Environment Setup](#development-environment-setup)
3. [Project Structure](#project-structure)
4. [Development Workflow](#development-workflow)
5. [Coding Standards](#coding-standards)
6. [Testing Guidelines](#testing-guidelines)
7. [Git Workflow](#git-workflow)
8. [Code Review Process](#code-review-process)
9. [Debugging Guide](#debugging-guide)
10. [Performance Guidelines](#performance-guidelines)
11. [Feature Implementation Guides](#feature-implementation-guides)
12. [Security Best Practices](#security-best-practices)
13. [Contribution Types](#contribution-types)

---

## Getting Started

### Prerequisites

Before starting development, ensure you have:

- **Flutter SDK**: 3.10.1 or later
- **Dart SDK**: 3.10.1 or later (included with Flutter)
- **Git**: Version 2.30.0 or later
- **IDE**: VS Code with Flutter extension or Android Studio
- **Device**: iOS Simulator, Android Emulator, or physical device

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-org/silni_app.git
cd silni_app

# 2. Install Flutter dependencies
flutter pub get

# 3. Generate code
flutter pub run build_runner build

# 4. Copy environment file
cp .env.example .env

# 5. Edit environment variables
nano .env

# 6. Run the app
flutter run
```

### Verification

```bash
# Check Flutter installation
flutter doctor -v

# Verify connected devices
flutter devices

# Run tests to verify setup
flutter test
```

---

## Development Environment Setup

### IDE Configuration

#### VS Code Setup

1. **Install Extensions**:
   - Flutter
   - Dart
   - GitLens
   - Flutter Tree
   - Bracket Pair Colorizer

2. **Configure Settings**:
   ```json
   {
     "dart.flutterSdkPath": "/path/to/flutter",
     "editor.formatOnSave": true,
     "editor.codeActionsOnSave": {
       "source.fixAll": true
     },
     "files.associations": {
       "*.dart": "dart"
     }
   }
   ```

3. **Debug Configuration**:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Silni App",
         "type": "dart",
         "request": "launch",
         "program": "lib/main.dart"
       }
     ]
   }
   ```

#### Android Studio Setup

1. **Install Plugins**:
   - Flutter
   - Dart
   - .env files support

2. **Configure SDK**:
   - Open Preferences → Languages & Frameworks → Flutter
   - Set Flutter SDK path

3. **Run Configuration**:
   - Run → Edit Configurations
   - Add Flutter configuration
   - Set main.dart as entry point

### Environment Configuration

#### Development Environment Variables

Create `.env` file in project root:

```bash
# Development Configuration
APP_ENV=development
ENVIRONMENT=development

# Supabase Development
SUPABASE_STAGING_URL=http://localhost:54321
SUPABASE_STAGING_ANON_KEY=your_local_anon_key

# Firebase Development
FIREBASE_PROJECT_ID=silni-dev
FCM_SERVER_KEY=your_dev_fcm_key

# Sentry Development
SENTRY_DSN=your_dev_sentry_dsn

# Development Flags
ENABLE_LOGGER=true
ENABLE_DEBUG_MODE=true
ENABLE_ANALYTICS=false
```

#### Environment Validation

```bash
# Validate environment setup
flutter pub run build_runner build

# Check for missing variables
flutter pub run envied:generate
```

---

## Project Structure

### Directory Overview

```
silni_app/
├── lib/                          # Main source code
│   ├── main.dart                 # App entry point
│   ├── core/                     # Core functionality
│   │   ├── ai/                  # AI services
│   │   ├── cache/                # Local storage
│   │   ├── config/               # App configuration
│   │   ├── constants/            # App constants
│   │   ├── errors/               # Error handling
│   │   ├── extensions/            # Dart extensions
│   │   ├── models/               # Core models
│   │   ├── providers/            # Global providers
│   │   ├── router/               # Navigation
│   │   ├── services/             # Core services
│   │   ├── theme/                # Theming
│   │   └── utils/                # Utilities
│   ├── features/                 # Feature modules
│   │   ├── ai_assistant/         # AI features
│   │   ├── auth/                 # Authentication
│   │   ├── family_tree/          # Family tree
│   │   ├── gamification/         # Gamification
│   │   ├── home/                 # Home screen
│   │   ├── notifications/         # Notifications
│   │   ├── profile/              # User profile
│   │   ├── relatives/            # Family members
│   │   ├── reminders/            # Reminders
│   │   ├── settings/             # Settings
│   │   └── statistics/           # Analytics
│   └── shared/                   # Shared components
│       ├── models/               # Shared models
│       ├── providers/            # Shared providers
│       ├── repositories/         # Data repositories
│       ├── services/             # Shared services
│       ├── utils/                # UI helpers
│       └── widgets/              # Reusable widgets
├── assets/                       # App assets
│   ├── animations/              # Animation files
│   ├── fonts/                   # Custom fonts
│   └── images/                  # Images and icons
├── test/                         # Unit tests
├── integration_test/              # Integration tests
├── docs/                         # Documentation
├── scripts/                      # Build and deployment scripts
└── .env.example                  # Environment template
```

### Feature Module Structure

Each feature follows this consistent structure:

```
feature_name/
├── providers/                     # Riverpod providers
│   ├── feature_provider.dart
│   └── feature_state.dart
├── screens/                       # UI screens
│   ├── feature_screen.dart
│   └── feature_detail_screen.dart
├── widgets/                       # Feature-specific widgets
│   ├── feature_widget.dart
│   └── feature_card.dart
└── services/                      # Feature-specific services
    └── feature_service.dart
```

---

## Development Workflow

### Daily Development Workflow

#### 1. Start Development

```bash
# Pull latest changes
git pull origin main

# Create feature branch
git checkout -b feature/new-feature

# Start local services
supabase start

# Run app with hot reload
flutter run
```

#### 2. Development Process

1. **Make Changes**: Implement feature or fix
2. **Run Tests**: Ensure all tests pass
3. **Code Generation**: Update generated files
4. **Local Testing**: Test on device/emulator
5. **Commit Changes**: Commit with descriptive message

#### 3. End Development

```bash
# Stage changes
git add .

# Commit changes
git commit -m "feat: add new feature description"

# Push to remote
git push origin feature/new-feature

# Create pull request
# (through GitHub/GitLab interface)
```

### Code Generation Workflow

#### When to Run Code Generation

```bash
# After adding new models
flutter pub run build_runner build

# After updating environment variables
flutter pub run build_runner build

# After adding new providers
flutter pub run build_runner build

# Watch for changes during development
flutter pub run build_runner watch
```

#### Common Code Generation Commands

```bash
# Build all generators
flutter pub run build_runner build

# Build with delete conflicting outputs
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes
flutter pub run build_runner watch
```

---

## Coding Standards

### Dart/Flutter Guidelines

#### Code Style

```dart
// Use camelCase for variables and functions
String userName = 'Ahmed';
void calculateAge() { }

// Use PascalCase for classes and types
class UserProfile { }
enum RelationshipType { }

// Use UPPER_CASE for constants
const String API_BASE_URL = 'https://api.silni.app';
final int MAX_RETRY_ATTEMPTS = 3;

// Use prefix_ for private members
class UserService {
  String _privateField;
  void _privateMethod() { }
}
```

#### File Organization

```dart
// File header
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// External imports first
import 'package:supabase_flutter/supabase_flutter.dart';

// Internal imports next
import '../models/user_model.dart';
import '../services/auth_service.dart';

// Relative imports last
import 'user_widget.dart';
import 'user_provider.dart';

// Class definition
class UserService {
  // Static constants
  static const String baseUrl = 'https://api.silni.app';
  
  // Private fields
  final SupabaseClient _client;
  
  // Constructor
  UserService(this._client);
  
  // Public methods
  Future<User> getUser(String id) async {
    // Implementation
  }
  
  // Private methods
  Future<void> _logError(String error) async {
    // Implementation
  }
}
```

#### Documentation Standards

```dart
/// Service for managing user operations
/// 
/// This service handles user authentication, profile management,
/// and user data synchronization with the backend.
/// 
/// Example:
/// ```dart
/// final userService = UserService();
/// final user = await userService.getUser('user-id');
/// ```
class UserService {
  /// Creates a new user with the provided email and password
  /// 
  /// [email] User's email address
  /// [password] User's password (min 8 characters)
  /// 
  /// Returns [User] object on success
  /// Throws [AuthenticationError] on failure
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await userService.createUser(
  ///     'user@example.com',
  ///     'password123',
  ///   );
  /// } catch (e) {
  ///   print('Authentication failed: $e');
  /// }
  /// ```
  Future<User> createUser(String email, String password) async {
    // Implementation
  }
}
```

### Flutter Widget Guidelines

#### Widget Structure

```dart
class UserProfileWidget extends ConsumerWidget {
  const UserProfileWidget({
    super.key,
    required this.userId,
    this.onEdit,
  });

  final String userId;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    
    return userAsync.when(
      data: (user) => _buildContent(context, user),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => _buildError(context, error),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    return Column(
      children: [
        _buildHeader(user),
        _buildDetails(user),
        if (onEdit != null) _buildEditButton(context),
      ],
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return ErrorWidget(
      error: error,
      onRetry: () => ref.refresh(userProvider(userId)),
    );
  }
}
```

#### State Management Patterns

```dart
// Provider definition
final userProvider = StreamProvider.family<User, String>((ref, userId) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserStream(userId);
});

// Provider usage
class UserProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    
    return userAsync.when(
      data: (user) => UserProfileContent(user: user),
      loading: () => const LoadingWidget(),
      error: (error, stack) => ErrorWidget(error: error),
    );
  }
}
```

---

## Testing Guidelines

### Testing Pyramid

```
    /\
   /  \
  /______\     E2E Tests (10%)
 /          \
/_____________\ Integration Tests (20%)
/______________\ Unit Tests (70%)
```

### Unit Testing

#### Test Structure

```dart
// test/services/user_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silni_app/services/user_service.dart';

void main() {
  group('UserService', () {
    late UserService userService;
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = MockSupabaseClient();
      userService = UserService(mockClient);
    });

    tearDown(() {
      mockClient.close();
    });

    group('createUser', () {
      test('should create user successfully', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        final expectedUser = User(
          id: 'test-id',
          email: email,
        );
        
        when(() => mockClient.from('users').insert(any()))
          .thenAnswer((_) async => {'id': 'test-id'});

        // Act
        final result = await userService.createUser(email, password);

        // Assert
        expect(result, equals(expectedUser));
        verify(() => mockClient.from('users').insert(any())).called(1);
      });

      test('should throw AuthenticationError for invalid email', () async {
        // Arrange
        const email = 'invalid-email';
        const password = 'password123';
        
        when(() => mockClient.from('users').insert(any()))
          .thenThrow(AuthenticationError('Invalid email'));

        // Act & Assert
        expect(
          () => userService.createUser(email, password),
          throwsA(isA<AuthenticationError>()),
        );
      });
    });
  });
}
```

#### Mocking Guidelines

```dart
// test/mocks/mock_supabase_client.dart
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {
  void close() {
    // Cleanup resources
  }
}

// Test setup
void setUpMockSupabase() {
  // Reset all mocks
  reset(MockSupabaseClient);
}
```

### Widget Testing

```dart
// test/widgets/user_profile_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silni_app/widgets/user_profile_widget.dart';

void main() {
  group('UserProfileWidget', () {
    testWidgets('should display user information', (tester) async {
      // Arrange
      const user = User(
        id: 'test-id',
        email: 'test@example.com',
        fullName: 'Test User',
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: UserProfileWidget(userId: user.id),
          ),
        ),
      );

      // Assert
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should call onEdit when edit button tapped', (tester) async {
      // Arrange
      bool editCalled = false;
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: UserProfileWidget(
              userId: 'test-id',
              onEdit: () => editCalled = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byKey(const Key('edit_button')));
      await tester.pump();

      // Assert
      expect(editCalled, isTrue);
    });
  });
}
```

### Integration Testing

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:silni_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Silni App E2E Tests', () {
    testWidgets('complete user authentication flow', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - Navigate to login
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Act - Enter credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.pumpAndSettle();

      // Act - Submit form
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // Assert - Verify home screen
      expect(find.byKey(const Key('home_screen')), findsOneWidget);
    });
  });
}
```

---

## Git Workflow

### Branch Strategy

```
main (production)
├── develop (staging)
├── feature/user-authentication
├── feature/family-tree
├── hotfix/critical-bug-fix
└── release/v1.2.0
```

### Branch Types

#### Main Branch
- **Purpose**: Production-ready code
- **Protection**: Direct commits not allowed
- **Merging**: Only from develop and release branches

#### Develop Branch
- **Purpose**: Integration branch for features
- **Protection**: Direct commits discouraged
- **Merging**: From feature branches

#### Feature Branches
- **Purpose**: New feature development
- **Naming**: `feature/description-of-feature`
- **Lifespan**: Temporary, merged to develop

#### Release Branches
- **Purpose**: Prepare for production release
- **Naming**: `release/vX.Y.Z`
- **Merging**: From develop to main

#### Hotfix Branches
- **Purpose**: Critical fixes for production
- **Naming**: `hotfix/description-of-fix`
- **Merging**: From main to develop and main

### Commit Message Standards

#### Conventional Commits

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes

#### Examples

```bash
feat(auth): add biometric authentication

Implement fingerprint and face ID authentication
for enhanced security and user convenience.

Closes #123
```

```bash
fix(relatives): resolve crash on relative deletion

Fix null pointer exception when deleting relative
with no interactions. Added null check before
accessing interaction list.

Fixes #456
```

### Pull Request Process

#### PR Template

```markdown
## Description
Brief description of changes and their purpose.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Cross-platform testing (iOS/Android/Web)

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Environment variables documented (if needed)
- [ ] Performance impact considered
- [ ] Security implications considered

## Screenshots/Videos
(If applicable, add screenshots or videos)

## Related Issues
Closes #123, #456
```

#### PR Review Process

1. **Self-Review**: Review your own changes
2. **Automated Checks**: CI/CD pipeline validation
3. **Peer Review**: At least one team member review
4. **Testing**: Verify tests pass on all platforms
5. **Approval**: Get approval from maintainer
6. **Merge**: Merge to target branch

---

## Code Review Process

### Review Guidelines

#### What to Look For

1. **Functionality**: Does the code work as intended?
2. **Performance**: Is the code efficient?
3. **Security**: Are there security vulnerabilities?
4. **Maintainability**: Is the code readable and maintainable?
5. **Testing**: Are tests comprehensive?
6. **Documentation**: Is the code well documented?

#### Review Checklist

```markdown
### Code Quality
- [ ] Code follows style guidelines
- [ ] No hardcoded values
- [ ] Proper error handling
- [ ] Memory leaks avoided
- [ ] Performance optimized

### Security
- [ ] Input validation implemented
- [ ] No sensitive data exposed
- [ ] Authentication/authorization correct
- [ ] SQL injection prevented

### Testing
- [ ] Unit tests cover new code
- [ ] Integration tests included
- [ ] Edge cases considered
- [ ] Manual testing completed

### Documentation
- [ ] Code comments added where needed
- [ ] API documentation updated
- [ ] README updated (if needed)
- [ ] Commit messages clear
```

### Review Process

#### 1. Automated Review

```yaml
# .github/workflows/pr_checks.yml
name: PR Checks

on:
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
      - name: Install dependencies
        run: flutter pub get
      - name: Run tests
        run: flutter test
      - name: Run integration tests
        run: flutter test integration_test/
      - name: Analyze code
        run: flutter analyze
```

#### 2. Manual Review

1. **Initial Review**: Quick scan for obvious issues
2. **Detailed Review**: Line-by-line examination
3. **Testing**: Verify functionality manually
4. **Discussion**: Address questions and concerns
5. **Approval**: Approve or request changes

---

## Debugging Guide

### Debugging Tools

#### Flutter Inspector

```bash
# Run app with debugging
flutter run --debug

# Open Flutter Inspector in VS Code
# View: Command Palette → Flutter: Open Flutter Inspector
```

#### Logging

```dart
// Using built-in logging
import 'package:logging/logging.dart';

final _logger = Logger('UserService');

class UserService {
  Future<User> getUser(String id) async {
    _logger.info('Getting user: $id');
    
    try {
      final user = await _fetchUser(id);
      _logger.fine('User retrieved successfully: ${user.id}');
      return user;
    } catch (e, stackTrace) {
      _logger.severe('Failed to get user: $e', e, stackTrace);
      rethrow;
    }
  }
}
```

#### Custom Debugging

```dart
// lib/core/utils/debug_helper.dart
class DebugHelper {
  static void log(String message, {String? tag, Object? data}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final tagStr = tag != null ? '[$tag] ' : '';
      final dataStr = data != null ? ' Data: $data' : '';
      
      print('$timestamp $tagStr$message$dataStr');
    }
  }
  
  static void assertCondition(
    bool condition,
    String message, {
    String? tag,
    Object? data,
  }) {
    if (!condition) {
      log('ASSERTION FAILED: $message', tag: tag, data: data);
      if (kDebugMode) {
        throw AssertionError(message);
      }
    }
  }
}
```

### Common Debugging Scenarios

#### State Management Issues

```dart
// Debug provider state
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final notifier = UserNotifier();
  
  // Debug state changes
  ref.listen(userProvider, (previous, next) {
    DebugHelper.log(
      'User state changed',
      tag: 'UserProvider',
      data: {
        'previous': previous.toString(),
        'next': next.toString(),
      },
    );
  });
  
  return notifier;
});
```

#### Network Issues

```dart
// Debug network requests
class ApiService {
  static Future<Map<String, dynamic>> makeRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    DebugHelper.log(
      'Making API request',
      tag: 'ApiService',
      data: {
        'endpoint': endpoint,
        'data': data,
      },
    );
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      
      DebugHelper.log(
        'API request completed',
        tag: 'ApiService',
        data: {
          'endpoint': endpoint,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'status_code': response.statusCode,
        },
      );
      
      return json.decode(response.body);
    } catch (e) {
      stopwatch.stop();
      
      DebugHelper.log(
        'API request failed',
        tag: 'ApiService',
        data: {
          'endpoint': endpoint,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
        },
      );
      
      rethrow;
    }
  }
}
```

---

## Performance Guidelines

### Performance Best Practices

#### Widget Performance

```dart
// Use const constructors where possible
class MyWidget extends StatelessWidget {
  const MyWidget({super.key}); // Good
  
  // Avoid expensive operations in build
  @override
  Widget build(BuildContext context) {
    return const Text('Hello'); // Good - const
    // return Text(DateTime.now().toString()); // Bad - changes every build
  }
}

// Use RepaintBoundary for expensive widgets
class ExpensiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ExpensivePainter(),
      ),
    );
  }
}
```

#### List Performance

```dart
// Use ListView.builder for long lists
class UserListWidget extends StatelessWidget {
  final List<User> users;
  
  const UserListWidget({super.key, required this.users});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return UserTile(user: users[index]);
      },
    );
    // Good: Efficient for long lists
    
    // Bad: Column(children: users.map((u) => UserTile(user: u)).toList())
    // Bad: Creates all widgets at once
  }
}
```

#### Image Performance

```dart
// Use cached images
class UserAvatar extends StatelessWidget {
  final String imageUrl;
  
  const UserAvatar({super.key, required this.imageUrl});
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      memCacheWidth: 100,
      memCacheHeight: 100,
    );
  }
}
```

### Performance Monitoring

```dart
// Track performance metrics
class PerformanceTracker {
  static void trackWidgetBuild(String widgetName) {
    final stopwatch = Stopwatch()..start();
    
    return () {
      stopwatch.stop();
      
      if (stopwatch.elapsedMilliseconds > 16) { // > 60fps
        DebugHelper.log(
          'Slow widget build detected',
          tag: 'Performance',
          data: {
            'widget': widgetName,
            'duration_ms': stopwatch.elapsedMilliseconds,
          },
        );
      }
    };
  }
  
  static void trackAsyncOperation(
    String operationName,
    Future<void> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await operation();
      stopwatch.stop();
      
      DebugHelper.log(
        'Async operation completed',
        tag: 'Performance',
        data: {
          'operation': operationName,
          'duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
    } catch (e) {
      stopwatch.stop();
      
      DebugHelper.log(
        'Async operation failed',
        tag: 'Performance',
        data: {
          'operation': operationName,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
        },
      );
      
      rethrow;
    }
  }
}
```

---

## Feature Implementation Guides

### Subscription System

#### Overview

Silni uses RevenueCat for subscription management with a two-tier model (Free and MAX).

#### Environment Setup

Add these environment variables:

```bash
# RevenueCat Configuration
REVENUECAT_APPLE_API_KEY=your_apple_api_key
REVENUECAT_GOOGLE_API_KEY=your_google_api_key
```

#### Using Subscription Providers

```dart
import 'package:silni_app/core/providers/subscription_provider.dart';
import 'package:silni_app/core/models/subscription_tier.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user has MAX tier
    final isMax = ref.watch(isMaxProvider);

    // Check specific feature access
    final hasAIChat = ref.watch(featureAccessProvider(FeatureIds.aiChat));

    // Get current tier details
    final tier = ref.watch(subscriptionTierProvider);

    // Check trial status
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final daysRemaining = ref.watch(trialDaysRemainingProvider);

    // Get reminder limit
    final reminderLimit = ref.watch(reminderLimitProvider);

    return Column(
      children: [
        if (isTrialActive)
          Text('$daysRemaining أيام متبقية في الفترة التجريبية'),
        if (hasAIChat)
          AIChatWidget()
        else
          UpgradePrompt(),
      ],
    );
  }
}
```

#### Initializing Subscription Service

The subscription service is initialized in `main.dart`:

```dart
// Initialize RevenueCat after user authentication
await SubscriptionService.instance.initialize(userId: user.id);
```

### Feature Gating

#### Using FeatureGate Widget

The `FeatureGate` widget wraps features and shows locked UI when user doesn't have access:

```dart
import 'package:silni_app/shared/widgets/feature_gate.dart';

// Basic usage - replaces content with locked card
FeatureGate(
  featureId: FeatureIds.aiChat,
  child: AIChatWidget(),
  onLockedTap: () => context.push('/paywall'),
)

// With overlay blur (maintains visual continuity)
FeatureGate(
  featureId: FeatureIds.aiChat,
  child: AIChatWidget(),
  useOverlay: true,
  onLockedTap: () => context.push('/paywall'),
)

// With custom locked widget
FeatureGate(
  featureId: FeatureIds.messageComposer,
  child: MessageComposerWidget(),
  lockedWidget: CustomLockedCard(),
  onLockedTap: () => showPaywallSheet(context),
)
```

#### LockedBadge for Cards/Tiles

```dart
import 'package:silni_app/shared/widgets/feature_gate.dart';

// For cards and tiles
LockedBadge(
  onTap: () => context.push('/paywall'),
  child: FeatureCard(
    title: 'AI Analysis',
    icon: Icons.psychology,
  ),
)
```

#### PremiumIconBadge

```dart
// Small badge for icons/indicators
Row(
  children: [
    Text('Advanced Analytics'),
    const SizedBox(width: 8),
    const PremiumIconBadge(size: 16),
  ],
)
```

#### ConditionalFeatureGate

```dart
// Only gates when user doesn't have access
ConditionalFeatureGate(
  featureId: FeatureIds.unlimitedReminders,
  onLockedTap: () => context.push('/paywall'),
  child: CreateReminderButton(),
)
```

#### Available Feature IDs

```dart
class FeatureIds {
  // MAX-only AI features
  static const String aiChat = 'ai_chat';
  static const String messageComposer = 'message_composer';
  static const String communicationScripts = 'communication_scripts';
  static const String relationshipAnalysis = 'relationship_analysis';
  static const String smartRemindersAI = 'smart_reminders_ai';
  static const String weeklyReports = 'weekly_reports';

  // MAX-only other features
  static const String advancedAnalytics = 'advanced_analytics';
  static const String leaderboard = 'leaderboard';
  static const String dataExport = 'data_export';
  static const String unlimitedReminders = 'unlimited_reminders';

  // Free features (no gating needed)
  static const String customThemes = 'custom_themes';
  static const String familyTree = 'family_tree';
}
```

### Premium Onboarding

#### Triggering Onboarding

```dart
import 'package:silni_app/features/premium_onboarding/screens/premium_onboarding_screen.dart';
import 'package:silni_app/features/premium_onboarding/providers/onboarding_provider.dart';

// Check if onboarding should be shown
final shouldShow = ref.read(shouldShowOnboardingProvider);

if (shouldShow) {
  // Show the onboarding carousel
  await PremiumOnboardingScreen.show(context);
}
```

#### Onboarding Steps

The onboarding carousel showcases these MAX features in order:

1. **AI Counselor** - Personalized relationship advice
2. **Message Composer** - AI-generated messages
3. **Communication Scripts** - Pre-written conversation scripts
4. **Relationship Analysis** - AI-powered relationship insights
5. **Smart Reminders AI** - Intelligent reminder suggestions
6. **Weekly Reports** - Comprehensive activity summaries

#### State Management

```dart
// Access onboarding state
final state = ref.watch(onboardingProvider);

// Check progress
if (state.isCompleted) {
  // Onboarding finished
}

// Mark step as completed
ref.read(onboardingProvider.notifier).completeStep('ai_counselor');

// Skip entire showcase
ref.read(onboardingProvider.notifier).skipShowcase();
```

### Offline-First Patterns

#### Repository Pattern with Cache-First

```dart
// Example: RelativesRepository implementation pattern
class MyRepository {
  final CacheService _cache;
  final MyService _service;
  final ConnectivityService _connectivity;

  Stream<List<MyModel>> watchData(String userId) async* {
    // 1. Emit cached data immediately
    yield _cache.getData(userId);

    // 2. Sync if online and cache is stale
    if (_connectivity.isOnline && _cache.isStale(userId)) {
      await _syncData(userId);
      yield _cache.getData(userId);
    }

    // 3. Stream real-time updates
    await for (final data in _service.stream(userId)) {
      await _cache.putData(userId, data);
      yield data;
    }
  }
}
```

#### Using OfflineQueueService

```dart
import 'package:silni_app/core/services/offline_queue_service.dart';

// Enqueue operation for offline sync
await OfflineQueueService.instance.enqueue(
  OfflineOperation(
    type: OperationType.create,
    entityType: 'relative',
    entityId: uuid.v4(),
    data: relative.toJson(),
  ),
);

// Check pending operations
final pendingCount = OfflineQueueService.instance.getPendingCount();

// View dead-letter queue (failed operations)
final deadLetters = OfflineQueueService.instance.getDeadLetterOperations();

// Retry a failed operation
await OfflineQueueService.instance.retryDeadLetter(operationId);
```

#### Connectivity-Aware Operations

```dart
import 'package:silni_app/core/services/connectivity_service.dart';

// Check connectivity before remote calls
if (ConnectivityService.instance.isOnline) {
  await performRemoteOperation();
} else {
  // Queue for later
  await OfflineQueueService.instance.enqueue(operation);
}
```

### Pattern Animation Configuration

#### Using Pattern Animation Provider

```dart
import 'package:silni_app/core/providers/pattern_animation_provider.dart';

class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(patternAnimationProvider);
    final notifier = ref.read(patternAnimationProvider.notifier);

    return Column(
      children: [
        // Toggle individual effects
        SwitchListTile(
          title: Text('Rotation'),
          value: settings.rotationEnabled,
          onChanged: (_) => notifier.toggleRotation(),
        ),
        SwitchListTile(
          title: Text('Pulse'),
          value: settings.pulseEnabled,
          onChanged: (_) => notifier.togglePulse(),
        ),
        SwitchListTile(
          title: Text('Gyroscope'),
          value: settings.gyroscopeEnabled,
          onChanged: (_) => notifier.toggleGyroscope(),
        ),

        // Intensity slider
        Slider(
          value: settings.animationIntensity,
          onChanged: (v) => notifier.setIntensity(v),
        ),

        // Quick actions
        TextButton(
          onPressed: notifier.enableAll,
          child: Text('Enable All'),
        ),
        TextButton(
          onPressed: notifier.disableAll,
          child: Text('Disable All'),
        ),
      ],
    );
  }
}
```

#### Available Animation Effects

| Effect | Method | Default | Battery Impact |
|--------|--------|---------|----------------|
| Rotation | `toggleRotation()` | ON | Low |
| Pulse | `togglePulse()` | ON | Low |
| Parallax | `toggleParallax()` | ON | Low |
| Shimmer | `toggleShimmer()` | OFF | Medium |
| Touch Ripple | `toggleTouchRipple()` | ON | Low |
| Gyroscope | `toggleGyroscope()` | OFF | Medium |
| Follow Touch | `toggleFollowTouch()` | ON | Low |

---

## Security Best Practices

### Data Protection

#### Environment Variables

```dart
// Never hardcode sensitive data
class ApiService {
  // Bad: Hardcoded API key
  // static const String API_KEY = 'sk-1234567890';
  
  // Good: Use environment variables
  static const String API_KEY = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );
}
```

#### Input Validation

```dart
class ValidationService {
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email is required';
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) return 'Invalid email format';
    
    return null; // Valid
  }
  
  static String? validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Password must contain uppercase';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Password must contain lowercase';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Password must contain number';
    
    return null; // Valid
  }
}
```

#### Secure Storage

```dart
class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> storeToken(String token) async {
    await _storage.write(
      key: 'auth_token',
      value: token,
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
```

### API Security

#### Request Security

```dart
class SecureApiService {
  static final _client = Dio();
  
  static Future<Map<String, dynamic>> makeSecureRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.post(
        endpoint,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-API-Version': '1.0',
          },
          timeout: const Duration(seconds: 30),
          validateStatus: true,
        ),
      );
      
      // Validate response
      if (response.statusCode != 200) {
        throw ApiException('Request failed: ${response.statusCode}');
      }
      
      return response.data;
    } on DioException catch (e) {
      throw ApiException('Network error: $e');
    }
  }
}
```

---

## Contribution Types

### Code Contributions

#### Bug Fixes

1. **Identify Issue**: Find bug in issue tracker
2. **Create Branch**: `fix/bug-description`
3. **Implement Fix**: Write code to fix the bug
4. **Add Tests**: Ensure bug doesn't reoccur
5. **Submit PR**: Create pull request with fix

#### New Features

1. **Discuss Feature**: Create issue for discussion
2. **Get Approval**: Get approval from maintainers
3. **Create Branch**: `feature/feature-description`
4. **Implement Feature**: Write code for new feature
5. **Add Tests**: Comprehensive test coverage
6. **Update Docs**: Update documentation
7. **Submit PR**: Create pull request

#### Refactoring

1. **Identify Area**: Code that needs improvement
2. **Plan Changes**: Document refactoring plan
3. **Create Branch**: `refactor/area-description`
4. **Implement Changes**: Refactor code
5. **Ensure Tests**: All tests still pass
6. **Submit PR**: Create pull request

### Non-Code Contributions

#### Documentation

1. **Identify Need**: Find documentation gaps
2. **Create Branch**: `docs/documentation-update`
3. **Update Docs**: Improve documentation
4. **Submit PR**: Create pull request

#### Testing

1. **Improve Coverage**: Add missing tests
2. **Fix Flaky Tests**: Stabilize test suite
3. **Add E2E Tests**: Add end-to-end tests
4. **Submit PR**: Create pull request

#### Design

1. **UI/UX Improvements**: Suggest design improvements
2. **Create Mockups**: Design new screens/features
3. **Submit Issue**: Create issue with design proposals

### Community Contributions

#### Bug Reports

1. **Use Template**: Follow bug report template
2. **Provide Details**: Include steps to reproduce
3. **Add Screenshots**: Include relevant screenshots
4. **Submit Issue**: Create detailed issue report

#### Feature Requests

1. **Search Existing**: Check for duplicate requests
2. **Describe Use Case**: Explain why feature is needed
3. **Propose Solution**: Suggest implementation approach
4. **Submit Issue**: Create feature request issue

---

## Conclusion

This developer guide provides comprehensive information for contributing to Silni app. Following these guidelines ensures:

1. **Consistent Code**: Maintainable and readable codebase
2. **High Quality**: Thorough testing and review process
3. **Efficient Development**: Streamlined workflow and tools
4. **Security Focus**: Secure coding practices throughout
5. **Collaborative Environment**: Inclusive contribution process

### Getting Help

- **Documentation**: Check existing docs first
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Use GitHub Discussions for questions
- **Team**: Reach out to maintainers for guidance

### Contributing to Silni

By contributing to Silni, you're helping to:

- **Strengthen Family Bonds**: Build tools for family connection
- **Promote Islamic Values**: Support culturally relevant features
- **Improve User Experience**: Create delightful user experiences
- **Advance Technology**: Use modern development practices

Thank you for your interest in contributing to Silni!