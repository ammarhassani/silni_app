# Development Workflow

## Branch Strategy

| Branch | Environment | Purpose |
|--------|-------------|---------|
| `main` | Production | App Store releases - PROTECTED |
| `develop` | Staging | Integration testing |
| `feature/*` | Local | New features |
| `fix/*` | Local | Bug fixes |

## Daily Workflow

### 1. Start New Feature
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
```

### 2. Work & Commit
```bash
# Make changes...
git add .
git commit -m "Add feature description"
```

### 3. Push & Create PR to develop
```bash
git push -u origin feature/my-feature
# Create PR on GitHub: feature/my-feature → develop
```

### 4. After PR Merged to develop
```bash
git checkout develop
git pull origin develop
# Test with staging environment
./scripts/switch-env.sh staging
flutter run
```

### 5. Release to Production
```bash
# Create PR on GitHub: develop → main
# After merge:
git checkout main
git pull origin main
./scripts/switch-env.sh production
# Build for App Store
```

## Environment Switching

```bash
./scripts/switch-env.sh staging    # Development/testing
./scripts/switch-env.sh production # App Store builds
```

## Commit Message Format

```
type: short description

- Detail 1
- Detail 2
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

## Security Rules

1. NEVER commit `.env` files (they're gitignored)
2. NEVER push directly to `main`
3. ALWAYS test on `develop` before releasing
4. Keep API keys in environment files only
