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

#### A/B Testing Configurations
- Define test variants directly in Firebase Remote Config
- Segment users automatically by ID hash for consistent assignment
- Track conversion metrics per variant using Analytics events
- Automatic winner selection based on statistical significance
- Implementation:
  ```dart
  // Check which variant the user is in
  final variant = configService.getABTestVariant('pricing_experiment');

  // Show appropriate UI based on variant
  switch (variant) {
    case 'control': showOriginalPricing();
    case 'variant_a': showDiscountedPricing();
    case 'variant_b': showBundlePricing();
  }
  ```

#### Segment-Based Configuration
- **Geographic targeting**: Different config for Saudi Arabia, UAE, Egypt, etc.
- **Language-based**: Arabic-specific or English-specific features
- **Platform-specific**: iOS vs Android configurations
- **Subscription tier targeting**: Free vs MAX user experiences
- **User cohort targeting**: New users vs returning users
- Implementation:
  ```dart
  // Get segment-specific config
  final config = configService.getConfigForSegment(
    region: user.region,
    language: user.preferredLanguage,
    tier: user.subscriptionTier,
  );
  ```

#### Scheduled Configuration Changes
- Time-based configuration activation (e.g., Ramadan special features)
- Scheduled maintenance windows with automatic activation
- Feature release scheduling (unlock at specific date/time)
- Promotional pricing windows (weekend sales, holiday discounts)
- Implementation:
  ```dart
  // Scheduled config structure
  {
    "scheduled_changes": [
      {
        "id": "ramadan_2025",
        "starts_at": "2025-02-28T00:00:00Z",
        "ends_at": "2025-03-29T23:59:59Z",
        "config_override": {
          "features.islamicContent.ramadanMode": true,
          "ui.theme.primaryColor": "#1a5f3f"
        }
      }
    ]
  }
  ```

#### Config Version History & Rollback
- Automatic versioning of all configuration changes
- Git-like version control for configurations
- One-click rollback to any previous version
- Change comparison (diff view) between versions
- Audit trail with change attribution (who changed what and when)
- Implementation:
  ```dart
  // Admin API endpoints
  GET  /api/config/versions         // List all versions
  GET  /api/config/versions/{id}    // Get specific version
  POST /api/config/rollback/{id}    // Rollback to version
  GET  /api/config/diff/{v1}/{v2}   // Compare versions
  ```

#### Real-time Config Preview
- Preview configuration changes before applying
- Side-by-side comparison (current vs proposed)
- Test configuration on specific user accounts
- Sandbox environment for testing
- Staged rollout preview (see how 10%, 50%, 100% would look)

### Phase 3: Analytics Integration

#### Feature Usage Analytics
- Track feature access frequency per user segment
- Measure user engagement time per feature
- Analyze feature discovery paths (how users find features)
- Identify unused features for potential removal
- Implementation:
  ```dart
  // Track feature usage
  AnalyticsService.trackFeatureUsage(
    featureId: 'ai_counselor',
    duration: sessionDuration,
    interactionCount: messageCount,
    metadata: {'source': 'home_screen'},
  );
  ```

#### Config Change Impact Tracking
- Correlate configuration changes with key metrics
- A/B test result analysis and statistical significance
- Conversion rate tracking by configuration variant
- Revenue impact analysis per configuration change
- User retention metrics by feature flag state
- Implementation:
  ```dart
  // Impact analysis query
  {
    "config_change_id": "pricing_v2",
    "metrics": {
      "conversion_rate": {"before": 2.3%, "after": 3.1%, "lift": +34.8%},
      "revenue_per_user": {"before": 1.23, "after": 1.67, "lift": +35.8%},
      "churn_rate": {"before": 5.2%, "after": 4.8%, "lift": -7.7%}
    },
    "statistical_significance": 0.95
  }
  ```

#### User Segment Performance
- Segment-specific KPI dashboards
- Cohort analysis by acquisition source, region, tier
- Churn prediction models by segment
- Lifetime Value (LTV) estimation per segment
- Segment health scores and alerts
- Metrics tracked:
  - Daily/Weekly/Monthly Active Users per segment
  - Feature adoption rates
  - Subscription conversion rates
  - Average session duration
  - Retention curves (D1, D7, D30)

#### Revenue Optimization
- Dynamic pricing optimization based on user behavior
- Subscription plan performance comparison
- Upgrade/downgrade flow optimization
- Trial conversion funnel analysis
- Promotional effectiveness measurement
- Implementation:
  ```dart
  // Revenue optimization dashboard
  {
    "current_period": {
      "mrr": 12500.00,
      "arr": 150000.00,
      "new_subscriptions": 145,
      "churned_subscriptions": 23,
      "net_revenue_retention": 112%
    },
    "recommendations": [
      {
        "action": "Increase annual discount",
        "expected_lift": "+15% annual conversions",
        "confidence": 0.87
      }
    ]
  }
  ```

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
