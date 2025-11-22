/**
 * CONFIGURATION SERVICE
 *
 * This service manages app configuration with support for:
 * 1. Default configuration (from appConfig.ts)
 * 2. Firebase Remote Config (for dynamic updates from control panel)
 * 3. Local overrides (for testing)
 * 4. Environment-specific configs
 *
 * CONTROL PANEL INTEGRATION:
 * - Admin panel can update Firebase Remote Config
 * - Changes propagate to all app instances
 * - No app update required for config changes
 */

import { defaultConfig, AppConfig } from '@constants/appConfig';
// Firebase Remote Config will be imported when Firebase is set up
// import { fetchAndActivate, getValue } from 'firebase/remote-config';

type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};

class ConfigService {
  private config: AppConfig = defaultConfig;
  private remoteConfigInitialized = false;
  private localOverrides: DeepPartial<AppConfig> = {};

  /**
   * Initialize the configuration service
   * Call this on app startup
   */
  async initialize(): Promise<void> {
    try {
      // Load local overrides from AsyncStorage (if any)
      await this.loadLocalOverrides();

      // Initialize Firebase Remote Config (when Firebase is set up)
      // await this.initializeRemoteConfig();

      // Merge configurations: defaults < remote < local overrides
      this.mergeConfigurations();

      console.log('✅ Configuration service initialized');
    } catch (error) {
      console.error('❌ Failed to initialize config service:', error);
      // Fallback to default config
      this.config = defaultConfig;
    }
  }

  /**
   * Get the entire configuration object
   */
  getConfig(): AppConfig {
    return this.config;
  }

