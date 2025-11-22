# 🕌 صِلْني - مستند المشروع الشامل (PRD)

## 📋 جدول المحتويات
1. [نظرة عامة](#نظرة-عامة)
2. [الرؤية والأهداف](#الرؤية-والأهداف)
3. [الجوانب الشرعية](#الجوانب-الشرعية)
4. [المستخدمون المستهدفون](#المستخدمون-المستهدفون)
5. [الميزات الكاملة](#الميزات-الكاملة)
6. [التقنيات المستخدمة](#التقنيات-المستخدمة)
7. [هيكل قاعدة البيانات](#هيكل-قاعدة-البيانات)
8. [تصميم UI/UX](#تصميم-uiux)
9. [User Flows](#user-flows)
10. [الأمان والخصوصية](#الأمان-والخصوصية)
11. [نموذج الأعمال](#نموذج-الأعمال)
12. [خطة التطوير](#خطة-التطوير)
13. [KPIs ومقاييس النجاح](#kpis-ومقاييس-النجاح)
14. [المخاطر والتحديات](#المخاطر-والتحديات)

---

## 1. نظرة عامة {#نظرة-عامة}

### 1.1 اسم المشروع
**صِلْني** (Silni)

### 1.2 الوصف المختصر
تطبيق جوال يساعد المسلمين على تنظيم وتتبع صلة الرحم بطريقة عملية وممتعة، مع تذكيرات ذكية وإحصائيات تحفيزية.

### 1.3 المشكلة التي نحلها
- **قطيعة الرحم**: كثير من المسلمين يريدون صلة أرحامهم لكن ينسون أو يهملون
- **عدم التنظيم**: صعوبة تتبع آخر تواصل مع كل قريب
- **النسيان**: عدم تذكر المناسبات المهمة
- **عدم الوعي**: عدم معرفة حدود صلة الرحم الشرعية

### 1.4 الحل
تطبيق شامل لإدارة صلة الرحم مع:
- 📱 واجهة سهلة وجميلة
- 🔔 تذكيرات ذكية مخصصة
- 📊 تتبع وإحصائيات محفزة
- 📚 محتوى تعليمي شرعي
- 🎮 عناصر تحفيزية (gamification)

### 1.5 المنصات
- ✅ iOS (iPhone/iPad)
- ✅ Android (Phones/Tablets)
- 🔄 Web (مستقبلاً)

### 1.6 اللغات
- **Phase 1**: العربية فقط
- **Phase 2**: الإنجليزية والأردية

---

## 2. الرؤية والأهداف {#الرؤية-والأهداف}

### 2.1 الرؤية (Vision)
> "أن نكون التطبيق الأول في العالم الإسلامي لتسهيل وتحفيز صلة الرحم، ونساهم في تقوية الروابط الأسرية في المجتمعات الإسلامية"

### 2.2 الرسالة (Mission)
> "نساعد المسلمين على تنظيم صلة أرحامهم بطريقة عملية، مع احتساب الأجر من الله تعالى، من خلال تطبيق سهل الاستخدام ومحفز"

### 2.3 الأهداف الاستراتيجية

#### أهداف دينية:
- 🕌 تسهيل عبادة صلة الرحم على المسلمين
- 📖 نشر الوعي بأحكام صلة الرحم
- 💚 تقوية الروابط الأسرية في المجتمع
- 🤲 صدقة جارية لمطوري التطبيق ومستخدميه

#### أهداف قابلة للقياس:
- **السنة الأولى**: 100,000 مستخدم نشط
- **السنة الثانية**: 500,000 مستخدم
- **السنة الثالثة**: 1,000,000 مستخدم
- **معدل الاشتراكات**: 5-10% من المستخدمين

#### أهداف الاسترزاق:
- 💰 تحقيق دخل حلال من الاشتراكات
- 📈 استدامة التطبيق وتطويره المستمر
- 💼 توظيف فريق لتطوير التطبيق (مستقبلاً)

---

## 3. الجوانب الشرعية {#الجوانب-الشرعية}

### 3.1 حكم صلة الرحم

#### 3.1.1 الرحم الواجبة (إجماعاً)
**كل ذي رحم محرم** - وهم الأقارب الذين لا يجوز الزواج بينهم:
- **الأصول**: الآباء، الأمهات، الأجداد، الجدات (من الطرفين)
- **الفروع**: الأبناء، البنات، الأحفاد، الحفيدات
- **الحواشي المحرمة**:
  - الإخوة والأخوات (أشقاء، من الأب، من الأم)
  - الأعمام والعمات
  - الأخوال والخالات

**المصدر الشرعي**:
> قال العلماء: "الرحم المحرمة هي كل شخصين لو كان أحدهما ذكراً والآخر أنثى حرمت مناكحتهما"

#### 3.1.2 الرحم المستحبة (خلاف بين العلماء)
**أولاد الأعمام والأخوال**:
- أبناء وبنات الأعمام والعمات
- أبناء وبنات الأخوال والخالات
- أبناء وبنات الإخوة والأخوات
- أقارب أبعد

**الخلاف الفقهي**:
- **القول الأول** (الراجح عند إسلام ويب): صلتهم مستحبة، وليست واجبة
- **القول الثاني** (المشهور عند المالكية والحنابلة): صلتهم واجبة أيضاً

**قرارنا في التطبيق**:
✅ **نجعل كل الأقارب (واجبة + مستحبة) في النسخة المجانية**
- خروجاً من الخلاف الفقهي
- لئلا نحجب عن أحد صلة قريب قد تكون واجبة
- الأجر أعظم بإذن الله

### 3.2 حكم أخذ مقابل على التطبيق

#### 3.2.1 الأدلة الشرعية
**يجوز أخذ الأجرة على الأعمال المتعدية النفع**:
> "يجوز أخذ الأجرة على تعليم العلم الشرعي، في قول جمهور الفقهاء، مقابل ما حصل للغير من منفعة"
> (المصدر: إسلام ويب، فتوى رقم 134154)

**التطبيق ينطبق عليه نفس الحكم**:
- ✅ جهد برمجي (ساعات عمل، تخطيط، تطوير)
- ✅ تكاليف حقيقية (استضافة، صيانة، تحديثات)
- ✅ خدمة مستمرة (دعم فني، إصلاح أخطاء)
- ✅ ينفع الناس في طاعة عظيمة

#### 3.2.2 الشروط الشرعية
1. ✅ النية الصالحة (نفع المسلمين + رزق حلال)
2. ✅ عدم حجب الأساسيات عن أحد
3. ✅ السعر معقول وليس استغلالاً
4. ✅ الشفافية في الهدف

#### 3.2.3 ما نفعله في التطبيق
- ✅ كل ميزات صلة الرحم: **مجانية للأبد**
- ✅ الميزات المتقدمة فقط: **اشتراك اختياري**
- ✅ نص واضح: "هذا مشروع خيري، المبلغ لتغطية التكاليف والتطوير"
- ✅ تخصيص نسبة للصدقة (10-20% من الأرباح)

### 3.3 المراجع الشرعية
- إسلام ويب - مركز الفتوى
- موقع الشيخ ابن باز
- الإسلام سؤال وجواب (إسلام كيو آي)
- فتاوى اللجنة الدائمة

---

## 4. المستخدمون المستهدفون {#المستخدمون-المستهدفون}

### 4.1 User Personas

#### Persona 1: "أحمد" - الموظف المشغول
- **العمر**: 28-40
- **المهنة**: موظف في القطاع الخاص
- **الحالة**: متزوج، لديه أطفال
- **المشكلة**: مشغول بالعمل، ينسى التواصل مع أقاربه
- **الهدف**: تنظيم وقته لصلة الرحم
- **الاستخدام**: يومي، تذكيرات قوية

#### Persona 2: "فاطمة" - ربة المنزل
- **العمر**: 25-45
- **المهنة**: ربة منزل
- **الحالة**: متزوجة، لديها أطفال
- **المشكلة**: صلة رحم زوجها + رحمها، كثيرة ومعقدة
- **الهدف**: تنظيم العلاقات الأسرية وعدم نسيان أحد
- **الاستخدام**: يومي، تتبع دقيق

#### Persona 3: "خالد" - الشاب الجامعي
- **العمر**: 18-25
- **المهنة**: طالب جامعي
- **الحالة**: أعزب
- **المشكلة**: مشغول بالدراسة، بعيد عن الأهل
- **الهدف**: البر بوالديه وصلة رحمه رغم البعد
- **الاستخدام**: أسبوعي، تذكيرات بسيطة

#### Persona 4: "سارة" - المرأة العاملة
- **العمر**: 25-40
- **المهنة**: طبيبة/مهندسة/معلمة
- **الحالة**: متزوجة أو عزباء
- **المشكلة**: التوازن بين العمل والحياة الشخصية
- **الهدف**: صلة الرحم بطريقة منظمة وفعالة
- **الاستخدام**: أسبوعي، إحصائيات محفزة

### 4.2 السوق المستهدف

#### السوق الأولي:
- 🇸🇦 **السعودية**: 35 مليون نسمة، 70% iPhone users
- 🇦🇪 **الإمارات**: 10 مليون نسمة
- 🇰🇼 **الكويت**: 4 مليون نسمة
- 🇶🇦 **قطر**: 3 مليون نسمة

**التقدير**:
- **إجمالي السوق الأولي**: 50 مليون نسمة
- **المستخدمون المحتملون** (20%): 10 مليون
- **الهدف السنة الأولى**: 100,000 مستخدم (1%)

#### السوق الثانوي (Phase 2):
- 🇪🇬 مصر
- 🇵🇰 باكستان
- 🇹🇷 تركيا
- 🇲🇾 ماليزيا
- 🇮🇩 إندونيسيا

---

## 5. الميزات الكاملة {#الميزات-الكاملة}

### 5.1 النسخة المجانية (Free Forever) 🆓

#### 5.1.1 إدارة الأقارب
- ✅ **إضافة عدد لا محدود** من الأقارب
- ✅ المعلومات الأساسية:
  - الاسم الكامل
  - العلاقة (أب، أم، أخ، عم، خال...)
  - رقم الجوال
  - صورة الملف الشخصي
- ✅ **التصنيف التلقائي** حسب نوع العلاقة
- ✅ **الفلترة والبحث** السريع
- ✅ عرض القائمة بطرق مختلفة (حسب العلاقة، حسب آخر تواصل)

#### 5.1.2 التذكيرات
- ✅ **تذكير يومي واحد** (وقت يحدده المستخدم)
- ✅ تذكير بالمناسبات العامة:
  - الأعياد (فطر، أضحى)
  - رمضان
  - يوم الجمعة
- ✅ **إشعارات أساسية**:
  - "لم تتصل بوالدتك منذ 3 أيام"
  - "حان وقت زيارة جدك"

#### 5.1.3 التتبع والسجل
- ✅ **تسجيل التواصل**:
  - نوع التواصل (اتصال، زيارة، رسالة، هدية)
  - التاريخ والوقت
  - ملاحظة قصيرة (اختياري)
- ✅ **عرض آخر 30 تواصل**
- ✅ **حساب أيام منذ آخر تواصل** لكل قريب

#### 5.1.4 الإحصائيات الأساسية
- ✅ **شاشة إحصائيات شهرية**:
  - عدد الاتصالات هذا الشهر
  - عدد الزيارات
  - أكثر قريب تواصلت معه
  - من أهملته هذا الشهر
- ✅ **Progress Bar** بسيط لكل قريب

#### 5.1.5 المحتوى التعليمي
- ✅ **حديث يومي** عن فضل صلة الرحم
- ✅ **دليل مبسط** عن أحكام صلة الرحم
- ✅ **قصص قصيرة** محفزة (5-10 قصص)
- ✅ **أسئلة وأجوبة** شائعة

#### 5.1.6 الواجهة
- ✅ **ثيم واحد جميل** (Light Mode)
- ✅ الخط العربي الأساسي (واضح ومريح)
- ✅ أيقونات واضحة

### 5.2 النسخة البريميوم (Premium) 👑

**السعر**: 7.99 ريال/شهر أو 79.99 ريال/سنة (وفّر 16 ريال!)

#### 5.2.1 إدارة متقدمة للأقارب
- 🌟 **معلومات موسعة**:
  - تاريخ الميلاد (تذكير تلقائي)
  - العنوان الكامل
  - البريد الإلكتروني
  - أكثر من رقم جوال
  - حسابات التواصل الاجتماعي
  - **ملاحظات مفصلة** (نص طويل)
  - **مواعيد مهمة** مخصصة (ذكرى زواج، تخرج، إلخ)
- 🌟 **شجرة العائلة التفاعلية** (Visualized Family Tree)
- 🌟 **العلاقات المعقدة**:
  - زوجة الأخ، زوج الأخت
  - أصهار
  - علاقات ممتدة
- 🌟 **المجموعات المخصصة**:
  - "عائلة أبي"
  - "عائلة أمي"
  - "الأقارب القريبون"
  - مجموعات مخصصة

#### 5.2.2 التذكيرات الذكية
- 🌟 **تذكيرات متعددة** في اليوم (لا محدودة)
- 🌟 **تذكيرات مخصصة لكل قريب**:
  - "اتصل بوالدتك كل صباح"
  - "زر جدك كل جمعة"
  - "أرسل رسالة لخالك كل أسبوعين"
- 🌟 **تذكيرات ذكية** بناءً على السلوك:
  - "لم تتصل بعمك منذ شهرين، حان الوقت!"
  - "والدتك عيد ميلادها بعد 3 أيام"
- 🌟 **اقتراحات** لطرق التواصل:
  - "جربت تزور بدل الاتصال؟"
  - "ماذا عن هدية بسيطة؟"
- 🌟 **تذكيرات المناسبات**:
  - أعياد الميلاد
  - ذكرى الزواج
  - التخرج
  - مناسبات مخصصة

#### 5.2.3 التتبع المتقدم
- 🌟 **سجل كامل** لكل التواصلات (لا محدود)
- 🌟 **ملاحظات تفصيلية**:
  - نص طويل
  - صور
  - audio notes (تسجيل صوتي)
- 🌟 **تصنيف التواصل**:
  - جودة التواصل (ممتاز، جيد، متوسط)
  - الحالة النفسية للقريب
  - احتياجات لاحظتها
- 🌟 **Reminders للمتابعة**:
  - "عمك قال عنده موعد طبيب، تابع معه"

#### 5.2.4 الإحصائيات والتحليلات المتقدمة
- 🌟 **Dashboard فخم** مع:
  - رسوم بيانية جميلة (Charts)
  - Heatmap للتواصل
  - Trends عبر الزمن
- 🌟 **إحصائيات متقدمة**:
  - يومية / أسبوعية / شهرية / سنوية
  - مقارنة بين الفترات
  - توقعات (Predictions)
- 🌟 **Streak Counter** (أيام متتالية)
- 🌟 **Insights ذكية**:
  - "تواصلك مع والدتك زاد 40% هذا الشهر! 💚"
  - "لم تتصل بخالك منذ 45 يوم، الأطول منذ سنة"
- 🌟 **التقارير**:
  - تقرير شهري مفصل
  - تقرير سنوي (Year in Review)
  - تصدير PDF/Excel

#### 5.2.5 Gamification (التحفيز)
- 🌟 **نظام الشارات** (Badges):
  - 🏆 "واصل الرحم الذهبي" (365 يوم متتالي)
  - ⭐ "البار بوالديه" (تواصل يومي مع الوالدين لشهر)
  - 💪 "المتواصل المستمر" (30 يوم streak)
  - 🎖️ "صلة العائلة" (تواصل مع 10 أقارب في أسبوع)
  - 🌟 "رحمة للعالمين" (1000 تواصل)
- 🌟 **نظام المستويات**:
  - Level 1: البداية
  - Level 5: المواظب
  - Level 10: الواصل
  - Level 20: الملتزم
  - Level 50: النجم
- 🌟 **التحديات**:
  - تحديات يومية
  - تحديات أسبوعية
  - تحديات شهرية
  - تحديات موسمية (رمضان، الحج...)
- 🌟 **الإنجازات** (Achievements):
  - "أول مكالمة!"
  - "10 مكالمات"
  - "أول زيارة"
  - "شهر كامل من التواصل"

#### 5.2.6 النسخ الاحتياطي والمزامنة
- 🌟 **Cloud Backup** تلقائي يومي
- 🌟 **المزامنة عبر الأجهزة**:
  - iPhone + iPad
  - Android + Tablet
  - Web (مستقبلاً)
- 🌟 **استرجاع البيانات**:
  - في أي وقت
  - Restore لتاريخ معين
- 🌟 **تصدير البيانات**:
  - JSON
  - CSV
  - PDF Report

#### 5.2.7 التخصيص والثيمات
- 🌟 **ثيمات متعددة**:
  - Light Mode (فاتح)
  - Dark Mode (داكن)
  - Islamic Theme (ذهبي/أخضر)
  - Modern Theme (عصري)
- 🌟 **خطوط عربية جميلة**:
  - خط النسخ
  - خط الثلث
  - خطوط حديثة
- 🌟 **تخصيص الألوان**:
  - اللون الرئيسي
  - لون التأكيد
  - ألوان الفئات
- 🌟 **تخصيص الأيقونات**:
  - Icon Packs مختلفة

#### 5.2.8 ميزات إضافية
- 🌟 **Widget** للشاشة الرئيسية:
  - آخر قريب تواصلت معه
  - من يحتاج تواصل اليوم
  - Streak counter
- 🌟 **Siri Shortcuts** (iOS):
  - "Siri، سجل اتصال بوالدتي"
  - "Siri، من أهملت هذا الأسبوع؟"
- 🌟 **Apple Watch App**:
  - عرض التذكيرات
  - تسجيل سريع
  - Complications
- 🌟 **مشاركة الإنجازات**:
  - (بدون تفاصيل شخصية)
  - صورة جميلة للمشاركة
- 🌟 **تكامل مع التقويم**:
  - إضافة المناسبات لـ Google/Apple Calendar
- 🌟 **إزالة الإعلانات** (إن وُجدت)
- 🌟 **أولوية الدعم الفني**

### 5.3 الميزات المستقبلية (Roadmap)

#### Phase 3 (بعد 6 أشهر):
- 📞 **تكامل مع تطبيق الهاتف**:
  - تسجيل تلقائي للمكالمات مع الأقارب
- 💬 **تكامل مع WhatsApp**:
  - رصد الرسائل (بإذن المستخدم)
- 🎁 **اقتراحات الهدايا**:
  - بناءً على اهتمامات القريب
  - روابط لمتاجر
- 👥 **Family Groups**:
  - إنشاء مجموعة عائلية
  - مشاركة المناسبات
  - تنسيق الزيارات

#### Phase 4 (بعد سنة):
- 🌍 **Web Version**:
  - متزامن مع الجوال
  - إدارة من المتصفح
- 🤖 **AI Suggestions**:
  - اقتراحات ذكية للتواصل
  - تحليل أنماط التواصل
  - توقع من يحتاج تواصل
- 📸 **Family Photo Album**:
  - ألبوم صور مشترك للعائلة
- 🎤 **Voice Notes**:
  - رسائل صوتية للأقارب

---

## 6. التقنيات المستخدمة {#التقنيات-المستخدمة}

### 6.1 Frontend (Mobile App)

#### Tech Stack:
```
Framework: React Native (with Expo)
Version: React Native 0.73+ / Expo SDK 50+
Language: TypeScript
```

#### Core Libraries:
```javascript
// Navigation
"@react-navigation/native": "^6.1.0"
"@react-navigation/native-stack": "^6.9.0"
"@react-navigation/bottom-tabs": "^6.5.0"

// State Management
"zustand": "^4.5.0"

// UI Components
"react-native-paper": "^5.12.0"
"react-native-vector-icons": "^10.0.0"
"react-native-svg": "^14.1.0"

// Forms & Validation
"react-hook-form": "^7.50.0"
"zod": "^3.22.0"

// Date & Time
"date-fns": "^3.3.0"
"date-fns-jalali": "^3.0.0" // للتقويم الهجري

// Notifications
"expo-notifications": "^0.27.0"
"expo-device": "^5.9.0"

// Storage
"@react-native-async-storage/async-storage": "^1.21.0"

// Charts & Graphs
"react-native-chart-kit": "^6.12.0"
"react-native-svg-charts": "^5.4.0"

// Animations
"react-native-reanimated": "^3.6.0"
"lottie-react-native": "^6.5.0"

// Images
"expo-image-picker": "^14.7.0"
"react-native-fast-image": "^8.6.0"

// Contacts (للاستيراد - optional)
"expo-contacts": "^12.8.0"

// Haptics
"expo-haptics": "^12.8.0"

// Calendar Integration
"expo-calendar": "^12.7.0"
```

### 6.2 Backend & Services

#### Firebase:
```javascript
// Core
"firebase": "^10.8.0"

// Services Used:
- Firebase Authentication (Email/Password, Phone)
- Cloud Firestore (Database)
- Firebase Storage (Images)
- Cloud Messaging (Push Notifications)
- Firebase Analytics
- Firebase Crashlytics
- Firebase Remote Config
```

#### Additional Services:
```
- Expo Application Services (EAS)
  - Build service
  - Submit service
  - Updates (OTA)
  
- RevenueCat (Subscriptions)
  - In-app purchases
  - Subscription management
  - Cross-platform
```

### 6.3 Development Tools

```
- VS Code (IDE)
- Git & GitHub (Version Control)
- Expo CLI (Development)
- EAS CLI (Build & Deploy)
- Postman (API Testing)
- Figma (Design)
- Notion (Project Management)
```

### 6.4 Testing

```
- Jest (Unit Testing)
- React Native Testing Library
- Detox (E2E Testing - optional)
- Manual Testing on:
  - iPhone 15 Pro
  - Android emulator
```

### 6.5 CI/CD

```
- GitHub Actions
  - Automated testing
  - EAS builds on push
  - Code quality checks
  
- EAS Build
  - iOS builds
  - Android builds
  
- EAS Submit
  - App Store
  - Google Play
```

### 6.6 Analytics & Monitoring

```
- Firebase Analytics (User behavior)
- Firebase Crashlytics (Crash reporting)
- Sentry (Error tracking - optional)
- RevenueCat (Revenue analytics)
```

---

## 7. هيكل قاعدة البيانات {#هيكل-قاعدة-البيانات}

### 7.1 Firestore Collections

#### 7.1.1 Users Collection
```javascript
users/{userId}
{
  // Basic Info
  id: string,
  email: string,
  phoneNumber: string | null,
  displayName: string,
  photoURL: string | null,
  
  // Settings
  language: 'ar' | 'en',
  theme: 'light' | 'dark' | 'islamic',
  notificationsEnabled: boolean,
  
  // Subscription
  subscriptionStatus: 'free' | 'premium',
  subscriptionStartDate: timestamp | null,
  subscriptionEndDate: timestamp | null,
  
  // Stats (cached for performance)
  totalRelatives: number,
  totalInteractions: number,
  currentStreak: number,
  longestStreak: number,
  level: number,
  xp: number,
  
  // Metadata
  createdAt: timestamp,
  updatedAt: timestamp,
  lastActiveAt: timestamp,
  
  // Premium Features
  premiumFeatures: {
    cloudBackup: boolean,
    advancedStats: boolean,
    customThemes: boolean,
    // ...
  }
}
```

#### 7.1.2 Relatives Collection
```javascript
users/{userId}/relatives/{relativeId}
{
  // Basic Info
  id: string,
  userId: string, // owner
  fullName: string,
  nickname: string | null,
  photoURL: string | null,
  
  // Relationship
  relationshipType: 'father' | 'mother' | 'brother' | 'sister' | 
                    'uncle' | 'aunt' | 'cousin' | ...,
  relationshipCategory: 'obligatory' | 'recommended', // واجبة أم مستحبة
  side: 'paternal' | 'maternal' | 'both', // من جهة الأب أو الأم
  
  // Contact Info
  phoneNumbers: [
    { type: 'mobile', number: string, isPrimary: boolean }
  ],
  email: string | null,
  address: {
    street: string,
    city: string,
    country: string,
  } | null,
  
  // Social
  socialMedia: {
    whatsapp: string,
    twitter: string,
    // ...
  } | null,
  
  // Important Dates
  birthDate: timestamp | null,
  anniversaries: [
    { name: string, date: timestamp, recurring: boolean }
  ],
  
  // Notes
  notes: string, // Premium feature
  interests: string[],
  healthNotes: string, // "يعاني من السكري"
  
  // Preferences
  preferredContactMethod: 'call' | 'visit' | 'message',
  contactFrequency: 'daily' | 'weekly' | 'monthly', // suggested
  
  // Stats
  totalInteractions: number,
  lastInteractionDate: timestamp | null,
  lastInteractionType: string | null,
  daysSinceLastContact: number,
  
  // Custom Reminders
  customReminders: [
    {
      type: 'call' | 'visit' | 'message',
      frequency: 'daily' | 'weekly' | 'monthly',
      time: string, // "09:00"
      daysOfWeek: number[], // [0,1,2,3,4,5,6]
      enabled: boolean
    }
  ],
  
  // Groups (Premium)
  groups: string[], // ["paternal_family", "close_relatives"]
  
  // Metadata
  createdAt: timestamp,
  updatedAt: timestamp,
  isArchived: boolean,
  sortOrder: number
}
```

#### 7.1.3 Interactions Collection
```javascript
users/{userId}/interactions/{interactionId}
{
  id: string,
  userId: string,
  relativeId: string,
  
  // Interaction Details
  type: 'call' | 'visit' | 'message' | 'gift' | 'event' | 'other',
  date: timestamp,
  duration: number | null, // in minutes (for calls/visits)
  
  // Quality & Sentiment
  quality: 'excellent' | 'good' | 'average' | null, // Premium
  sentiment: 'positive' | 'neutral' | 'negative' | null, // Premium
  
  // Notes
  notes: string,
  tags: string[], // ["birthday", "hospital_visit"]
  
  // Media
  photos: string[], // Storage URLs
  audioNotes: string[], // Storage URLs (Premium)
  
  // Follow-up
  hasFollowUp: boolean,
  followUpDate: timestamp | null,
  followUpNote: string | null,
  
  // Metadata
  createdAt: timestamp,
  updatedAt: timestamp,
  syncStatus: 'synced' | 'pending' | 'failed'
}
```

#### 7.1.4 Reminders Collection
```javascript
users/{userId}/reminders/{reminderId}
{
  id: string,
  userId: string,
  relativeId: string | null, // null for general reminders
  
  // Reminder Details
  type: 'interaction' | 'birthday' | 'anniversary' | 'custom',
  title: string,
  message: string,
  
  // Schedule
  scheduledDate: timestamp,
  scheduledTime: string, // "09:00"
  recurring: boolean,
  recurrence: {
    frequency: 'daily' | 'weekly' | 'monthly' | 'yearly',
    interval: number, // every X days/weeks/months
    endDate: timestamp | null,
    daysOfWeek: number[] | null, // for weekly
    dayOfMonth: number | null, // for monthly
  } | null,
  
  // Status
  status: 'active' | 'completed' | 'dismissed' | 'snoozed',
  completedAt: timestamp | null,
  snoozedUntil: timestamp | null,
  
  // Notification
  notificationId: string | null, // Local notification ID
  notificationSent: boolean,
  
  // Metadata
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### 7.1.5 Achievements Collection
```javascript
users/{userId}/achievements/{achievementId}
{
  id: string,
  userId: string,
  
  // Achievement Details
  type: 'badge' | 'level' | 'streak' | 'milestone',
  achievementId: string, // "golden_connector"
  title: string,
  description: string,
  icon: string,
  
  // Progress
  currentProgress: number,
  targetProgress: number,
  isUnlocked: boolean,
  
  // Reward
  xpReward: number,
  
  // Dates
  unlockedAt: timestamp | null,
  createdAt: timestamp
}
```

#### 7.1.6 Statistics Collection (Aggregated)
```javascript
users/{userId}/statistics/{period}
// period: "2024-03", "2024-W12", "2024-03-15"
{
  id: string, // period
  userId: string,
  periodType: 'daily' | 'weekly' | 'monthly' | 'yearly',
  
  // Counts
  totalInteractions: number,
  interactionsByType: {
    calls: number,
    visits: number,
    messages: number,
    gifts: number,
    other: number
  },
  
  // Relatives
  uniqueRelativesContacted: number,
  mostContactedRelativeId: string,
  leastContactedRelativeIds: string[],
  
  // Streaks
  currentStreak: number,
  streakBroken: boolean,
  
  // Time Analysis
  averageInteractionsPerDay: number,
  busiestDay: string, // "Monday"
  busiestHour: number, // 14 (2 PM)
  
  // Quality (Premium)
  averageQuality: number,
  positiveInteractions: number,
  
  // Generated
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### 7.1.7 Subscriptions Collection
```javascript
users/{userId}/subscriptions/{subscriptionId}
{
  id: string,
  userId: string,
  
  // Subscription Details
  platform: 'ios' | 'android',
  productId: string, // "premium_monthly"
  purchaseToken: string,
  
  // Status
  status: 'active' | 'cancelled' | 'expired' | 'grace_period',
  startDate: timestamp,
  currentPeriodEnd: timestamp,
  cancelAt: timestamp | null,
  
  // Payment
  currency: string,
  price: number,
  
  // Metadata
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 7.2 Storage Structure

```
Firebase Storage:
/users/{userId}/
  /profile/
    - avatar.jpg
  /relatives/{relativeId}/
    - photo.jpg
  /interactions/{interactionId}/
    - photo1.jpg
    - photo2.jpg
    - audio.m4a
  /exports/
    - backup_2024_03_15.json
    - report_march_2024.pdf
```

### 7.3 Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Nested collections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Prevent access to other users' data
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 7.4 Indexes (Firestore)

```javascript
// Required composite indexes:

// 1. For fetching relatives sorted by last contact
Collection: users/{userId}/relatives
Fields: userId (Ascending), lastInteractionDate (Descending)

// 2. For interactions timeline
Collection: users/{userId}/interactions
Fields: userId (Ascending), date (Descending)

// 3. For reminders by date
Collection: users/{userId}/reminders
Fields: userId (Ascending), scheduledDate (Ascending), status (Ascending)

// 4. For achievements
Collection: users/{userId}/achievements
Fields: userId (Ascending), isUnlocked (Ascending), unlockedAt (Descending)
```

---

## 8. تصميم UI/UX {#تصميم-uiux}

### 8.1 مبادئ التصميم

#### 8.1.1 القيم الأساسية:
- 🎯 **البساطة**: واجهة بسيطة وواضحة
- 🌟 **الجمال**: تصميم عصري وجذاب
- ⚡ **السرعة**: استجابة فورية
- 💚 **الدفء**: ألوان دافئة تعكس الروابط الأسرية
- 📖 **الوضوح**: نصوص واضحة وخطوط مريحة

#### 8.1.2 Accessibility:
- ✅ دعم كامل لقارئ الشاشة (VoiceOver/TalkBack)
- ✅ Contrast ratio مناسب (WCAG AA)
- ✅ حجم خط قابل للتعديل
- ✅ أزرار كبيرة (44x44 pt minimum)
- ✅ تسميات واضحة

### 8.2 نظام الألوان

#### Primary Palette:
```
الأخضر الرئيسي: #2D7A3E (صلة، نمو، حياة)
الأخضر الفاتح: #4CAF50
الأخضر الداكن: #1B5E20

الذهبي: #D4AF37 (قيمة، عظمة)
الذهبي الفاتح: #FFD700

الأبيض: #FFFFFF
Off-white: #F8F9FA
```

#### Secondary Colors:
```
أزرق: #1976D2 (ثقة، سلام)
برتقالي: #FF9800 (طاقة، تحفيز)
أحمر: #D32F2F (تنبيه، عاجل)
رمادي: #757575 (محايد)
```

#### Text Colors:
```
Primary Text: #212121
Secondary Text: #757575
Disabled: #BDBDBD
Hint: #9E9E9E
```

### 8.3 Typography

#### Arabic Fonts:
```
Primary: "Cairo" (Google Font)
- Regular (400)
- Medium (500)
- SemiBold (600)
- Bold (700)

Alternative: "Tajawal" أو "IBM Plex Sans Arabic"
```

#### English Fonts:
```
Primary: "Roboto"
- Regular (400)
- Medium (500)
- Bold (700)
```

#### Font Sizes:
```
Display: 28-32pt
Title: 22-24pt
Headline: 18-20pt
Body: 16pt
Caption: 14pt
Small: 12pt
```

### 8.4 الشاشات الرئيسية

#### 8.4.1 Splash Screen
- Logo كبير
- "صِلْني"
- Tagline: "لنصل الرحم معاً"
- Animation لطيفة

#### 8.4.2 Onboarding (3 شاشات)
**Screen 1**: "أهلاً بك في صِلْني"
- رسم توضيحي: عائلة متحابة
- نص: "نساعدك على تنظيم صلة رحمك بطريقة سهلة ومحفزة"

**Screen 2**: "تذكيرات ذكية"
- رسم: جوال مع إشعار
- نص: "لن تنسى أبداً التواصل مع أحبائك"

**Screen 3**: "تتبع إنجازاتك"
- رسم: إحصائيات ونجوم
- نص: "شاهد تقدمك واحتسب الأجر من الله"

#### 8.4.3 Auth Screens
**Login**:
- Logo
- "مرحباً بعودتك"
- Email field
- Password field
- "نسيت كلمة المرور؟"
- زر "تسجيل الدخول"
- "ليس لديك حساب؟ سجّل الآن"

**Sign Up**:
- "إنشاء حساب جديد"
- Name field
- Email field
- Password field
- Confirm password
- زر "إنشاء حساب"
- "لديك حساب؟ سجّل الدخول"

#### 8.4.4 Main Tabs (Bottom Navigation)
1. **الرئيسية** (Home) 🏠
2. **الأقارب** (Relatives) 👥
3. **إضافة** (+) ➕ (FAB in center)
4. **الإحصائيات** (Stats) 📊
5. **المزيد** (More) ☰

#### 8.4.5 Home Screen
**Header**:
- "السلام عليكم، [الاسم]"
- تاريخ اليوم (هجري + ميلادي)
- Current streak: "🔥 15 يوماً"

**Quick Stats**:
- تواصلات اليوم
- تواصلات هذا الأسبوع
- التقدم نحو الهدف

**Today's Reminders**:
- قائمة من يجب التواصل معهم اليوم
- كل واحد في Card مع:
  - صورة
  - الاسم
  - العلاقة
  - أيام منذ آخر تواصل
  - زر سريع للاتصال

**Daily Hadith**:
- Card جميل مع حديث اليوم

**Quick Actions**:
- أزرار سريعة لأكثر الأعمال استخداماً

#### 8.4.6 Relatives List Screen
**Header**:
- Search bar
- Filter button
- Sort button

**Filters**:
- الكل
- الأقرب (حسب العلاقة)
- يحتاج تواصل
- الأخيرون

**List Item**:
- صورة دائرية
- الاسم
- العلاقة
- أيام منذ آخر تواصل
- أيقونة status
- Swipe actions:
  - Call
  - Message
  - Mark as contacted

**FAB**: + إضافة قريب جديد

#### 8.4.7 Relative Detail Screen
**Header**:
- صورة كبيرة
- الاسم
- العلاقة
- أيقونات للإجراءات السريعة:
  - Call
  - Message
  - Video call
  - Edit

**Info Cards**:
- Contact info
- Last contacted: X days ago
- Total interactions: Y
- Notes (Premium)

**Timeline**:
- تاريخ كل التواصلات
- عرض زمني جميل

**Actions**:
- زر "سجّل تواصل جديد"
- زر "جدول تذكير"

#### 8.4.8 Add/Edit Relative Screen
**Form Fields**:
- صورة (optional)
- الاسم الكامل *
- الكنية
- العلاقة * (Dropdown)
- رقم الجوال *
- أرقام إضافية (Premium)
- البريد الإلكتروني
- العنوان (Premium)
- تاريخ الميلاد (Premium)
- ملاحظات (Premium)

**Save Button**:
- "حفظ"

#### 8.4.9 Add Interaction Screen
**Quick Select**:
- أزرار كبيرة:
  - 📞 اتصال
  - 🏠 زيارة
  - 💬 رسالة
  - 🎁 هدية
  - 📅 مناسبة
  - ➕ أخرى

**Details**:
- التاريخ (default: اليوم)
- الوقت
- المدة (optional)
- ملاحظات (optional)
- الجودة (Premium)
- صور (Premium)

**Save Button**

#### 8.4.10 Statistics Screen
**Header**:
- فترة الإحصائيات (اليوم، الأسبوع، الشهر، السنة)

**Summary Cards**:
- إجمالي التواصلات
- أكثر قريب تواصلاً
- Current streak
- Level & XP

**Charts** (Premium):
- رسم بياني للتواصلات
- Heatmap
- توزيع أنواع التواصل

**Achievements** (Premium):
- عرض الشارات المكتسبة

**Reports** (Premium):
- زر "إنشاء تقرير"

#### 8.4.11 More/Settings Screen
**Account Section**:
- صورة وaسم المستخدم
- "تعديل الملف الشخصي"
- "الاشتراك" (مع badge إذا Premium)

**App Settings**:
- اللغة
- الثيم
- الإشعارات
- الصوت والاهتزاز

**Premium Features** (if free):
- Card جذاب للترقية
- "جرّب Premium مجاناً لـ 7 أيام"

**Data & Privacy**:
- النسخ الاحتياطي (Premium)
- تصدير البيانات
- الخصوصية

**Support**:
- المحتوى التعليمي
- الأسئلة الشائعة
- تواصل معنا
- تقييم التطبيق

**About**:
- عن التطبيق
- الشروط والأحكام
- سياسة الخصوصية
- الإصدار

**Danger Zone**:
- حذف الحساب

#### 8.4.12 Premium Paywall
**Hero Section**:
- "ارتقِ لـ Premium"
- "احصل على كل المزايا"

**Features List**:
- ✅ إضافة لا محدودة للأقارب
- ✅ تذكيرات ذكية
- ✅ إحصائيات متقدمة
- ✅ شارات وتحديات
- ✅ نسخ احتياطي سحابي
- ✅ ثيمات متعددة
- ✅ وأكثر...

**Pricing**:
- شهري: 7.99 ريال/شهر
- سنوي: 79.99 ريال/سنة (وفّر 16 ريال!)

**CTA Buttons**:
- "ابدأ التجربة المجانية" (7 أيام)
- "اشترك الآن"
- "استعادة المشتريات"
- "لاحقاً"

**Fine Print**:
- شرح بسيط عن التجربة المجانية والاشتراك

### 8.5 Components & Patterns

#### 8.5.1 Cards:
- Shadow خفيف
- Border radius: 12px
- Padding: 16px
- Elevation: 2

#### 8.5.2 Buttons:
**Primary**:
- Background: Primary color
- Text: White
- Height: 48px
- Border radius: 24px
- Bold text

**Secondary**:
- Outlined
- Border: Primary color
- Text: Primary color

**Text Button**:
- No background
- Primary color text

#### 8.5.3 Input Fields:
- Height: 56px
- Border radius: 8px
- Outlined style
- Label floats on focus
- Helper text below
- Error state: Red

#### 8.5.4 Bottom Sheet:
- للخيارات والفلاتر
- Handle في الأعلى
- Background: Semi-transparent overlay

#### 8.5.5 Snackbar/Toast:
- للرسائل السريعة
- تظهر من الأسفل
- Auto-dismiss بعد 3 ثواني

#### 8.5.6 Loading States:
- Skeleton screens
- أو Shimmer effect
- أو Spinner للعمليات السريعة

#### 8.5.7 Empty States:
- رسم توضيحي لطيف
- نص واضح
- زر CTA للإجراء

### 8.6 Animations & Transitions

#### 8.6.1 Screen Transitions:
- Slide from right (iOS style)
- أو Fade (لبعض الشاشات)
- Duration: 300ms

#### 8.6.2 Micro-interactions:
- زر يهتز عند الضغط
- Card يكبر شوي عند التحديد
- Checkmark animation عند الحفظ
- Confetti عند فتح Achievement

#### 8.6.3 Pull-to-refresh:
- Lottie animation مخصص

#### 8.6.4 Loading Animations:
- Skeleton للقوائم
- Spinner للعمليات
- Progress bar للتحميل

### 8.7 Dark Mode

**كل الألوان لها نسخة Dark:**
```
Background: #121212
Surface: #1E1E1E
Primary: #4CAF50 (نفسه)
Text: #FFFFFF
Secondary Text: #B3B3B3
```

---

## 9. User Flows {#user-flows}

### 9.1 Onboarding Flow

```
Start
  ↓
Splash Screen (2s)
  ↓
First time? → YES → Onboarding (3 screens)
  ↓                    ↓
  NO              Sign Up Screen
  ↓                    ↓
Login Screen      Create Account
  ↓                    ↓
  └────────────────────┘
           ↓
    Home Screen
```

### 9.2 Add Relative Flow

```
Relatives Screen
  ↓
Tap FAB (+)
  ↓
Add Relative Screen
  ↓
Fill Form
  ↓
Choose Relationship Type
  ↓
Add Contact Info
  ↓
[Premium: Add more details]
  ↓
Tap "Save"
  ↓
Success! → Navigate to Relative Detail
  ↓
[Optional: Set Reminder]
  ↓
Back to Relatives List
```

### 9.3 Log Interaction Flow

```
Option 1: From Home
  Home Screen
    ↓
  Today's Reminders
    ↓
  Tap relative
    ↓
  Quick action buttons
    ↓
  Tap "Call" / "Visit" / etc
    ↓
  Log Interaction Screen (pre-filled)
    ↓
  [Add notes if needed]
    ↓
  Save
    ↓
  Success toast
    ↓
  Back to Home (updated stats)

Option 2: From Relative Detail
  Relative Detail Screen
    ↓
  Tap "Log New Interaction"
    ↓
  Choose type
    ↓
  Fill details
    ↓
  Save
    ↓
  Timeline updated

Option 3: Quick Log from List
  Relatives List
    ↓
  Swipe left on relative
    ↓
  Tap action (Call/Visit/etc)
    ↓
  Logged! (minimal friction)
```

### 9.4 View Statistics Flow

```
Stats Tab
  ↓
Overview dashboard
  ↓
Select period (Week/Month/Year)
  ↓
View charts [Premium]
  ↓
Tap "Generate Report" [Premium]
  ↓
PDF generated
  ↓
Share or Save
```

### 9.5 Upgrade to Premium Flow

```
Trigger Premium Feature
  ↓
Paywall appears
  ↓
View features & pricing
  ↓
Tap "Start Free Trial" or "Subscribe"
  ↓
Platform payment (App Store / Play Store)
  ↓
Payment confirmed
  ↓
Success! Premium unlocked
  ↓
Back to app with Premium access
```

### 9.6 Daily Usage Flow

```
User opens app (Morning)
  ↓
Home Screen
  ↓
Sees notification badge
  ↓
Reads "Today's Reminders"
  ↓
Sees: "Call your mother - 3 days since last contact"
  ↓
Taps "Call" quick action
  ↓
Phone app opens with number
  ↓
Makes call
  ↓
Returns to app
  ↓
Interaction auto-logged (or manual)
  ↓
Sees updated streak: "🔥 16 days"
  ↓
Achievement unlocked? → Celebration animation
  ↓
Reads daily Hadith
  ↓
Closes app feeling good 💚
```

---

## 10. الأمان والخصوصية {#الأمان-والخصوصية}

### 10.1 Authentication & Authorization

#### 10.1.1 Firebase Auth:
- ✅ Email/Password (with email verification)
- ✅ Phone number (SMS verification)
- 🔄 Social login (Google - Phase 2)
- 🔄 Apple Sign In (Phase 2)

#### 10.1.2 Password Requirements:
- Minimum 8 characters
- At least 1 uppercase
- At least 1 lowercase
- At least 1 number
- At least 1 special character

#### 10.1.3 Session Management:
- JWT tokens
- Auto-logout after 30 days inactivity
- Remember me option
- Biometric authentication (Face ID / Touch ID / Fingerprint)

### 10.2 Data Security

#### 10.2.1 Encryption:
- ✅ **In Transit**: TLS 1.3
- ✅ **At Rest**: Firebase encryption (AES-256)
- ✅ **Sensitive Data**: Additional encryption layer for notes

#### 10.2.2 Firestore Security Rules:
```javascript
// User can only access their own data
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
  
  match /relatives/{relativeId} {
    allow read, write: if request.auth.uid == userId;
  }
  
  match /interactions/{interactionId} {
    allow read, write: if request.auth.uid == userId;
  }
}
```

#### 10.2.3 Storage Security Rules:
```javascript
// User can only access their own files
match /users/{userId}/{allPaths=**} {
  allow read, write: if request.auth.uid == userId;
}
```

### 10.3 Privacy

#### 10.3.1 Data Collection:
**ما نجمعه**:
- ✅ بيانات الحساب (اسم، بريد، هاتف)
- ✅ بيانات الأقارب (المستخدم يدخلها)
- ✅ بيانات الاستخدام (Analytics)
- ✅ بيانات الجهاز (لتحسين الأداء)

**ما لا نجمعه**:
- ❌ محتوى المكالمات
- ❌ محتوى الرسائل
- ❌ الموقع الدقيق (إلا بإذن صريح)
- ❌ جهات الاتصال (إلا بإذن الاستيراد)

#### 10.3.2 Data Usage:
- ✅ لتحسين التطبيق
- ✅ لإرسال الإشعارات
- ✅ للإحصائيات المجهولة
- ❌ لن نبيع بياناتك **أبداً**
- ❌ لن نشارك مع أطراف ثالثة (إلا خدمات مثل Firebase)

#### 10.3.3 User Rights:
- ✅ حق الوصول لكل بياناتك
- ✅ حق التعديل
- ✅ حق التصدير
- ✅ حق الحذف الكامل

#### 10.3.4 GDPR Compliance:
- ✅ Privacy Policy واضحة
- ✅ Terms of Service
- ✅ Cookie Policy
- ✅ حق النسيان (Right to be forgotten)

### 10.4 App Permissions

#### 10.4.1 Required:
- ✅ Internet (للمزامنة)
- ✅ Notifications (للتذكيرات)

#### 10.4.2 Optional (with clear explanation):
- 📷 Camera (لصور الأقارب)
- 📁 Photo Library (لرفع الصور)
- 📞 Phone (للاتصال السريع)
- 📅 Calendar (للمزامنة)
- 📍 Location (للمناسبات المرتبطة بمكان - Premium)
- 👤 Contacts (للاستيراد السريع)

**كل إذن نطلبه بعد توضيح السبب!**

### 10.5 Compliance

#### 10.5.1 Saudi Regulations:
- ✅ متوافق مع أنظمة حماية البيانات الشخصية
- ✅ خوادم في مناطق مسموح بها
- ✅ لا محتوى مخالف

#### 10.5.2 App Store Guidelines:
- ✅ Apple App Store Review Guidelines
- ✅ Google Play Policy
- ✅ Data Safety declarations

---

## 11. نموذج الأعمال {#نموذج-الأعمال}

### 11.1 Revenue Streams

#### 11.1.1 Freemium Subscription:
```
Free: $0 (كل الأساسيات)
Premium: 7.99 SAR/month أو 79.99 SAR/year

Target conversion rate: 5-10%

Year 1 projections:
- 100,000 users
- 5% conversion = 5,000 Premium
- Revenue = 5,000 × 79.99 = ~400,000 SAR/year
```

#### 11.1.2 In-app Purchases (Phase 2):
- Theme packs: 4.99 SAR
- Icon packs: 2.99 SAR
- Premium features à la carte

#### 11.1.3 Ethical Ads (Free version - optional):
- Non-intrusive banner ads
- Only halal products/services
- Opt-out with Premium

### 11.2 Costs

#### 11.2.1 Fixed Costs (Monthly):
```
Firebase (Blaze plan): 25 SAR
EAS Builds: 0 SAR (Free tier initially)
Domain & Hosting (website): 50 SAR
───────────────────────────────
Total Fixed: ~75 SAR/month = 900 SAR/year
```

#### 11.2.2 Variable Costs (scales with users):
```
Firebase (storage, bandwidth): ~0.10 SAR per user/month
Apple Developer: 99 USD/year = ~370 SAR/year
Google Play: 25 USD one-time = ~94 SAR
RevenueCat: 15% of revenue (after $2500/month)
───────────────────────────────
For 100,000 users:
Variable = 100,000 × 0.10 × 12 = ~120,000 SAR/year
```

#### 11.2.3 Total Costs (Year 1):
```
Fixed: 900 SAR
Variable: 120,000 SAR
Platform fees: 464 SAR
───────────────────────────────
Total: ~121,364 SAR/year
```

### 11.3 Profitability

#### Year 1:
```
Revenue: 400,000 SAR
Costs: 121,364 SAR
───────────────────────────────
Profit: ~278,636 SAR
ROI: 230%
```

**ملاحظة**: هذه تقديرات متحفظة. الأرقام الفعلية قد تختلف.

### 11.4 Growth Strategy

#### 11.4.1 Acquisition:
- 📱 App Store Optimization (ASO)
- 📢 Social Media (Twitter, TikTok)
- 🕌 Partnerships مع المؤسسات الدينية
- 🎙️ Podcast sponsorships
- 📺 YouTube influencers
- 🤝 Word of mouth (referral program)

#### 11.4.2 Retention:
- 🔔 Smart notifications
- 🎮 Gamification
- 📊 Progress tracking
- 💌 Email newsletters
- 🆕 Regular feature updates

#### 11.4.3 Monetization:
- 🎁 Free trial (7 days)
- 🏷️ Limited-time offers (Ramadan discount)
- 💎 Value-based pricing
- 🎯 Targeted upsells

### 11.5 Exit Strategy (5+ years)

#### Option 1: Continue independently
- Sustainable business
- Passive income
- Hire small team

#### Option 2: Acquisition
- Islamic apps network
- Larger tech company

#### Option 3: Nonprofit
- Convert to Islamic foundation
- Donation-based model

---

## 12. خطة التطوير {#خطة-التطوير}

### 12.1 Phase 1: MVP (Weeks 1-4)

#### Week 1: Setup & Core
- ✅ Project setup (Expo + Firebase)
- ✅ Authentication (Email/Password)
- ✅ Basic navigation
- ✅ Relatives CRUD (Add, List, Edit, Delete)
- ✅ Basic UI components

#### Week 2: Features
- ✅ Interactions logging
- ✅ Reminders system
- ✅ Local notifications
- ✅ Basic stats

#### Week 3: Content & Polish
- ✅ Daily Hadith
- ✅ Educational content
- ✅ UI polish
- ✅ Dark mode
- ✅ Loading states

#### Week 4: Testing & Launch
- ✅ Bug fixes
- ✅ Performance optimization
- ✅ App Store assets (screenshots, description)
- ✅ Beta testing (TestFlight/Internal Testing)
- ✅ Submit to stores

**Deliverable**: MVP على App Store & Play Store

---

### 12.2 Phase 2: Premium Features (Weeks 5-8)

#### Week 5: Advanced Tracking
- 🌟 Timeline view
- 🌟 Advanced stats
- 🌟 Charts & graphs

#### Week 6: Gamification
- 🎮 Badges system
- 🎮 Levels & XP
- 🎮 Achievements
- 🎮 Streak tracking

#### Week 7: Premium Infrastructure
- 💎 RevenueCat integration
- 💎 Subscription paywall
- 💎 Cloud backup
- 💎 Cross-device sync

#### Week 8: Testing & Launch
- 🧪 Premium features testing
- 🧪 Payment testing
- 📱 Launch Premium tier
- 📣 Marketing push

**Deliverable**: Premium features live

---

### 12.3 Phase 3: Growth (Months 3-6)

#### Month 3:
- 📊 Analytics & insights
- 🐛 Bug fixes based on feedback
- 🆕 Small feature additions

#### Month 4:
- 🌐 English localization
- 🎨 More themes
- 📱 Widget support

#### Month 5:
- ⌚ Apple Watch app
- 🔗 Calendar integration
- 📞 Call integration

#### Month 6:
- 🤖 Smart suggestions (AI)
- 👥 Family groups (shared)
- 📸 Photo albums

**Deliverable**: Feature-rich app with strong user base

---

### 12.4 Phase 4: Scale (Year 1+)

#### Q1 Year 2:
- 🌍 More languages (Urdu, Turkish)
- 🌐 Web version (React)
- 🔄 Advanced sync

#### Q2 Year 2:
- 🤝 Partnerships
- 📈 Marketing campaigns
- 🎓 Educational partnerships

#### Q3 Year 2:
- 🆕 Major feature updates
- 🎮 More gamification
- 📱 iPad optimization

#### Q4 Year 2:
- 🎯 Enterprise features
- 👨‍👩‍👧‍👦 Family plans
- 🏢 Institution licenses

---

### 12.5 Development Workflow

#### Daily:
```
9:00 AM: Stand-up (5 min)
9:05 AM - 12:00 PM: Deep work (coding)
12:00 PM - 1:00 PM: Break
1:00 PM - 5:00 PM: Development
5:00 PM - 6:00 PM: Testing & bug fixes
6:00 PM: Commit & push
```

#### Weekly:
```
Monday: Sprint planning
Wednesday: Mid-week check-in
Friday: Sprint review & demo
Saturday: Rest or catch-up
```

#### Testing:
- Unit tests for critical functions
- Manual testing on real devices (daily)
- Beta testing with 10-20 users
- User feedback incorporation

---

## 13. KPIs ومقاييس النجاح {#kpis-ومقاييس-النجاح}

### 13.1 User Metrics

#### Acquisition:
- 📈 **Downloads**: 100K Year 1
- 📱 **Daily Active Users (DAU)**: 10K
- 🔄 **Monthly Active Users (MAU)**: 40K
- 📊 **DAU/MAU Ratio**: 25% (healthy)

#### Engagement:
- ⏱️ **Session Length**: 3-5 minutes
- 🔁 **Sessions per DAU**: 2-3
- 📅 **Days Active per Week**: 4+
- 🔥 **Retention Rate**:
  - Day 1: 70%
  - Day 7: 40%
  - Day 30: 25%

#### Monetization:
- 💰 **Conversion to Premium**: 5-10%
- 💎 **ARPU** (Average Revenue Per User): 4 SAR
- 💵 **LTV** (Lifetime Value): 80 SAR
- 🔄 **Churn Rate**: <5% monthly

### 13.2 Feature Metrics

#### Relatives:
- 👥 **Avg Relatives per User**: 15-20
- ➕ **New Relatives Added/Week**: 2
- 📝 **Completion Rate**: 80% (all fields filled)

#### Interactions:
- 📞 **Interactions Logged/Week**: 5-10
- 🔔 **Reminder Response Rate**: 60%
- ⏰ **Time to Log**: <30 seconds

#### Gamification:
- 🏆 **Badges Earned/User**: 5+ in first month
- ⭐ **Avg Level Reached**: Level 5 in 3 months
- 🔥 **Avg Streak**: 7 days

### 13.3 Technical Metrics

#### Performance:
- ⚡ **App Launch Time**: <2 seconds
- 🖼️ **Screen Load Time**: <500ms
- 🔄 **Sync Time**: <3 seconds
- 📊 **Crash-free Rate**: >99.5%

#### Quality:
- 🐛 **Bug Rate**: <1 per 1000 sessions
- ⭐ **App Store Rating**: 4.5+
- 📝 **Review Sentiment**: 80% positive

### 13.4 Business Metrics

#### Revenue:
- 💰 **MRR** (Monthly Recurring Revenue): 33K SAR (Month 12)
- 📈 **ARR** (Annual Recurring Revenue): 400K SAR
- 💵 **CAC** (Customer Acquisition Cost): <20 SAR
- 🎯 **CAC Payback Period**: <3 months

#### Growth:
- 📊 **Month-over-Month Growth**: 10-20%
- 🔄 **Viral Coefficient**: 0.3 (30% bring a friend)
- 📢 **NPS** (Net Promoter Score): 50+

---

## 14. المخاطر والتحديات {#المخاطر-والتحديات}

### 14.1 Technical Risks

#### Risk 1: Performance Issues
**Probability**: Medium
**Impact**: High
**Mitigation**:
- Pagination for large lists
- Image optimization
- Caching strategies
- Regular performance audits

#### Risk 2: Data Loss
**Probability**: Low
**Impact**: Critical
**Mitigation**:
- Daily cloud backups
- Version history (Premium)
- Local backup before sync
- Data export anytime

#### Risk 3: Push Notification Failures
**Probability**: Medium
**Impact**: Medium
**Mitigation**:
- Fallback to in-app notifications
- Redundant notification systems
- User-configurable retry

### 14.2 Business Risks

#### Risk 1: Low Conversion to Premium
**Probability**: Medium
**Impact**: High
**Mitigation**:
- Strong value proposition
- 7-day free trial
- Regular feature updates
- User testimonials
- Limited-time offers

#### Risk 2: High Churn Rate
**Probability**: Medium
**Impact**: High
**Mitigation**:
- Gamification to increase engagement
- Regular reminders
- Valuable content
- Community building
- Quick feature requests turnaround

#### Risk 3: Competition
**Probability**: High
**Impact**: Medium
**Mitigation**:
- First-mover advantage
- Superior UX
- Islamic differentiation
- Strong brand
- Community loyalty

### 14.3 Market Risks

#### Risk 1: Market Saturation
**Probability**: Low (niche market)
**Impact**: High
**Mitigation**:
- Continuous innovation
- Expand to related features
- International expansion
- B2B opportunities (institutions)

#### Risk 2: Economic Downturn
**Probability**: Low-Medium
**Impact**: Medium
**Mitigation**:
- Affordable pricing
- Strong free tier
- Flexible payment options
- Value demonstration

### 14.4 Legal/Regulatory Risks

#### Risk 1: Privacy Regulations
**Probability**: Low
**Impact**: High
**Mitigation**:
- GDPR-compliant from day 1
- Clear privacy policy
- User consent for everything
- Regular audits
- Legal consultation

#### Risk 2: App Store Rejection
**Probability**: Low
**Impact**: Critical
**Mitigation**:
- Follow guidelines strictly
- Beta review before submission
- Quick fixes for feedback
- Alternative distribution (web)

### 14.5 Contingency Plans

#### If downloads are low:
1. Increase marketing spend
2. Referral program
3. Partnerships with Islamic orgs
4. Content marketing (blog, videos)
5. App Store Optimization

#### If conversion is low:
1. A/B test pricing
2. Improve onboarding
3. Enhance free tier slightly
4. Better premium demos
5. User surveys

#### If technical issues arise:
1. Dedicated bug fix sprints
2. Hotfix releases
3. User communication
4. Temporary workarounds
5. Expert consultation if needed

---

## 15. الخلاصة والتوجيهات

### 15.1 Vision Summary
صِلْني هو تطبيق إسلامي لمساعدة المسلمين على تنظيم وتتبع صلة الرحم بطريقة عملية ومحفزة. نهدف لأن نكون التطبيق الأول في هذا المجال، مع التركيز على:
- ✅ البساطة والسهولة
- ✅ التحفيز والإنجاز
- ✅ الجودة والاحترافية
- ✅ النية الصالحة والأجر

### 15.2 Core Principles
1. **الأساسيات مجانية للأبد** - لا نحجب صلة الرحم عن أحد
2. **الجودة قبل الكمية** - ميزات مصقولة أفضل من ميزات كثيرة
3. **الخصوصية أولاً** - بيانات المستخدم مقدسة
4. **الاستدامة** - نموذج عمل صحي لاستمرارية التطبيق
5. **الصدقة الجارية** - الهدف الأول هو الأجر، الرزق تبع بإذن الله

### 15.3 Success Criteria
**Phase 1 (3 months)**: 10,000 downloads, 4.0+ rating
**Phase 2 (6 months)**: 50,000 downloads, 500 Premium users
**Phase 3 (1 year)**: 100,000 downloads, 5,000 Premium users, profitable

### 15.4 Next Steps
1. ✅ Setup development environment (Week 0)
2. ✅ Build MVP (Weeks 1-4)
3. ✅ Beta testing (Week 4)
4. ✅ Launch (Week 5)
5. ✅ Iterate based on feedback (Ongoing)
6. ✅ Add Premium features (Weeks 5-8)
7. ✅ Scale and grow (Months 3+)

---

## 📞 Contact & Support

**Project Lead**: [Your Name]
**Email**: [Your Email]
**GitHub**: [Repository URL]
**Website**: [Coming Soon]

---

## 📄 Document Info

**Version**: 1.0
**Last Updated**: [Date]
**Status**: In Development
**Next Review**: [Date]

---

**بِسْمِ اللهِ، وعلى بركة الله، نبدأ! 🚀**

> "إِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ"
> [التوبة: 120]