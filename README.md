# صِلْني - Silni | Family Connection Tracker

<div align="center">
  <img src="assets/images/silni_logo.svg" alt="Silni Logo" width="200"/>
  
  **A dramatic Islamic family connection tracker with stunning UI/UX**
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
  
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
- [Contributing](#contributing)
- [License](#license)

## About

**Silni** (صِلْني) is a beautiful Islamic family connection tracker designed to help Muslims maintain strong family ties (صلة الرحم). The app combines modern technology with Islamic values to encourage regular communication with relatives through smart reminders, gamification, and daily Islamic teachings.

The name "Silni" comes from the Arabic concept of "صلة الرحم" (maintaining family ties), which is highly emphasized in Islamic teachings as a means of earning blessings in both this life and the hereafter.

## Features

### 🌳 Family Management
- Add and manage family members with detailed profiles
- Interactive family tree visualization
- Track last contact dates and communication history
- Import contacts from your phone

### ⏰ Smart Reminders
- Intelligent reminder system based on relationship priority
- Customizable reminder schedules
- Notification system with Islamic greetings
- Track upcoming birthdays and special occasions

### 📿 Islamic Content
- Daily hadith and Islamic teachings
- Inspirational Quranic verses about family ties
- Islamic quotes and wisdom about maintaining relationships
- Prayer times integration (planned feature)

### 🏆 Gamification
- Earn points for maintaining family connections
- Achievement badges for consistent communication
- Streak tracking for regular contact
- Level progression system
- Statistics and progress tracking

### 📊 Analytics & Insights
- Detailed statistics about family communication patterns
- Visual charts showing interaction frequency
- Progress tracking over time
- Insights into relationship health

### 🎨 Beautiful UI/UX
- Modern glassmorphic design
- Smooth animations and transitions
- RTL (Right-to-Left) support for Arabic
- Dark/Light theme options
- Responsive design for all screen sizes

## Screenshots

<div align="center">
  <img src="screenshots/home_screen.png" alt="Home Screen" width="200"/>
  <img src="screenshots/family_tree.png" alt="Family Tree" width="200"/>
  <img src="screenshots/reminders.png" alt="Reminders" width="200"/>
  <img src="screenshots/statistics.png" alt="Statistics" width="200"/>
</div>

## Installation

### Prerequisites
- Flutter SDK (>= 3.10.1)
- Dart SDK
- Android Studio / Xcode
- Git

### Clone the repository
```bash
git clone https://github.com/yourusername/silni_app.git
cd silni_app
```

### Install dependencies
```bash
flutter pub get
```

### Environment setup
1. Copy `.env.example` to `.env`
2. Fill in your environment variables:
   ```
   SUPABASE_STAGING_URL=your_supabase_url
   SUPABASE_STAGING_ANON_KEY=your_supabase_anon_key
   SENTRY_DSN=your_sentry_dsn
   ```

### Run the app
```bash
# For development
flutter run

# For release build
flutter build apk    # Android
flutter build ios    # iOS
```

## Usage

1. **Sign Up**: Create an account with email or social login
2. **Add Family Members**: Start by adding your immediate family members
3. **Set Reminders**: Configure reminders for each family member
4. **Track Interactions**: Log your communications to maintain streaks
5. **Earn Rewards**: Progress through levels and unlock achievements
6. **View Insights**: Analyze your family connection patterns

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## Tech Stack

- **Frontend**: Flutter
- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Real-time**: Supabase Realtime
- **Push Notifications**: Firebase Cloud Messaging
- **Analytics**: Sentry
- **Storage**: Supabase Storage

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Arabic | [English](#english)

## جدول المحتويات
- [حول التطبيق](#حول-التطبيق)
- [المميزات](#المميزات)
- [لقطات الشاشة](#لقطات-الشاشة)
- [التثبيت](#التثبيت)
- [الاستخدام](#الاستخدام)
- [المساهمة](#المساهمة)
- [الرخصة](#الرخصة)

## حول التطبيق

**صِلْني** هو تطبيق إسلامي جميل لتتبع روابط العائلة، مصمم لمساعدة المسلمين على الحفاظ على روابط عائلية قوية (صلة الرحم). يجمع التطبيق بين التكنولوجيا الحديثة والقيم الإسلامية لتشجيع التواصل المنتظم مع الأقارب من خلال التذكيرات الذكية، والتحفيز، والتعاليم الإسلامية اليومية.

اسم "صِلْني" مشتق من المفهوم الإسلامي "صلة الرحم"، الذي يُؤكد عليه بشدة في التعاليم الإسلامية كوسيلة لكسب البركات في الحياة الدنيا والآخرة.

## المميزات

### 🌳 إدارة العائلة
- إضافة وإدارة أفراد العائلة بملفات تعريف مفصلة
- شجرة عائلة تفاعلية
- تتبع تواريخ آخر تواصل وسجل الاتصال
- استيراد جهات الاتصال من هاتفك

### ⏰ التذكيرات الذكية
- نظام تذكير ذكي يعتمد على أولوية العلاقة
- جداول تذكير قابلة للتخصيص
- نظام إشعارات بتحيات إسلامية
- تتبع أعياد الميلاد والمناسبات الخاصة القادمة

### 📿 المحتوى الإسلامي
- حديث نبوي يومي وتعاليم إسلامية
- آيات قرآنية ملهمة عن روابط العائلة
- اقتباسات وحكم إسلامية عن الحفاظ على العلاقات
- تكامل أوقات الصلاة (ميزة مخطط لها)

### 🏆 التحفيز
- اكسب نقاط للحفاظ على روابط العائلة
- شارات الإنجاز للتواصل المنتظم
- تتبع السلاسل للاتصال المنتظم
- نظام تقدم المستويات
- إحصائيات وتتبع التقدم

### 📊 التحليلات والرؤى
- إحصائيات مفصلة عن أنماط التواصل العائلي
- رسوم بيانية مرئية تظهر تكرار التفاعل
- تتبع التقدم بمرور الوقت
- رؤى حول صحة العلاقات

### 🎨 واجهة مستخدم جميلة
- تصميم عصري بأسلوب الزجاج
- رسوم متحركة سلسة وانتقالات
- دعم RTL (من اليمين إلى اليسار) للغة العربية
- خيارات الوضع الليلي/النهاري
- تصميم متجاوب لجميع أحجام الشاشات

## لقطات الشاشة

<div align="center">
  <img src="screenshots/home_screen.png" alt="الشاشة الرئيسية" width="200"/>
  <img src="screenshots/family_tree.png" alt="شجرة العائلة" width="200"/>
  <img src="screenshots/reminders.png" alt="التذكيرات" width="200"/>
  <img src="screenshots/statistics.png" alt="الإحصائيات" width="200"/>
</div>

## التثبيت

### المتطلبات الأساسية
- Flutter SDK (>= 3.10.1)
- Dart SDK
- Android Studio / Xcode
- Git

### استنساخ المستودع
```bash
git clone https://github.com/yourusername/silni_app.git
cd silni_app
```

### تثبيت الاعتماديات
```bash
flutter pub get
```

### إعداد البيئة
1. انسخ `.env.example` إلى `.env`
2. املأ متغيرات البيئة الخاصة بك:
   ```
   SUPABASE_STAGING_URL=your_supabase_url
   SUPABASE_STAGING_ANON_KEY=your_supabase_anon_key
   SENTRY_DSN=your_sentry_dsn
   ```

### تشغيل التطبيق
```bash
# للتطوير
flutter run

# للبناء الإنتاجي
flutter build apk    # Android
flutter build ios    # iOS
```

## الاستخدام

1. **التسجيل**: أنشئ حسابًا بالبريد الإلكتروني أو تسجيل الدخول الاجتماعي
2. **إضافة أفراد العائلة**: ابدأ بإضافة أفراد عائلتك المباشرين
3. **ضبط التذكيرات**: قم بتكوين التذكيرات لكل فرد من أفراد العائلة
4. **تتبع التفاعلات**: سجل اتصالاتك للحفاظ على السلاسل
5. **كسب المكافآت**: تقدم عبر المستويات وفتح الإنجازات
6. **عرض الرؤى**: حلل أنماط اتصال عائلتك

## المساهمة

نرحب بالمساهمات! يرجى الاطلاع على [دليل المساهمة](CONTRIBUTING.md) للحصول على التفاصيل.

### إعداد التطوير
1. انسخ المستودع
2. أنشئ فرع ميزة: `git checkout -b feature/amazing-feature`
3. قم بتنفيذ تغييراتك: `git commit -m 'Add amazing feature'`
4. ادفع إلى الفرع: `git push origin feature/amazing-feature`
5. افتح طلب سحب

## التقنيات المستخدمة

- **الواجهة الأمامية**: Flutter
- **إدارة الحالة**: Riverpod
- **الخلفية**: Supabase (PostgreSQL)
- **المصادقة**: Supabase Auth
- **الوقت الفعلي**: Supabase Realtime
- **الإشعارات المدفوعة**: Firebase Cloud Messaging
- **التحليلات**: Sentry
- **التخزين**: Supabase Storage

## الرخصة

هذا المشروع مرخص تحت رخصة MIT - راجع ملف [LICENSE](LICENSE) للتفاصيل.

---

<div align="center">
  Made with ❤️ for the Muslim Ummah
</div>
