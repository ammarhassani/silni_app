# Silni App - AI Assistant Guidelines

## Project Overview
Silni (صِلني) is a Flutter app for maintaining family relationships through interaction tracking, streaks, and AI-powered insights.

## Supabase
- **Production**: `bapwklwxmwhpucutyras`
- Deploy functions: `supabase functions deploy --project-ref bapwklwxmwhpucutyras`
- Push migrations: `supabase db push` (after linking)

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

## Key Files
- `.env` - Environment config (gitignored)
- `lib/core/config/env/env.g.dart` - Generated env file
