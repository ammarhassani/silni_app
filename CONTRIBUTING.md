# Development Workflow

## Database migration rules

Migrations live in `supabase/migrations/*.sql` and are applied in
filename order. They are the source of truth for the schema; the
`legacy/` directory is historical only and is not applied to fresh
deploys (see [DATABASE_AUDIT.md](DATABASE_AUDIT.md) for the full
inventory of issues we are working through).

- Every FK to `auth.users` or `public.users` MUST include an explicit
  `ON DELETE` clause:
  - `ON DELETE CASCADE` — dependent rows have no value without the user
    (relatives, interactions, reminders, streaks).
  - `ON DELETE SET NULL` — dependent rows are historical or audit
    records that should outlive the user (admin_audit_log, social
    invitation history).
  - `ON DELETE RESTRICT` or `NO ACTION` — only with explicit reasoning
    written into a comment above the constraint. The expected use case
    is "we want the application layer to clean this up first via an
    atomic RPC."
- Migrations are append-only. Don't edit existing migrations. Write a
  new one. The CI history is what's actually been applied to staging
  and prod; rewriting it desyncs us from reality.
- New migrations should use `CREATE TABLE IF NOT EXISTS`,
  `CREATE OR REPLACE FUNCTION`, `ADD COLUMN IF NOT EXISTS`, and
  similar idempotent forms wherever possible. They should be safe to
  run against any environment state.
- The CI job `migrations-fk-discipline` runs
  `scripts/check_migrations_for_missing_on_delete.sh` against any
  migration files added or changed in a PR. It's bounded to one bug
  class (the FK / ON DELETE gap that caused the delete-account
  incident); don't expand it into a general SQL linter without
  scoping that as its own task.

If you need to make a destructive schema change (drop column, drop
table, change FK target), write the migration in two halves:

1. First migration: add the new shape, copy data, but keep the old
   shape live.
2. Ship and verify in staging.
3. Second migration: drop the old shape.

This pattern is the only safe way to roll back without data loss if
the new shape has a bug.

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
