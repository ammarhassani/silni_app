/**
 * APP CONFIGURATION
 *
 * This file contains all configurable settings for the Silni app.
 * These values can be overridden by Firebase Remote Config for dynamic updates.
 *
 * CONTROL PANEL: All these settings will be manageable from admin panel.
 */

export interface AppConfig {
  // App Information
  app: {
    name: string;
    version: string;
    environment: 'development' | 'staging' | 'production';
  };

  // Feature Flags - Control panel can enable/disable features
  features: {
    authentication: {
      emailPasswordEnabled: boolean;
      phoneAuthEnabled: boolean;
      googleSignInEnabled: boolean;
      appleSignInEnabled: boolean;
      allowGuestMode: boolean;
    };
    relatives: {
      unlimitedRelativesInFree: boolean;
      maxRelativesFree: number; // If unlimited is false
      allowImportFromContacts: boolean;
      allowFamilyTree: boolean; // Premium feature
    };
    interactions: {
      allowPhotoAttachments: boolean;
      allowAudioNotes: boolean; // Premium
      allowVideoNotes: boolean; // Premium
      enableQualityRating: boolean; // Premium
    };
    reminders: {
      enableDailyReminders: boolean;
      enableSmartReminders: boolean; // Premium
      enableBirthdayReminders: boolean;
      maxRemindersPerDayFree: number;
      unlimitedRemindersPremium: boolean;
    };
    statistics: {
      enableBasicStats: boolean;
      enableAdvancedCharts: boolean; // Premium
      enableYearInReview: boolean; // Premium
      enableExportReports: boolean; // Premium
    };
    gamification: {
      enableBadges: boolean; // Premium
      enableLevels: boolean; // Premium
      enableStreaks: boolean;
      enableChallenges: boolean; // Premium
      enableLeaderboards: boolean; // Premium - Future
    };
    content: {
      enableDailyHadith: boolean;
      enableEducationalContent: boolean;
      enableFAQ: boolean;
      contentLanguages: string[]; // ['ar', 'en']
    };
    premium: {
      enableFreeTrial: boolean;
      freeTrialDays: number;
      monthlyPrice: number; // SAR
      yearlyPrice: number; // SAR
      yearlyDiscountPercent: number;
    };
  };

  // Content Settings - Control panel can update content
  content: {
    onboarding: {
      enabled: boolean;
      slides: {
        title: string;
        description: string;
        imageUrl?: string;
      }[];
    };
    dailyHadith: {
      enabled: boolean;
      rotationFrequency: 'daily' | 'weekly';
      source: 'local' | 'api';
      apiUrl?: string;
    };
    educationalContent: {
      enabled: boolean;
      categories: string[];
      updateFrequency: 'manual' | 'auto';
    };
  };

  // UI/UX Settings - Control panel can customize appearance
  ui: {
    theme: {
      defaultTheme: 'light' | 'dark' | 'system';
      allowThemeCustomization: boolean;
      availableThemes: string[];
    };
    language: {
      defaultLanguage: 'ar' | 'en';
      availableLanguages: string[];
      autoDetect: boolean;
    };
    notifications: {
      enablePushNotifications: boolean;
      enableInAppNotifications: boolean;
      notificationSound: boolean;
      vibration: boolean;
    };
  };

  // Limits & Quotas - Control panel can adjust limits
  limits: {
    free: {
      maxRelatives: number | null; // null = unlimited
      maxInteractionsPerMonth: number | null;
      maxPhotosPerInteraction: number;
      maxRemindersPerDay: number;
      historyDays: number; // How many days of history
    };
    premium: {
      maxRelatives: number | null;
      maxInteractionsPerMonth: number | null;
      maxPhotosPerInteraction: number;
      maxRemindersPerDay: number | null;
      historyDays: number | null;
    };
  };

  // Backend Settings
  backend: {
    apiVersion: string;
    timeout: number; // milliseconds
    retryAttempts: number;
    cacheDuration: number; // minutes
  };

  // Analytics & Tracking
  analytics: {
    enabled: boolean;
    anonymizeIP: boolean;
    trackScreenViews: boolean;
    trackEvents: boolean;
    trackErrors: boolean;
  };

  // Security
  security: {
    requireBiometrics: boolean;
    sessionTimeout: number; // minutes
    autoLockTimeout: number; // minutes
    allowScreenshots: boolean;
  };

  // Maintenance & Updates
  maintenance: {
    isUnderMaintenance: boolean;
    maintenanceMessage?: string;
    forceUpdateRequired: boolean;
    minimumAppVersion: string;
    updateMessage?: string;
  };

  // External Links
  links: {
    privacyPolicy: string;
    termsOfService: string;
    support: string;
    faq: string;
    website: string;
    socialMedia: {
      twitter?: string;
      instagram?: string;
      facebook?: string;
    };
  };
}

