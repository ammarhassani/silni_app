# صِلْني - Silni | Family Connection Tracker

<div align="center">
  <img src="assets/images/silni_logo.svg" alt="Silni Logo" width="200"/>
  
  **A comprehensive Islamic family connection tracker with stunning UI/UX**
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
  [![Build Status](https://img.shields.io/github/workflows/CI/badge.svg)](https://github.com/your-org/silni_app/actions)
  [![Coverage](https://img.shields.io/codecov/c/github/your-org/silni_app)](https://codecov.io/gh/your-org/silni_app)
  
  [Download for iOS](#) | [Download for Android](#) | [Web App](#)
</div>

---

## English | [العربية](#arabic)

## Table of Contents
- [About](#about)
- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Usage](#usage)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## About

**Silni** (صِلْني) is a comprehensive Islamic family connection tracker designed to help Muslims maintain strong family ties (صلة الرحم). The app combines modern technology with Islamic values to encourage regular communication with relatives through smart reminders, gamification, and daily Islamic teachings.

The name "Silni" comes from the Arabic concept of "صلة الرحم" (maintaining family ties), which is highly emphasized in Islamic teachings as a means of earning blessings in both this life and the hereafter.

### Mission

Strengthen family bonds in the Muslim community by providing a modern, intuitive platform that:
- Encourages regular family communication
- Provides Islamic context and guidance
- Uses technology to facilitate religious obligations
- Creates meaningful family connections across distances

### Vision

Become the leading digital platform for Muslim families worldwide, fostering stronger family relationships through innovative technology while respecting Islamic values and cultural traditions.

---

## Features

### 🌳 Family Management
- **Comprehensive Profiles**: Add and manage family members with detailed information
- **Interactive Family Tree**: Visual representation of family relationships
- **Contact Integration**: Import contacts from your phone
- **Smart Search**: Find family members quickly
- **Relationship Tracking**: Monitor communication patterns and frequency

### ⏰ Smart Reminders
- **Intelligent Scheduling**: AI-powered reminder optimization
- **Flexible Frequencies**: Daily, weekly, monthly, and custom schedules
- **Islamic Features**: Friday-specific reminders and Islamic greetings
- **Priority-Based**: Different reminder frequencies based on relationship importance
- **Multi-Channel**: Push notifications, in-app alerts, and email reminders

### 📿 Islamic Content
- **Daily Hadith**: Curated Islamic teachings about family ties
- **Quranic Verses**: Relevant verses about family relationships
- **Islamic Wisdom**: Quotes and teachings from Islamic scholars
- **Prayer Times**: Integration with Islamic prayer schedules
- **Cultural Context**: Content relevant to Muslim family traditions

### 🏆 Gamification System
- **Points System**: Earn points for maintaining family connections
- **Achievement Badges**: Unlock badges for consistent communication
- **Level Progression**: Advance through levels with increasing responsibilities
- **Streak Tracking**: Maintain and visualize communication streaks
- **Leaderboards**: Compare progress with family members (optional)
- **Challenges**: Participate in family connection challenges

### 📊 Analytics & Insights
- **Comprehensive Statistics**: Detailed family communication patterns
- **Visual Charts**: Interactive charts showing interaction frequency
- **Progress Tracking**: Monitor improvement over time
- **Relationship Health**: AI-powered relationship health scoring
- **Trend Analysis**: Identify patterns and areas for improvement
- **Export Reports**: Download family connection reports

### 🤖 AI-Powered Features
- **Relationship Analysis**: AI insights into relationship health
- **Gift Recommendations**: Personalized gift suggestions based on preferences
- **Communication Scripts**: AI-generated conversation starters and scripts
- **Weekly Reports**: AI-generated family connection summaries
- **Smart Suggestions**: Context-aware recommendations for strengthening bonds

### 🎨 Beautiful UI/UX
- **Glassmorphic Design**: Modern, elegant visual design
- **Smooth Animations**: Fluid transitions and micro-interactions
- **RTL Support**: Full right-to-left Arabic support
- **Dark/Light Themes**: Multiple theme options
- **Responsive Design**: Optimized for all screen sizes
- **Accessibility**: Support for users with disabilities

### 🔒 Security & Privacy
- **Secure Authentication**: Email/password and social login options
- **Biometric Support**: Fingerprint and face ID authentication
- **Data Encryption**: End-to-end encryption for sensitive data
- **Privacy Controls**: Granular privacy settings and controls
- **GDPR Compliance**: Full compliance with data protection regulations

### 📱 Cross-Platform Support
- **iOS Native**: Optimized for iPhone and iPad
- **Android Native**: Optimized for Android phones and tablets
- **Web Application**: Full-featured web version
- **Offline Support**: Core functionality available without internet
- **Sync Across Devices**: Seamless synchronization between devices

---

## Screenshots

<div align="center">
  <img src="screenshots/home_screen.png" alt="Home Screen" width="200"/>
  <img src="screenshots/family_tree.png" alt="Family Tree" width="200"/>
  <img src="screenshots/reminders.png" alt="Reminders" width="200"/>
  <img src="screenshots/statistics.png" alt="Statistics" width="200"/>
  <img src="screenshots/ai_features.png" alt="AI Features" width="200"/>
  <img src="screenshots/gamification.png" alt="Gamification" width="200"/>
</div>

---

## Installation

### Prerequisites
- **Flutter SDK**: 3.10.1 or later
- **Dart SDK**: 3.10.1 or later (included with Flutter)
- **Platform Support**: iOS 12+, Android API 21+, Modern browsers
- **Storage**: 100MB available space
- **Network**: Internet connection for initial setup and sync

### Quick Start

#### Option 1: Download from App Stores

**iOS App Store**
1. Open App Store on your iOS device
2. Search for "Silni" or scan QR code
3. Tap "Get" to download and install
4. Open app and follow setup instructions

**Google Play Store**
1. Open Google Play Store on your Android device
2. Search for "Silni" or scan QR code
3. Tap "Install" to download and install
4. Open app and follow setup instructions

#### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/your-org/silni_app.git
cd silni_app

# Install dependencies
flutter pub get

# Generate environment files
flutter pub run build_runner build

# Copy environment configuration
cp .env.example .env
# Edit .env with your configuration

# Run the app
flutter run
```

### Environment Configuration

Create `.env` file in project root:

```bash
# Application Environment
APP_ENV=development
ENVIRONMENT=development

# Supabase Configuration
SUPABASE_STAGING_URL=your_supabase_url
SUPABASE_STAGING_ANON_KEY=your_supabase_anon_key

# Firebase Configuration
FIREBASE_PROJECT_ID=your_firebase_project_id
FCM_SERVER_KEY=your_fcm_server_key

# Monitoring Configuration
SENTRY_DSN=your_sentry_dsn

# Feature Flags
ENABLE_AI_FEATURES=true
ENABLE_PREMIUM_FEATURES=true
ENABLE_ANALYTICS=true
```

---

## Usage

### Getting Started

1. **Create Account**: Sign up with email or social login
2. **Add Family Members**: Import from contacts or add manually
3. **Set Up Reminders**: Configure reminder schedules for each relative
4. **Start Connecting**: Log interactions and track communication
5. **Explore Features**: Discover AI insights, gamification, and analytics

### Core Workflows

#### Adding Family Members
1. Tap "Add Relative" button
2. Fill in family member details
3. Set relationship type and priority
4. Add contact information and preferences
5. Save and start tracking interactions

#### Setting Reminders
1. Go to Reminders section
2. Tap "Create Schedule"
3. Select family members and frequency
4. Set preferred time and message
5. Enable notifications and save

#### Tracking Interactions
1. Visit family member's profile
2. Tap "Log Interaction"
3. Select interaction type (call, visit, message, etc.)
4. Add details and optional notes
5. Save to update statistics and streaks

#### Using AI Features
1. Go to AI Assistant section
2. Choose feature (analysis, scripts, recommendations)
3. Select family member and context
4. Review AI-generated insights
5. Apply suggestions to strengthen relationships

---

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Mobile App (Flutter)                  │
├─────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   UI Layer  │  │ Business    │  │   Data      │    │
│  │             │  │ Logic       │  │ Layer       │    │
│  │ - Screens   │  │ - Services  │  │ - Models    │    │
│  │ - Widgets   │  │ - Providers │  │ - Repos     │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────┐
│                    Backend Services                       │
├─────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Supabase   │  │  Firebase   │  │   Sentry    │    │
│  │             │  │             │  │             │    │
│  │ - Auth      │  │ - FCM       │  │ - Error     │    │
│  │ - Database  │  │ - Analytics │  │ Tracking    │    │
│  │ - Storage   │  │ - Performance│  │             │    │
│  │ - Realtime  │  │ Monitoring  │  │             │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────┘
```

### Key Architectural Patterns

- **Feature-Based Organization**: Code organized by features rather than layers
- **Clean Architecture**: Separation of concerns with clear boundaries
- **Reactive Programming**: Riverpod for state management and data flow
- **Repository Pattern**: Data access abstraction for testability
- **Dependency Injection**: Type-safe dependency management
- **Offline-First**: Local caching with sync capabilities

### Technology Decisions

For detailed architectural decisions and rationale, see [Technical Architecture Documentation](docs/TECHNICAL_ARCHITECTURE.md).

---

## Technology Stack

### Frontend Technologies

| Technology | Version | Purpose |
|-------------|---------|---------|
| **Flutter** | 3.10.1+ | Cross-platform mobile framework |
| **Dart** | 3.10.1+ | Programming language |
| **Riverpod** | 2.6.1+ | State management and dependency injection |
| **Go Router** | 14.8.1+ | Declarative routing and navigation |

### Backend Services

| Service | Purpose | Features |
|---------|---------|----------|
| **Supabase** | Primary backend | Auth, PostgreSQL, Storage, Realtime |
| **Firebase** | Complementary services | FCM, Analytics, Performance |
| **Sentry** | Monitoring | Error tracking and performance monitoring |

### Development Tools

| Tool | Purpose |
|------|---------|
| **Flutter CLI** | Command-line development tools |
| **VS Code** | Primary development environment |
| **Git** | Version control |
| **Supabase CLI** | Backend management |

For complete technology stack details, see [Technology Stack Documentation](docs/TECHNOLOGY_STACK.md).

---

## Documentation

### Available Documentation

| Document | Audience | Description |
|----------|------------|-------------|
| [Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md) | Developers | Comprehensive technical architecture overview |
| [API Specifications](docs/API_SPECIFICATIONS.md) | Developers | Complete API documentation |
| [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) | DevOps | Deployment and environment setup |
| [Maintenance Operations](docs/MAINTENANCE_OPERATIONS.md) | Operations | Maintenance and operational procedures |
| [Technology Stack](docs/TECHNOLOGY_STACK.md) | Developers | Complete technology stack overview |
| [Developer Guide](docs/DEVELOPER_GUIDE.md) | Contributors | Development setup and contribution guidelines |
| [Security & Compliance](docs/SECURITY_COMPLIANCE.md) | Security | Security measures and compliance |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Users | Common issues and solutions |
| [User Guide](docs/USER_GUIDE.md) | Users | Feature usage and tutorials |
| [Roadmap](docs/ROADMAP.md) | All | Future development plans |

### Getting Help

- **Documentation**: Check relevant documentation first
- **Issues**: Search existing GitHub issues
- **Discussions**: Use GitHub Discussions for questions
- **Community**: Join our Discord/Slack community
- **Support**: Contact support team for urgent issues

---

## Contributing

We welcome contributions from the community! Please see our [Developer Guide](docs/DEVELOPER_GUIDE.md) for detailed contribution guidelines.

### How to Contribute

1. **Fork Repository**: Create your own copy
2. **Create Branch**: `feature/your-feature-name`
3. **Make Changes**: Implement your feature or fix
4. **Add Tests**: Ensure comprehensive test coverage
5. **Submit PR**: Create pull request with description
6. **Review Process**: Participate in code review

### Contribution Areas

- **Code**: New features, bug fixes, performance improvements
- **Documentation**: Improve documentation and examples
- **Testing**: Add tests, improve test coverage
- **Design**: UI/UX improvements, new design concepts
- **Translations**: Help with internationalization
- **Community**: Support other contributors, answer questions

### Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md) to ensure a welcoming environment for all contributors.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### License Summary

- ✅ **Commercial Use**: Allowed
- ✅ **Modification**: Allowed
- ✅ **Distribution**: Allowed
- ✅ **Private Use**: Allowed
- ❌ **Liability**: No warranty provided
- ❌ **Trademark**: No trademark grant

---

## Support

### Getting Help

- **Documentation**: [docs/](docs/) directory
- **Issues**: [GitHub Issues](https://github.com/your-org/silni_app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/silni_app/discussions)
- **Email**: support@silni.app
- **Website**: [silni.app](https://silni.app)

### Social Media

- **Twitter**: [@SilniApp](https://twitter.com/SilniApp)
- **Facebook**: [Silni App](https://facebook.com/SilniApp)
- **Instagram**: [@silni_app](https://instagram.com/silni_app)

---

## Acknowledgments

### Special Thanks

- **Islamic Scholars**: For guidance on Islamic content and family values
- **Beta Testers**: For valuable feedback and testing
- **Open Source Community**: For amazing tools and libraries
- **Flutter Team**: For excellent cross-platform framework
- **Supabase Team**: For powerful backend services

### Libraries Used

This app wouldn't be possible without these amazing open-source libraries:

- [Flutter](https://flutter.dev/) - Cross-platform development framework
- [Riverpod](https://riverpod.dev/) - Reactive state management
- [Supabase](https://supabase.com/) - Backend services
- [Go Router](https://gorouter.dev/) - Declarative routing

For complete dependencies list, see [pubspec.yaml](pubspec.yaml).

---

## FAQ

### Common Questions

**Q: Is Silni free to use?**
A: Silni offers a freemium model with basic features free and premium features requiring subscription.

**Q: Is my data secure?**
A: Yes, all data is encrypted and stored securely. We follow industry best practices for data protection.

**Q: Does Silni work offline?**
A: Core features work offline, with sync when connection is restored.

**Q: Can I use Silni for my business?**
A: Silni is designed for personal family use. For business inquiries, please contact us.

For more FAQs, see our [Troubleshooting Guide](docs/TROUBLESHOOTING.md).

---

## Roadmap

### Upcoming Features

- **Family Events**: Event planning and coordination
- **Video Calling**: In-app video communication
- **Advanced AI**: More sophisticated relationship analysis
- **Multi-Language**: Support for English, French, German
- **Web Enhancements**: Full-featured web application
- **Premium Features**: Advanced analytics and exclusive content

### Release Schedule

- **Version 1.1**: Q1 2025 - Enhanced AI features
- **Version 1.2**: Q2 2025 - Family events and video calling
- **Version 2.0**: Q3 2025 - Multi-language support

For detailed roadmap, see [Roadmap Documentation](docs/ROADMAP.md).

---

<div align="center">

**Made with ❤️ for the Muslim Ummah**

[⭐ Star this repo](https://github.com/your-org/silni_app) | [🐛 Report issues](https://github.com/your-org/silni_app/issues) | [📖 Read docs](docs/)

</div>

---

## Arabic | [English](#english)

## جدول المحتويات
- [حول التطبيق](#حول-التطبيق)
- [المميزات](#المميزات)
- [لقطات الشاشة](#لقطات-الشاشة)
- [التثبيت](#التثبيت)
- [الاستخدام](#الاستخدام)
- [الهيكل](#الهيكل)
- [مكدس التقنيات](#مكدس-التقنيات)
- [التوثيق](#التوثيق)
- [المساهمة](#المساهمة)
- [الرخصة](#الرخصة)

## حول التطبيق

**صِلْني** هو تطبيق إسلامي شامل لتتبع روابط العائلة، مصمم لمساعدة المسلمين على الحفاظ على روابط عائلية قوية (صلة الرحم). يجمع التطبيق بين التكنولوجيا الحديثة والقيم الإسلامية لتشجيع التواصل المنتظم مع الأقارب من خلال التذكيرات الذكية، والتحفيز، والتعاليم الإسلامية اليومية.

اسم "صِلْني" مشتق من المفهوم الإسلامي "صلة الرحم"، الذي يُؤكد عليه بشدة في التعاليم الإسلامية كوسيلة لكسب البركات في الحياة الدنيا والآخرة.

### مهمتنا

تقوية الروابط الأسرية في المجتمع المسلم من خلال توفير منصة حديثة وبديهية:
- تشجع التواصل الأسري المنتظم
- توفير سياق إسلامي وإرشاد
- استخدام التكنولوجيا لتسهيل الالتزامات الدينية
- إنشاء روابط أسرية ذات معنى عبر المسافات

### رؤيتنا

أن نكون المنصة الرقمية الرائدة للأسر المسلمة في جميع أنحاء العالم، مما يعزز العلاقات الأسرية من خلال التكنولوجيا المبتكرة مع احترام القيم الإسلامية والتقاليد الثقافية.

## المميزات

### 🌳 إدارة العائلة
- **ملفات تعريف شاملة**: إضافة وإدارة أفراد العائلة بمعلومات مفصلة
- **شجرة عائلة تفاعلية**: تمثيل بصري للعلاقات الأسرية
- **تكامل جهات الاتصال**: استيراد جهات الاتصال من هاتفك
- **بحث ذكي**: العثور السريع على أفراد العائلة
- **تتبع العلاقات**: مراقبة أنماط التواصل والتكرار

### ⏰ التذكيرات الذكية
- **جدولة ذكية**: تحسين التذكيرات المدعومة بالذكاء الاصطناعي
- **تكرارات مرنة**: يومي، أسبوعي، شهري، وجداول مخصصة
- **مميزات إسلامية**: تذكيرات خاصة يوم الجمعة وتحيات إسلامية
- **قائم على الأولوية**: تكرارات تذكير مختلفة بناءً على أهمية العلاقة
- **قنوات متعددة**: إشعارات دفع، تنبيهات داخل التطبيق، وتذكيرات بريدية

### 📿 المحتوى الإسلامي
- **حديث نبوي يومي**: تعاليم إسلامية منتقاة عن روابط العائلة
- **آيات قرآنية**: آيات ذات صلة بالعلاقات الأسرية
- **حكم إسلامية**: اقتباسات وتعاليم من العلماء المسلمين
- **أوقات الصلاة**: تكامل مع جداول الصلاة الإسلامية
- **سياق ثقافي**: محتوى ذو صلة بالتقاليد الأسرية المسلمة

### 🏆 نظام التحفيز
- **نظام النقاط**: كسب نقاط للحفاظ على الروابط الأسرية
- **شارات الإنجاز**: فتح شارات للتوااصل المنتظم
- **تقدم المستويات**: التقدم عبر المستويات بمسؤوليات متزايدة
- **تتبع السلاسل**: الحفاظ على وتصور سلاسل التواصل
- **لوحات الصدارة**: مقارنة التقدم مع أفراد العائلة (اختياري)
- **التحديات**: المشاركة في تحديات التواصل الأسري

### 📊 التحليلات والرؤى
- **إحصائيات شاملة**: أنماط التواصل الأسري المفصلة
- **رسوم بيانية تفاعلية**: رسوم بيانية تظهر تكرار التفاعل
- **تتبع التقدم**: مراقبة التحسن بمرور الوقت
- **صحة العلاقات**: تسجيل صحة العلاقات المدعوم بالذكاء الاصطناعي
- **تحليل الاتجاهات**: تحديد الأنماط ومجالات التحسين
- **تصدير التقارير**: تنزيل تقارير التواصل الأسري

### 🤖 المميزات المدعومة بالذكاء الاصطناعي
- **تحليل العلاقات**: رؤى ذكاء اصطناعي حول صحة العلاقات
- **اقتراحات الهدايا**: اقتراحات هدايا مخصصة بناءً على التفضيلات
- **نصوص التواصل**: نصوص بداية محادثة ومخططات مولدة بالذكاء الاصطناعي
- **التقارير الأسبوعية**: ملخصات التواصل الأسري المولدة بالذكاء الاصطناعي
- **الاقتراحات الذكية**: اقتراحات مدركة للسياق لتعزيز الروابط

### 🎨 واجهة مستخدم جميلة
- **تصميم عصري بأسلوب الزجاج**: تصميم بصري أنيق وعصري
- **رسوم متحركة سلسة**: انتقالات سلسة وتفاعلات دقيقة
- **دعم RTL**: دعم كامل من اليمين إلى اليسار للغة العربية
- **سمات فاتحة/داكنة**: خيارات سمات متعددة
- **تصميم متجاوب**: محسن لجميع أحجام الشاشات
- **إمكانية الوصول**: دعم المستخدمين ذوي الإعاقة

### 🔒 الأمان والخصوصية
- **مصادقة آمنة**: خيارات تسجيل الدخول بالبريد الإلكتروني والاجتماعي
- **دعم بيومتري**: مصادقة بصمة الإصبع والتعرف على الوجه
- **تشفير البيانات**: تشفير من طرف إلى طرف للبيانات الحساسة
- **عناصر تحكم الخصوصية**: إعدادات خصوصية وتحكمات مفصلة
- **التزام GDPR**: امتثال كامل مع لوائح حماية البيانات

### 📱 دعم متعدد المنصات
- **iOS أصلي**: محسن لـ iPhone و iPad
- **Android أصلي**: محسن لهواتف وأجهزة Android
- **تطبيق ويب**: نسخة ويب كاملة الميزات
- **دعم بدون اتصال**: ميزات أساسية متاحة بدون إنترنت
- **مزامنة عبر الأجهزة**: مزامنة سلسة بين الأجهزة

## لقطات الشاشة

<div align="center">
  <img src="screenshots/home_screen.png" alt="الشاشة الرئيسية" width="200"/>
  <img src="screenshots/family_tree.png" alt="شجرة العائلة" width="200"/>
  <img src="screenshots/reminders.png" alt="التذكيرات" width="200"/>
  <img src="screenshots/statistics.png" alt="الإحصائيات" width="200"/>
  <img src="screenshots/ai_features.png" alt="مميزات الذكاء الاصطناعي" width="200"/>
  <img src="screenshots/gamification.png" alt="التحفيز" width="200"/>
</div>

## التثبيت

### المتطلبات الأساسية
- **Flutter SDK**: 3.10.1 أو أحدث
- **Dart SDK**: 3.10.1 أو أحدث (مضمن مع Flutter)
- **دعم المنصات**: iOS 12+، Android API 21+، المتصفحات الحديثة
- **التخزين**: 100MB مساحة متوفرة
- **الشبكة**: اتصال بالإنترنت للإعداد الأولي والمزامنة

### البدء السريع

#### الخيار 1: التنزيل من متاجر التطبيقات

**متجر App**
1. افتح متجر التطبيقات على جهاز iOS الخاص بك
2. ابحث عن "Silni" أو امسح رمز QR ضوئي
3. اضغط على "Get" للتنزيل والتثبيت
4. افتح التطبيق واتبع تعليمات الإعداد

**متجر Google Play**
1. افتح متجر Google Play على جهاز Android الخاص بك
2. ابحث عن "Silni" أو امسح رمز QR ضوئي
3. اضغط على "Install" للتنزيل والتثبيت
4. افتح التطبيق واتبع تعليمات الإعداد

#### الخيار 2: البناء من المصدر

```bash
# استنساخ المستودع
git clone https://github.com/your-org/silni_app.git
cd silni_app

# تثبيت الاعتماديات
flutter pub get

# توليد ملفات البيئة
flutter pub run build_runner build

# نسخ تكوين البيئة
cp .env.example .env
# تحرير .env بتكوينك

# تشغيل التطبيق
flutter run
```

### تكوين البيئة

أنشئ ملف `.env` في جذر المشروع:

```bash
# بيئة التطبيق
APP_ENV=development
ENVIRONMENT=development

# تكوين Supabase
SUPABASE_STAGING_URL=your_supabase_url
SUPABASE_STAGING_ANON_KEY=your_supabase_anon_key

# تكوين Firebase
FIREBASE_PROJECT_ID=your_firebase_project_id
FCM_SERVER_KEY=your_fcm_server_key

# تكوين المراقبة
SENTRY_DSN=your_sentry_dsn

# أعلام الميزات
ENABLE_AI_FEATURES=true
ENABLE_PREMIUM_FEATURES=true
ENABLE_ANALYTICS=true
```

## الاستخدام

### البدء

1. **إنشاء حساب**: سجل بالبريد الإلكتروني أو تسجيل الدخول الاجتماعي
2. **إضافة أفراد العائلة**: استيراد من جهات الاتصال أو إضافة يدوياً
3. **إعداد التذكيرات**: تكوين جداول التذكيرات لكل فرد من العائلة
4. **بدء التواصل**: سجل التفاعلات وتتبع التواصل
5. **استكشاف الميزات**: اكتشف رؤى الذكاء الاصطناعي، والتحفيز، والإحصائيات

### سير العمل الأساسي

#### إضافة أفراد العائلة
1. اضغط على زر "إضافة قريب"
2. املأ تفاصيل فرد العائلة
3. حدد نوع العلاقة والأولوية
4. أضف معلومات الاتصال والتفضيلات
5. احفظ وابدأ تتبع التفاعلات

#### إعداد التذكيرات
1. اذهب إلى قسم التذكيرات
2. اضغط على "إنشاء جدول"
3. حدد أفراد العائلة والتكرار
4. اضبط الوقت المفضل والرسالة
5. فعّل الإشعارات واحفظ

#### تتبع التفاعلات
1. اذهب إلى ملف تعريف فرد العائلة
2. اضغط على "تسجيل تفاعل"
3. حدد نوع التفاعل (مكالمة، زيارة، رسالة، إلخ)
4. أضف التفاصيل وملاحظات اختيارية
5. احفظ لتحديث الإحصائيات والسلاسل

#### استخدام ميزات الذكاء الاصطناعي
1. اذهب إلى قسم المساعد الذكاء الاصطناعي
2. اختر الميزة (تحليل، نصوص، توصيات)
3. حدد فرد العائلة والسياق
4. راجع الرؤى المولدة بالذكاء الاصطناعي
5. طبق التوصيات لتعزيز العلاقات

---

<div align="center">

**صُنع بحب ❤️ للأمة المسلمة**

[⭐ إعطاء نجمة للمستودع](https://github.com/your-org/silni_app) | [🐛 الإبلاغ عن مشاكل](https://github.com/your-org/silni_app/issues) | [📖 قراءة التوثيق](docs/)

</div>
