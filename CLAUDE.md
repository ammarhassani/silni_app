# Silni App - AI Assistant Guidelines

## Project Overview
Silni (صِلني) is a Flutter app for maintaining family relationships through interaction tracking, streaks, and AI-powered insights.

## Environment Rules (CRITICAL)

### Production-Only Workflow
- **Always use production** for ALL development and testing
- `.env` should always have `APP_ENV=production`
- Deploy migrations and functions to production: `--project-ref bapwklwxmwhpucutyras`
- Test with real production data using test user accounts
- NO syncing between environments - production is the single source of truth

### Supabase Environments
| Environment | Project ID | Purpose |
|-------------|------------|---------|
| **Production** | `bapwklwxmwhpucutyras` | **USE THIS FOR EVERYTHING** |
| Staging | `dqqyhmydodjpqboykzow` | Emergency backup ONLY (Plan B) |

### Staging = Plan B (Emergency Only)
- Staging exists ONLY as emergency backup
- **DO NOT** use staging for normal development workflow
- **DO NOT** sync data between staging and production
- Only use staging if production has catastrophic failure (DB corruption, etc.)

### When to Use Staging (RARE)
- Production database corrupted and needs restore
- Testing destructive migration before production (very rare)
- NEVER for regular feature development

## Critical Rules for AI Assistants

### DO NOT:
- Use staging environment for development
- Sync data between staging and production
- Switch to staging unless explicitly asked for emergency recovery
- Commit API keys, secrets, or credentials

### ALWAYS:
- Use production environment (`APP_ENV=production`)
- Deploy to production: `supabase functions deploy --project-ref bapwklwxmwhpucutyras`
- Run migrations on production: `supabase db push --project-ref bapwklwxmwhpucutyras`
- Test using test user accounts on production

## Environment Commands

```bash
# Ensure production environment (should already be set)
./scripts/switch-env.sh production

# Deploy edge functions
supabase functions deploy --project-ref bapwklwxmwhpucutyras

# Apply migrations
supabase db push --project-ref bapwklwxmwhpucutyras
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

- `.env` - Single env file with all keys, APP_ENV toggles environment (gitignored)
- `lib/core/config/env/env.g.dart` - Generated env file (auto-updated by switch script)

## Workflow for New Features

1. Work on `main` branch (or `feature/*` branch for large features)
2. Make changes
3. Test with production environment using test accounts
4. Deploy directly to production
5. For large features, merge feature branch to `main`

## Database Migrations

- Apply migrations directly to production: `supabase db push --project-ref bapwklwxmwhpucutyras`
- For destructive migrations, create a backup first
- No need to test on staging - production is the only environment

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Primary development branch |
| `feature/*` | Large feature development |
| `fix/*` | Bug fixes |