/**
 * DEFAULT CONFIGURATION
 * These are the default values. They can be overridden by:
 * 1. Firebase Remote Config (for dynamic updates)
 * 2. Environment variables (for different environments)
 * 3. Control Panel (for admin changes)
 */
export const defaultConfig: AppConfig = {
  app: {
    name: 'Silni',
    version: '1.0.0',
    environment: 'development',
  },

  features: {
    authentication: {
      emailPasswordEnabled: true,
      phoneAuthEnabled: true,
      googleSignInEnabled: false, // Future
      appleSignInEnabled: false, // Future
      allowGuestMode: false,
    },
    relatives: {
      unlimitedRelativesInFree: true,
      maxRelativesFree: 50, // If unlimited is false
      allowImportFromContacts: true,
      allowFamilyTree: true, // Premium
    },
    interactions: {
      allowPhotoAttachments: true,
      allowAudioNotes: true, // Premium
      allowVideoNotes: false, // Future
      enableQualityRating: true, // Premium
    },
    reminders: {
      enableDailyReminders: true,
      enableSmartReminders: true, // Premium
      enableBirthdayReminders: true,
      maxRemindersPerDayFree: 10,
      unlimitedRemindersPremium: true,
    },
    statistics: {
      enableBasicStats: true,
      enableAdvancedCharts: true, // Premium
      enableYearInReview: true, // Premium
      enableExportReports: true, // Premium
    },
    gamification: {
      enableBadges: true, // Premium
      enableLevels: true, // Premium
      enableStreaks: true,
      enableChallenges: true, // Premium
      enableLeaderboards: false, // Future
    },
    content: {
      enableDailyHadith: true,
      enableEducationalContent: true,
      enableFAQ: true,
      contentLanguages: ['ar', 'en'],
    },
    premium: {
      enableFreeTrial: true,
      freeTrialDays: 7,
      monthlyPrice: 7.99, // SAR
      yearlyPrice: 79.99, // SAR
      yearlyDiscountPercent: 16,
    },
  },

  content: {
    onboarding: {
      enabled: true,
      slides: [
        {
          title: 'أهلاً بك في صِلْني',
          description: 'نساعدك على تنظيم صلة رحمك بطريقة سهلة ومحفزة',
        },
        {
          title: 'تذكيرات ذكية',
          description: 'لن تنسى أبداً التواصل مع أحبائك',
        },
        {
          title: 'تتبع إنجازاتك',
          description: 'شاهد تقدمك واحتسب الأجر من الله',
        },
      ],
    },
    dailyHadith: {
      enabled: true,
      rotationFrequency: 'daily',
      source: 'local',
    },
    educationalContent: {
      enabled: true,
      categories: ['أحكام', 'فضائل', 'قصص', 'أسئلة وأجوبة'],
      updateFrequency: 'manual',
    },
  },

  ui: {
    theme: {
      defaultTheme: 'light',
      allowThemeCustomization: true,
      availableThemes: ['light', 'dark', 'islamic'],
    },
    language: {
      defaultLanguage: 'ar',
      availableLanguages: ['ar', 'en'],
      autoDetect: true,
    },
    notifications: {
      enablePushNotifications: true,
      enableInAppNotifications: true,
      notificationSound: true,
      vibration: true,
    },
  },

  limits: {
    free: {
      maxRelatives: null, // Unlimited in free (as per PRD)
      maxInteractionsPerMonth: null,
      maxPhotosPerInteraction: 3,
      maxRemindersPerDay: 10,
      historyDays: 30,
    },
    premium: {
      maxRelatives: null,
      maxInteractionsPerMonth: null,
      maxPhotosPerInteraction: 10,
      maxRemindersPerDay: null,
      historyDays: null, // Unlimited
    },
  },

  backend: {
    apiVersion: 'v1',
    timeout: 30000, // 30 seconds
    retryAttempts: 3,
    cacheDuration: 60, // 1 hour
  },

  analytics: {
    enabled: true,
    anonymizeIP: true,
    trackScreenViews: true,
    trackEvents: true,
    trackErrors: true,
  },

  security: {
    requireBiometrics: false,
    sessionTimeout: 30, // 30 minutes
    autoLockTimeout: 5, // 5 minutes
    allowScreenshots: true,
  },

  maintenance: {
    isUnderMaintenance: false,
    forceUpdateRequired: false,
    minimumAppVersion: '1.0.0',
  },

  links: {
    privacyPolicy: 'https://silni.app/privacy',
    termsOfService: 'https://silni.app/terms',
    support: 'mailto:support@silni.app',
    faq: 'https://silni.app/faq',
    website: 'https://silni.app',
    socialMedia: {},
  },
};
