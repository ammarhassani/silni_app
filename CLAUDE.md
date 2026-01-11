# Silni App - AI Assistant Guidelines

## Project Overview
Silni (صِلني) is a Flutter app for maintaining family relationships through interaction tracking, streaks, and AI-powered insights.

## Branch & Environment Strategy

### Branches
| Branch | Environment | Purpose |
|--------|-------------|---------|
| `main` | Production | App Store releases - DO NOT modify directly |
| `develop` | Staging | Integration testing, safe to modify |
| `feature/*` | Local | New features |
| `fix/*` | Local | Bug fixes |

### Supabase Environments
| Environment | Project ID | Purpose |
|-------------|------------|---------|
| Production | `bapwklwxmwhpucutyras` | Live App Store users |
| Staging | `dqqyhmydodjpqboykzow` | Development & testing |

## Critical Rules for AI Assistants

### DO NOT:
- Push directly to `main` branch
- Modify production environment variables without explicit permission
- Change `.env` to point to production unless building for App Store
- Run migrations directly on production database
- Commit API keys, secrets, or credentials

### ALWAYS:
- Work on `develop` branch or feature branches
- Use staging environment for testing
- Ask before any production-related changes
- Use `./scripts/switch-env.sh staging` for development
- Create PRs for merging to `main`

## Environment Switching

```bash
# For development (DEFAULT)
./scripts/switch-env.sh staging

# For App Store builds ONLY
./scripts/switch-env.sh production
```

## File Structure

```
lib/
├── core/           # Core services, config, theme
├── features/       # Feature modules (auth, home, relatives, etc.)
├── shared/         # Shared widgets, utils, services
supabase/
├── functions/      # Edge functions
├── migrations/     # Database migrations
silni-admin/        # Next.js admin dashboard
```

## Key Configuration Files

- `.env` - Current environment (gitignored)
- `.env.staging` - Staging config (gitignored)
- `.env.production` - Production config (gitignored)
- `lib/core/config/env/env.g.dart` - Generated env file

## Workflow for New Features

1. `git checkout develop`
2. `git checkout -b feature/feature-name`
3. Make changes
4. Test with staging environment
5. Push and create PR to `develop`
6. After testing on `develop`, create PR to `main`

## Database Migrations

- Test migrations on staging first: `supabase db push --project-ref dqqyhmydodjpqboykzow`
- Only apply to production after thorough testing
- Never run destructive migrations without backup

## When User Asks for Production Changes

If the user asks to:
- Deploy to production
- Build for App Store
- Modify production database

Always confirm:
1. Are you sure this is ready for production?
2. Has this been tested on staging?
3. Is the current branch `main`?
