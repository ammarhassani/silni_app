# 🎛️ Silni Control Panel System

## Overview

The Silni app is built with a fully configurable architecture that allows **everything** to be controlled from a centralized control panel without requiring app updates.

## Architecture

### 1. Configuration Layers

```
┌─────────────────────────────────────┐
│   Control Panel (Web Admin)        │
│   - Modify settings                 │
│   - Enable/disable features         │
│   - Update content                  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Firebase Remote Config            │
│   - Stores configuration JSON       │
│   - Propagates to all app instances │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   App Config Service                │
│   - Merges default + remote config  │
│   - Caches locally                  │
│   - Applies overrides               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Mobile App                        │
│   - Uses config for all decisions   │
│   - Updates in real-time            │
└─────────────────────────────────────┘
```

### 2. What's Configurable

#### ✅ Features (Enable/Disable)
- Authentication methods
- Premium features
- Gamification elements
- Content sections
- Social features

#### ✅ Content
- Onboarding slides
- Daily Hadith
- Educational content
- FAQs
- Notifications

#### ✅ UI/UX
- Theme options
- Available languages
- Color schemes
- Layout options

#### ✅ Pricing & Limits
- Subscription prices
- Free tier limits
- Premium features list
- Trial period duration

#### ✅ Business Logic
- Free vs Premium features
- Usage quotas
- Rate limits
- Feature availability

#### ✅ Maintenance
- Maintenance mode
- Force update requirements
- Version control
- Error messages

## Implementation

### Current State (Phase 1)

**✅ Completed:**
- Default configuration file (`src/constants/appConfig.ts`)
- Configuration service (`src/services/configService.ts`)
- TypeScript types for all settings
- Local override system for testing

**🔄 Next Steps:**
1. Integrate Firebase Remote Config (when Firebase is set up)
2. Build admin web panel (React/Next.js)
3. Create API for control panel ↔ Firebase

### Using Configuration in Code

```typescript
import { configService, isFeatureEnabled } from '@services/configService';

// Check if a feature is enabled
if (isFeatureEnabled('features.gamification.enableBadges')) {
  // Show badges
}

// Get pricing info
const pricing = configService.getPremiumPricing();

// Check limits
const limits = configService.getLimits(isPremiumUser);

// Check if feature is available for user
if (configService.canAccessPremiumFeature('features.statistics.enableAdvancedCharts', isPremiumUser)) {
  // Show advanced charts
}
```

### Testing Features Locally

```typescript
import { configService } from '@services/configService';

// Override a setting for testing
configService.setLocalOverride('features.gamification.enableBadges', false);

// Clear overrides
configService.clearLocalOverrides();
```

## Control Panel Features

### Phase 1: Basic Admin Panel
- [ ] View all configuration settings
- [ ] Edit feature flags
- [ ] Update content (Hadith, onboarding, etc.)
- [ ] Modify pricing
- [ ] Set maintenance mode

### Phase 2: Advanced Features
- [ ] A/B testing configurations
- [ ] Segment-based config (by region, language, etc.)
- [ ] Scheduled config changes
- [ ] Config version history & rollback
- [ ] Real-time config preview

### Phase 3: Analytics Integration
- [ ] Feature usage analytics
- [ ] Config change impact tracking
- [ ] User segment performance
- [ ] Revenue optimization

## Control Panel Tech Stack (Planned)

```
Frontend: Next.js + TypeScript + Tailwind CSS
Backend: Firebase Cloud Functions
Database: Firestore (config storage)
Auth: Firebase Admin Auth
Hosting: Vercel / Firebase Hosting
```

## Security

### Access Control
- Admin authentication required
- Role-based access control (RBAC)
- Audit logs for all changes
- Two-factor authentication

### Config Validation
- Schema validation before applying
- Rollback capability
- Staged deployments (test → production)
- Change approval workflow

## Firebase Remote Config Structure

```json
{
  "app_config": {
    "features": {
      "authentication": {
        "emailPasswordEnabled": true,
        "phoneAuthEnabled": true
      },
      "premium": {
        "monthlyPrice": 7.99,
        "yearlyPrice": 79.99,
        "freeTrialDays": 7
      }
      // ... all other config
    }
  }
}
```

## Benefits

### 1. No App Updates Required
- Change features instantly
- Fix issues immediately
- Test new features quickly
- Gradual rollouts

### 2. Flexibility
- Run experiments
- Customize per region
- Seasonal changes
- Emergency shutdowns

### 3. Business Agility
- Adjust pricing dynamically
- Launch features faster
- Respond to feedback quickly
- Optimize conversion rates

### 4. Risk Mitigation
- Kill switch for problematic features
- Gradual rollouts
- Easy rollbacks
- Testing in production safely

## Roadmap

### Q1 2025
- ✅ Configuration architecture
- ⏳ Firebase Remote Config integration
- ⏳ Basic admin panel (read-only)

### Q2 2025
- Admin panel CRUD operations
- Feature flag management
- Content management
- User role management

### Q3 2025
- A/B testing framework
- Analytics integration
- Automated rollouts
- Version control

### Q4 2025
- Advanced segmentation
- ML-based optimization
- Multi-region support
- Advanced analytics

## Notes for Developers

1. **Always use `configService.get()` instead of hardcoded values**
2. **Never bypass the config service**
3. **Document new configurable settings in `appConfig.ts`**
4. **Test with different configurations**
5. **Handle config loading failures gracefully**

## Example Use Cases

### 1. Emergency Maintenance
```typescript
// Admin sets in control panel:
maintenance: {
  isUnderMaintenance: true,
  maintenanceMessage: "نعتذر، النظام قيد الصيانة حالياً"
}

// App automatically shows maintenance screen
```

### 2. Feature Rollout
```typescript
// Week 1: Enable for 10% of users (via segment)
// Week 2: Enable for 50% of users
// Week 3: Enable for all users
```

### 3. Pricing Experiment
```typescript
// Test different prices for new users
// Region A: 7.99 SAR
// Region B: 9.99 SAR
// Measure conversion rates
```

### 4. Content Update
```typescript
// Update daily Hadith collection without app update
// Add new onboarding slides
// Update educational content
```

---

**🎯 Goal**: Make Silni the most flexible and maintainable Islamic app through comprehensive configurability.
