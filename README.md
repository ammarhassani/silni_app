# صِلْني - Silni

<div align="center">
  <img src="assets/images/app_icon.png" alt="Silni Logo" width="150" style="border-radius: 30px;"/>

  **تطبيق إسلامي لتعزيز صلة الرحم**

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
  [![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)](#)

  [الموقع](https://ammarhassani.github.io/silni_app/) | [سياسة الخصوصية](https://ammarhassani.github.io/silni_app/privacy-policy-ar.html) | [الشروط والأحكام](https://ammarhassani.github.io/silni_app/terms-ar.html)
</div>

---

## حول التطبيق

**صِلْني** تطبيق مصمم لمساعدة المسلمين على الحفاظ على صلة الرحم من خلال:

- تتبع التواصل مع الأقارب
- تذكيرات ذكية للتواصل
- شجرة عائلة تفاعلية
- مساعد ذكاء اصطناعي للعلاقات
- نظام تحفيز بالنقاط والشارات

---

## المميزات

### الباقة المجانية
- إدارة الأقارب وتتبع التواصل
- شجرة العائلة التفاعلية
- 3 تذكيرات مجدولة
- السمات المخصصة
- نظام النقاط والشارات
- المحتوى الإسلامي اليومي

### باقة MAX
كل مميزات الباقة المجانية بالإضافة إلى:
- مساعد الذكاء الاصطناعي
- كاتب الرسائل الذكي
- سيناريوهات التواصل
- تحليل العلاقات
- تذكيرات غير محدودة
- التقارير الأسبوعية

---

## التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|-----------|
| Flutter | تطوير التطبيق |
| Riverpod | إدارة الحالة |
| Supabase | قاعدة البيانات والمصادقة |
| Firebase | الإشعارات والتحليلات |
| RevenueCat | إدارة الاشتراكات |
| DeepSeek | الذكاء الاصطناعي |

---

## البنية المعمارية

```
lib/
├── core/                 # الخدمات والثوابت الأساسية
│   ├── ai/              # محرك الذكاء الاصطناعي
│   ├── constants/       # الثوابت والألوان
│   ├── models/          # نماذج البيانات
│   ├── providers/       # مزودات Riverpod
│   ├── services/        # الخدمات الأساسية
│   └── theme/           # السمات والتصميم
├── features/            # ميزات التطبيق
│   ├── ai_assistant/    # المساعد الذكي
│   ├── auth/            # المصادقة
│   ├── family_tree/     # شجرة العائلة
│   ├── gamification/    # النقاط والشارات
│   ├── home/            # الشاشة الرئيسية
│   ├── notifications/   # الإشعارات
│   ├── profile/         # الملف الشخصي
│   ├── relatives/       # إدارة الأقارب
│   ├── reminders/       # التذكيرات
│   ├── settings/        # الإعدادات
│   └── subscription/    # الاشتراكات
└── shared/              # المكونات المشتركة
    ├── services/        # خدمات مشتركة
    ├── utils/           # أدوات مساعدة
    └── widgets/         # عناصر واجهة مشتركة
```

---

## التشغيل المحلي

### المتطلبات
- Flutter SDK 3.10+
- Dart SDK 3.10+
- Xcode (لنظام iOS)

### الخطوات

```bash
# استنساخ المستودع
git clone https://github.com/AmmarHassani/silni_app.git
cd silni_app

# تثبيت الاعتماديات
flutter pub get

# توليد الملفات
dart run build_runner build --delete-conflicting-outputs

# إعداد ملف البيئة
cp .env.example .env
# قم بتعديل .env بإعداداتك

# تشغيل التطبيق
flutter run
```

---

## الخدمات الخارجية

يستخدم التطبيق الخدمات التالية:

- **Supabase** - قاعدة البيانات والمصادقة
- **Firebase** - الإشعارات والتحليلات
- **RevenueCat** - إدارة الاشتراكات
- **DeepSeek API** - الذكاء الاصطناعي
- **Cloudinary** - تخزين الصور

---

## التواصل

- **البريد الإلكتروني**: silniapp@outlook.com
- **الموقع**: [ammarhassani.github.io/silni_app](https://ammarhassani.github.io/silni_app/)

---

## الترخيص

جميع الحقوق محفوظة © 2025 صِلْني

---

<div align="center">

**صُنع بـ ❤️ لتعزيز صلة الرحم**

</div>