  /**
   * Get a specific configuration value using dot notation
   * Example: get('features.relatives.unlimitedRelativesInFree')
   */
  get<T = any>(path: string): T {
    const keys = path.split('.');
    let value: any = this.config;

    for (const key of keys) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        console.warn(`Config path not found: ${path}`);
        return undefined as T;
      }
    }

    return value as T;
  }

  /**
   * Check if a feature is enabled
   * Example: isFeatureEnabled('features.gamification.enableBadges')
   */
  isFeatureEnabled(featurePath: string): boolean {
    return this.get<boolean>(featurePath) ?? false;
  }

  /**
   * Check if user has premium features based on subscription status
   */
  canAccessPremiumFeature(featurePath: string, isPremiumUser: boolean): boolean {
    const featureEnabled = this.get<boolean>(featurePath);

    // If feature is not explicitly marked as premium in path,
    // check the feature flag
    if (!featurePath.includes('Premium') && !featurePath.includes('premium')) {
      return featureEnabled ?? false;
    }

    return featureEnabled && isPremiumUser;
  }

  /**
   * Get app version for update checks
   */
  getAppVersion(): string {
    return this.get<string>('app.version') ?? '1.0.0';
  }

  /**
   * Check if app is under maintenance
   */
  isUnderMaintenance(): boolean {
    return this.get<boolean>('maintenance.isUnderMaintenance') ?? false;
  }

  /**
   * Check if force update is required
   */
  isForceUpdateRequired(currentVersion: string): boolean {
    const forceUpdateRequired = this.get<boolean>('maintenance.forceUpdateRequired');
    const minimumVersion = this.get<string>('maintenance.minimumAppVersion');

    if (!forceUpdateRequired || !minimumVersion) {
      return false;
    }

    return this.compareVersions(currentVersion, minimumVersion) < 0;
  }

  /**
   * Get premium pricing
   */
  getPremiumPricing() {
    return {
      monthly: this.get<number>('features.premium.monthlyPrice'),
      yearly: this.get<number>('features.premium.yearlyPrice'),
      freeTrialDays: this.get<number>('features.premium.freeTrialDays'),
      enableFreeTrial: this.get<boolean>('features.premium.enableFreeTrial'),
    };
  }

  /**
   * Get usage limits for free/premium users
   */
  getLimits(isPremium: boolean) {
    return isPremium
      ? this.get('limits.premium')
      : this.get('limits.free');
  }

  /**
   * Refresh configuration from remote
   * Call this periodically or when user requests
   */
  async refresh(): Promise<void> {
    try {
      // Fetch latest from Firebase Remote Config
      // await this.fetchRemoteConfig();

      this.mergeConfigurations();
      console.log('✅ Configuration refreshed');
    } catch (error) {
      console.error('❌ Failed to refresh config:', error);
    }
  }

  /**
   * Set a local override for testing
   * This is useful for debugging and testing specific features
   */
  setLocalOverride(path: string, value: any): void {
    const keys = path.split('.');
    let current: any = this.localOverrides;

    for (let i = 0; i < keys.length - 1; i++) {
      const key = keys[i];
      if (!(key in current)) {
        current[key] = {};
      }
      current = current[key];
    }

    current[keys[keys.length - 1]] = value;
    this.mergeConfigurations();
  }

  /**
   * Clear all local overrides
   */
  clearLocalOverrides(): void {
    this.localOverrides = {};
    this.mergeConfigurations();
  }

  // Private methods

  private async loadLocalOverrides(): Promise<void> {
    try {
      // Load from AsyncStorage when needed
      // const stored = await AsyncStorage.getItem('config_overrides');
      // if (stored) {
      //   this.localOverrides = JSON.parse(stored);
      // }
    } catch (error) {
      console.error('Failed to load local overrides:', error);
    }
  }

  private async initializeRemoteConfig(): Promise<void> {
    try {
      // TODO: Initialize Firebase Remote Config
      // const remoteConfig = getRemoteConfig(firebaseApp);
      // remoteConfig.settings.minimumFetchIntervalMillis = 3600000; // 1 hour
      //
      // Set default values
      // await remoteConfig.setDefaults(defaultConfig);
      //
      // Fetch and activate
      // await fetchAndActivate(remoteConfig);
      //
      // this.remoteConfigInitialized = true;
    } catch (error) {
      console.error('Failed to initialize remote config:', error);
    }
  }

  private async fetchRemoteConfig(): Promise<void> {
    if (!this.remoteConfigInitialized) {
      return;
    }

    try {
      // TODO: Fetch from Firebase Remote Config
      // const remoteConfig = getRemoteConfig();
      // await fetchAndActivate(remoteConfig);
      //
      // Parse the config
      // const remoteConfigData = getValue(remoteConfig, 'app_config').asString();
      // if (remoteConfigData) {
      //   const parsedConfig = JSON.parse(remoteConfigData);
      //   this.mergeConfigurations(parsedConfig);
      // }
    } catch (error) {
      console.error('Failed to fetch remote config:', error);
    }
  }

  private mergeConfigurations(remoteConfig?: DeepPartial<AppConfig>): void {
    // Priority: default < remote < local overrides
    this.config = {
      ...defaultConfig,
      ...(remoteConfig as any),
      ...(this.localOverrides as any),
    };

    // Deep merge for nested objects
    this.config = this.deepMerge(
      defaultConfig,
      remoteConfig || {},
      this.localOverrides
    ) as AppConfig;
  }

  private deepMerge(...objects: any[]): any {
    return objects.reduce((prev, obj) => {
      Object.keys(obj).forEach((key) => {
        const prevValue = prev[key];
        const objValue = obj[key];

        if (Array.isArray(prevValue) && Array.isArray(objValue)) {
          prev[key] = objValue;
        } else if (
          typeof prevValue === 'object' &&
          prevValue !== null &&
          typeof objValue === 'object' &&
          objValue !== null
        ) {
          prev[key] = this.deepMerge(prevValue, objValue);
        } else {
          prev[key] = objValue;
        }
      });

      return prev;
    }, {});
  }

  private compareVersions(version1: string, version2: string): number {
    const v1 = version1.split('.').map(Number);
    const v2 = version2.split('.').map(Number);

    for (let i = 0; i < Math.max(v1.length, v2.length); i++) {
      const num1 = v1[i] || 0;
      const num2 = v2[i] || 0;

      if (num1 > num2) return 1;
      if (num1 < num2) return -1;
    }

    return 0;
  }
}

// Export singleton instance
export const configService = new ConfigService();

// Export convenience functions
export const getConfig = () => configService.getConfig();
export const isFeatureEnabled = (path: string) => configService.isFeatureEnabled(path);
export const canAccessPremiumFeature = (path: string, isPremium: boolean) =>
  configService.canAccessPremiumFeature(path, isPremium);
