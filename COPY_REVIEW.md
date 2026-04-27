# Silni — Arabic Copy Review (Founder Pass)

**Scope:** User-facing Arabic strings extracted verbatim from `lib/`. The "✅/✏️/❌" column is yours to fill — `_` = pending. Use ✅ if the wording is fine, ✏️ if it needs a small tweak (note inline), ❌ if it must be rewritten.

**Capping note:** This file is capped at the most-trafficked surfaces. Excluded:
- `silni-admin/` (admin dashboard, not in lib/)
- LoggerOverlay debug strings
- Hadith content (separate Cat 4 review)
- Constants accessed only by lookup (e.g. `RelationshipType.arabicLabel`, `InteractionType.arabicName`, `AvatarType.arabicName`) — too many enum values; review separately
- Hardcoded English strings (Cat 1 of leakage audit)
- `wrapped/services/wrapped_generator_service.dart` personality labels (already short and listed in dictionary form below)

Strings are quoted verbatim from source — copy-paste into PRs. Where a `$variable` is interpolated, it's left in place so you see the template.

---

## 1. Onboarding (carousel — first cold-start)

File: `lib/features/auth/screens/onboarding_screen.dart`

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| onboarding_screen.dart:29 | Page 1 title | رحلة الصلة | _ |
| onboarding_screen.dart:30 | Page 1 description | قرّب قلبك من عائلتك وأحبائك\nبطريقة جميلة وممتعة | _ |
| onboarding_screen.dart:35 | Page 2 title | التذكيرات السحرية | _ |
| onboarding_screen.dart:36 | Page 2 description | لن تنسى التواصل مع أحبائك بعد اليوم\nتذكيرات ذكية وشخصية | _ |
| onboarding_screen.dart:41 | Page 3 title | احتفل بإنجازاتك | _ |
| onboarding_screen.dart:42 | Page 3 description | كسب النقاط والشارات والإنجازات\nمع كل تواصل مع عائلتك | _ |
| onboarding_screen.dart:47 | Page 4 title | ثلاث دوائر للتواصل | _ |
| onboarding_screen.dart:48 | Page 4 description | 🏠 أهل البيت — تواصل يومي\n📞 تواصل دائم — متابعة أسبوعية\n🌙 مناسبات — أعياد وأفراح | _ |
| onboarding_screen.dart:110 | Skip button label | تخطي | _ |
| onboarding_screen.dart:150 | Last-page CTA / Next button | ابدأ الآن / التالي | _ |

### Premium-onboarding (post-trial walkthrough)

File: `lib/features/premium_onboarding/constants/onboarding_content.dart`, `models/onboarding_step.dart`

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| onboarding_content.dart:10 | Header title | مرحباً بك في MAX | _ |
| onboarding_content.dart:13 | Skip button | تخطي | _ |
| onboarding_content.dart:16 | Next button | التالي | _ |
| onboarding_content.dart:19 | Try-now button | جرب الآن | _ |
| onboarding_content.dart:22 | Start-journey button | ابدأ رحلتك | _ |
| onboarding_content.dart:32 | Completion title | أنت جاهز! | _ |
| onboarding_content.dart:36 | Completion description | استكشفت جميع ميزات صلني MAX\nابدأ رحلتك في تقوية صلة الرحم | _ |
| onboarding_content.dart:39 | Completion CTA | ابدأ الآن | _ |
| onboarding_content.dart:42 | Quick-actions title | ابدأ مع | _ |
| onboarding_content.dart:49 | Tooltip dismiss button | فهمت | _ |
| onboarding_content.dart:52 | Tooltip don't-show-again | لا تظهر مرة أخرى | _ |
| onboarding_step.dart:72 | Step "AI Counselor" title | المستشار الذكي | _ |
| onboarding_step.dart:73 | Step "AI Counselor" desc | مستشارك الشخصي لصلة الرحم\nنصائح مخصصة لكل علاقة | _ |
| onboarding_step.dart:83 | AI Counselor bullet 1 | نصائح مخصصة لكل قريب | _ |
| onboarding_step.dart:84 | AI Counselor bullet 2 | حلول للمواقف الصعبة | _ |
| onboarding_step.dart:85 | AI Counselor bullet 3 | إرشادات إسلامية | _ |
| onboarding_step.dart:96 | Step "Reminders" title | تذكيرات غير محدودة | _ |
| onboarding_step.dart:97 | Step "Reminders" desc | سجّل أي عدد من التذكيرات\nليوصلك الله بأهلك في وقتها | _ |
| onboarding_step.dart:107 | Reminders bullet 1 | بلا حد على عدد التذكيرات | _ |
| onboarding_step.dart:108 | Reminders bullet 2 | يومية وأسبوعية وشهرية | _ |
| onboarding_step.dart:109 | Reminders bullet 3 | إشعارات في الوقت المناسب | _ |
| onboarding_step.dart:117 | Step "Weekly Report" title | التقرير الأسبوعي | _ |
| onboarding_step.dart:118 | Step "Weekly Report" desc | ملخص أسبوعي لتواصلك\nمع عائلتك | _ |
| onboarding_step.dart:128 | Weekly Report bullet 1 | ملخص تواصلك الأسبوعي | _ |
| onboarding_step.dart:129 | Weekly Report bullet 2 | إحصائيات مفصلة | _ |
| onboarding_step.dart:130 | Weekly Report bullet 3 | توصيات للأسبوع القادم | _ |

---

## 2. Auth flows

### Splash

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| splash_screen.dart:138 | Connection-error fallback | حدث خطأ في الاتصال — حاول مجدداً | _ |
| splash_screen.dart:186 | App name (logo wordmark) | صِـلْـنِـي | _ |
| splash_screen.dart:233 | Tagline below logo | صِلْ رَحِمَكَ بِحُبٍّ | _ |

### Login

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| login_screen.dart:189 | Biometric auth fail (fallback) | فشل المصادقة البيومترية | _ |
| login_screen.dart:200 | Session-expired snackbar | انتهت صلاحية الجلسة. يرجى تسجيل الدخول بكلمة المرور | _ |
| login_screen.dart:264 | Server-init failure (cold start) | فشل تهيئة الاتصال بالخادم. يرجى إعادة تشغيل التطبيق والمحاولة مرة أخرى. | _ |
| login_screen.dart:310 | Login timeout | انتهت مهلة تسجيل الدخول، يرجى المحاولة مرة أخرى | _ |
| login_screen.dart:501 | Forgot-password dialog title | إعادة تعيين كلمة المرور | _ |
| login_screen.dart:511 | Forgot-password dialog body | سنرسل لك رابط لإعادة تعيين كلمة المرور | _ |
| login_screen.dart:519 | Email field label (dialog) | البريد الإلكتروني | _ |
| login_screen.dart:520 | Email field hint (dialog) | بريدك الإلكتروني | _ |
| login_screen.dart:524 | Email validator empty | يرجى إدخال البريد الإلكتروني | _ |
| login_screen.dart:528 | Email validator format | يرجى إدخال بريد إلكتروني صحيح | _ |
| login_screen.dart:541 | Cancel button | إلغاء | _ |
| login_screen.dart:559 | Send (reset link) button | إرسال | _ |
| login_screen.dart:578 | Reset-link sent snackbar | تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني | _ |
| login_screen.dart:833 | Login title | مرحباً بعودتك | _ |
| login_screen.dart:845 | Login subtitle | سجّل الدخول للمتابعة | _ |
| login_screen.dart:869 | Email label (main form) | البريد الإلكتروني | _ |
| login_screen.dart:873 | Email hint (main form) | بريدك الإلكتروني | _ |
| login_screen.dart:911 | Email validator empty (main) | الرجاء إدخال البريد الإلكتروني | _ |
| login_screen.dart:918 | Email validator format (main) | البريد الإلكتروني غير صحيح | _ |
| login_screen.dart:935 | Password label | كلمة المرور | _ |
| login_screen.dart:990 | Password validator empty | الرجاء إدخال كلمة المرور | _ |
| login_screen.dart:1016 | New-account link | إنشاء حساب جديد | _ |
| login_screen.dart:1028 | Forgot-password link | نسيت كلمة المرور؟ | _ |
| login_screen.dart:1042 | Login button | تسجيل الدخول | _ |
| login_screen.dart:1063 | Divider word | أو | _ |
| login_screen.dart:1086 | Face-ID login button | تسجيل الدخول بـ Face ID | _ |
| login_screen.dart:1119 | Social-divider text | أو سجّل / ادخل بـ | _ |

### Signup

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| signup_screen.dart:89 | Signup timeout | انتهت مهلة التسجيل، يرجى المحاولة مرة أخرى | _ |
| signup_screen.dart:296 | Signup title | انضم إلينا | _ |
| signup_screen.dart:308 | Signup subtitle | ابدأ رحلتك في صلة الرحم | _ |
| signup_screen.dart:326 | Full-name label | الاسم الكامل | _ |
| signup_screen.dart:327 | Full-name hint | أدخل اسمك الكامل | _ |
| signup_screen.dart:332 | Name validator empty | الرجاء إدخال الاسم | _ |
| signup_screen.dart:335 | Name validator min-length | الاسم يجب أن يكون حرفين على الأقل | _ |
| signup_screen.dart:346 | Email label | البريد الإلكتروني | _ |
| signup_screen.dart:347 | Email hint | بريدك الإلكتروني | _ |
| signup_screen.dart:354 | Email validator empty | الرجاء إدخال البريد الإلكتروني | _ |
| signup_screen.dart:361 | Email validator format | البريد الإلكتروني غير صحيح | _ |
| signup_screen.dart:372 | Password label | كلمة المرور | _ |
| signup_screen.dart:393 | Password validator empty | الرجاء إدخال كلمة المرور | _ |
| signup_screen.dart:396 | Password min length | كلمة المرور يجب أن تكون 8 أحرف على الأقل | _ |
| signup_screen.dart:399 | Password needs uppercase | يجب أن تحتوي على حرف كبير واحد على الأقل | _ |
| signup_screen.dart:402 | Password needs lowercase | يجب أن تحتوي على حرف صغير واحد على الأقل | _ |
| signup_screen.dart:405 | Password needs digit | يجب أن تحتوي على رقم واحد على الأقل | _ |
| signup_screen.dart:416 | Confirm-password label | تأكيد كلمة المرور | _ |
| signup_screen.dart:438 | Confirm-password validator empty | الرجاء تأكيد كلمة المرور | _ |
| signup_screen.dart:441 | Passwords mismatch | كلمة المرور غير متطابقة | _ |
| signup_screen.dart:451 | Submit button | إنشاء حساب | _ |
| signup_screen.dart:471 | "Already have account?" | لديك حساب بالفعل؟ | _ |
| signup_screen.dart:489 | Login link | سجّل الدخول | _ |

### Email verification

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| email_verification_screen.dart:130 | Verification-sent toast | تم إرسال رابط التحقق إلى بريدك الإلكتروني | _ |
| email_verification_screen.dart:244 | Title | تحقق من بريدك الإلكتروني | _ |
| email_verification_screen.dart:257 | Subtitle prefix | أرسلنا رابط التحقق إلى | _ |
| email_verification_screen.dart:293 | Helper instructions | افتح بريدك الإلكتروني واضغط على رابط التحقق للمتابعة | _ |
| email_verification_screen.dart:307 | Resend button | إعادة إرسال الرابط | _ |
| email_verification_screen.dart:323 | Resend cooldown ("$_resendCooldown") | انتظر $_resendCooldown ثانية | _ |
| email_verification_screen.dart:357 | Already-verified link | لقد تحققت بالفعل | _ |
| email_verification_screen.dart:380 | Back-to-login | العودة لتسجيل الدخول | _ |

_Phone-verification screen (`phone_verification_screen.dart`) — extracted but omitted here since the route is not in the active auth flow. Strings: تأكيد رقم الجوال، أدخل رقم جوالك، إرسال رمز التحقق، رمز التحقق غير صحيح، تم تأكيد رقم الجوال بنجاح. Review separately if re-enabled._

### Name-prompt dialog (post-social-login)

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| name_prompt_dialog.dart:64 | Empty-name validation | الرجاء إدخال اسمك | _ |
| name_prompt_dialog.dart:71 | Name too short | الاسم قصير جداً | _ |
| name_prompt_dialog.dart:90 | Generic error | حدث خطأ، الرجاء المحاولة مرة أخرى | _ |
| name_prompt_dialog.dart:145 | Title | مرحباً بك! | _ |
| name_prompt_dialog.dart:156 | Subtitle | ما اسمك الذي تريد أن يظهر في التطبيق؟ | _ |
| name_prompt_dialog.dart:173 | Name field hint | أدخل اسمك | _ |
| name_prompt_dialog.dart:208 | Continue button | متابعة | _ |
| name_prompt_dialog.dart:224 | Skip-for-now link | تخطي الآن | _ |

### Auth error messages (auth_service.dart)

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| auth_service.dart:923 | Cancelled sign-in (Google) | تم إلغاء تسجيل الدخول | _ |
| auth_service.dart:940 | Google token failure | فشل في الحصول على رمز المصادقة من Google | _ |
| auth_service.dart:1037 | Apple token failure | فشل في الحصول على رمز المصادقة من Apple | _ |
| auth_service.dart:1182 | No-user-signed-in | لا يوجد مستخدم مسجل | _ |
| auth_service.dart:1286 | "Sign in first" | يرجى تسجيل الدخول أولاً | _ |
| auth_service.dart:1389 | Wrong creds | البريد الإلكتروني أو كلمة المرور غير صحيحة | _ |
| auth_service.dart:1391 | Email not confirmed | يرجى تأكيد بريدك الإلكتروني | _ |
| auth_service.dart:1394 | Email already used | البريد الإلكتروني مستخدم بالفعل | _ |
| auth_service.dart:1396 | Email invalid | البريد الإلكتروني غير صحيح | _ |
| auth_service.dart:1399 | Password too weak | كلمة المرور ضعيفة جداً (يجب أن تكون 6 أحرف على الأقل) | _ |
| auth_service.dart:1401 | No account with email | لا يوجد حساب بهذا البريد الإلكتروني | _ |
| auth_service.dart:1404 | Rate-limited | تم إجراء الكثير من المحاولات. يرجى المحاولة لاحقاً | _ |
| auth_service.dart:1407 | Network error | خطأ في الاتصال بالإنترنت | _ |
| auth_service.dart:1411 | Signups disabled | التسجيل معطل حالياً | _ |
| auth_service.dart:1415 | Server error | خطأ في الخادم. يرجى المحاولة لاحقاً | _ |
| auth_service.dart:1418 | Verification failure | فشل التحقق. يرجى المحاولة مرة أخرى | _ |
| auth_service.dart:1423 | Reset link expired | انتهت صلاحية الرابط. يرجى طلب رابط جديد | _ |
| auth_service.dart:1427 | Reset link invalid | الرابط غير صالح. يرجى طلب رابط جديد | _ |
| auth_service.dart:1432 | Open reset link from email | يرجى فتح رابط إعادة التعيين من البريد الإلكتروني | _ |
| auth_service.dart:1435 | Choose different password | يرجى اختيار كلمة مرور مختلفة عن السابقة | _ |
| auth_service.dart:1437 | New must differ from old | كلمة المرور الجديدة يجب أن تكون مختلفة عن القديمة | _ |
| auth_service.dart:1439 | Generic auth fallback | حدث خطأ ما. يرجى المحاولة مرة أخرى | _ |

---

## 3. Add Relative

### add_relative_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| add_relative_screen.dart:190 | Auth-required snackbar | يرجى تسجيل الدخول أولاً | _ |
| add_relative_screen.dart:341 | Save success snackbar | تم إضافة ${relative.fullName} بنجاح | _ |
| add_relative_screen.dart:458 | Divider | أو | _ |
| add_relative_screen.dart:497 | Manual-entry CTA | إضافة يدوياً | _ |
| add_relative_screen.dart:548 | Name field label | الاسم الكامل | _ |
| add_relative_screen.dart:549 | Name field hint | مثال: محمد أحمد | _ |
| add_relative_screen.dart:553 | Name empty validator | الرجاء إدخال الاسم | _ |
| add_relative_screen.dart:598 | Phone field label | رقم الهاتف (اختياري) | _ |
| add_relative_screen.dart:654 | Notes field label | ملاحظات (اختياري) | _ |
| add_relative_screen.dart:655 | Notes field hint | أي معلومات إضافية... | _ |
| add_relative_screen.dart:663 | Save button | حفظ القريب | _ |
| add_relative_screen.dart:719 | Discard-changes title | هل تريد الخروج بدون حفظ؟ | _ |
| add_relative_screen.dart:723 | Discard-changes body | ستفقد المعلومات التي أدخلتها. | _ |
| add_relative_screen.dart:729 | Keep-editing button | متابعة التعديل | _ |
| add_relative_screen.dart:734 | Discard button | تجاهل | _ |
| add_relative_screen.dart:758 | Screen title | إضافة قريب | _ |
| add_relative_screen.dart:807 | Add-image label | إضافة صورة | _ |
| add_relative_screen.dart:873 | Pick-from-contacts CTA | اختر من جهات الاتصال | _ |
| add_relative_screen.dart:882 | Tap-to-change subtitle | اضغط لتغيير جهة الاتصال | _ |
| add_relative_screen.dart:883 | Default subtitle | أسرع طريقة لإضافة قريب | _ |
| add_relative_screen.dart:1026 | Shared-tree toggle | ضيفه للعائلة المشتركة؟ | _ |
| add_relative_screen.dart:1055 | Group dropdown label | اختر المجموعة | _ |
| add_relative_screen.dart:1101 | Group required validator | الرجاء اختيار مجموعة | _ |

### contact_import_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| contact_import_screen.dart:105 | Load contacts error | خطأ في تحميل جهات الاتصال: $e | _ |
| contact_import_screen.dart:157 | Manual-name dialog title | أدخل الاسم | _ |
| contact_import_screen.dart:165 | Manual-name dialog hint | اسم القريب | _ |
| contact_import_screen.dart:175 | Cancel | إلغاء | _ |
| contact_import_screen.dart:191 | Add button | إضافة | _ |
| contact_import_screen.dart:206 | Pick-at-least-one warning | الرجاء اختيار جهة اتصال واحدة على الأقل | _ |
| contact_import_screen.dart:332 | Import success | تم استيراد $successCount جهة اتصال بنجاح! 🎉 | _ |
| contact_import_screen.dart:355 | Partial import error | فشل استيراد $errorCount جهة اتصال | _ |
| contact_import_screen.dart:368 | Generic import error | خطأ في الاستيراد: $e | _ |
| contact_import_screen.dart:460 | Importing button (loading) | جاري الاستيراد... | _ |
| contact_import_screen.dart:461 | Import button (with count) | استيراد (${_selectedContactIds.length}) | _ |
| contact_import_screen.dart:493 | Title (single) | اختر جهة اتصال | _ |
| contact_import_screen.dart:494 | Title (multi) | استيراد جهات الاتصال | _ |
| contact_import_screen.dart:503 | Subtitle (single) | اختر الشخص من جهات اتصالك | _ |
| contact_import_screen.dart:504 | Subtitle (multi) | اختر جهات الاتصال لإضافتهم كأقارب | _ |
| contact_import_screen.dart:525 | Search hint | ابحث عن جهة اتصال... | _ |
| contact_import_screen.dart:568 | Contacts count suffix | $count جهة اتصال | _ |
| contact_import_screen.dart:599 | Select-all toggle | تحديد الكل | _ |
| contact_import_screen.dart:627 | Empty state | لا توجد جهات اتصال | _ |
| contact_import_screen.dart:632 | Empty-search hint | جرب البحث بكلمة أخرى | _ |
| contact_import_screen.dart:703 | Manual-entry tile title | إدخال يدوي | _ |
| contact_import_screen.dart:711 | Manual-entry tile subtitle | اكتب الاسم يدوياً | _ |
| contact_import_screen.dart:839 | Permission gate title | إذن مطلوب | _ |
| contact_import_screen.dart:846 | Permission gate body | نحتاج إلى إذن للوصول إلى جهات الاتصال لاستيرادها | _ |
| contact_import_screen.dart:854 | Permission button | طلب الإذن | _ |

---

## 4. Log Interaction (relative detail)

### relative_detail_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| relative_detail_screen.dart:111 | Visit-dialog title | تسجيل زيارة | _ |
| relative_detail_screen.dart:112 | Visit-dialog hint | أضف ملاحظات عن الزيارة (اختياري) | _ |
| relative_detail_screen.dart:116 | Gift-dialog title | تسجيل هدية | _ |
| relative_detail_screen.dart:117 | Gift-dialog hint | ما هي الهدية؟ (اختياري) | _ |
| relative_detail_screen.dart:121 | Occasion-dialog title | تسجيل مناسبة | _ |
| relative_detail_screen.dart:122 | Occasion-dialog hint | ما هي المناسبة؟ (اختياري) | _ |
| relative_detail_screen.dart:155 | Recent-interactions section | التفاعلات الأخيرة | _ |
| relative_detail_screen.dart:193 | Not-found title | لم يتم العثور على القريب | _ |
| relative_detail_screen.dart:204 | Back button | رجوع | _ |
| relative_detail_screen.dart:299 | Cancel | إلغاء | _ |
| relative_detail_screen.dart:311 | Submit-log button | تسجيل | _ |
| relative_detail_screen.dart:339 | Call-log default note | مكالمة هاتفية | _ |
| relative_detail_screen.dart:346 | WhatsApp-log default note | رسالة واتساب | _ |
| relative_detail_screen.dart:353 | SMS-log default note | رسالة نصية | _ |
| relative_detail_screen.dart:439 | Streak-milestone snackbar | ✨ +$points نقطة · 🔥 وصلت لـ$streakDays يوم متواصل مع $relativeName | _ |
| relative_detail_screen.dart:445 | Streak-progress snackbar | +$points نقطة · 🔥 سلسلة $streakDays أيام مع $relativeName | _ |
| relative_detail_screen.dart:451 | Default-log success snackbar | +$points نقطة · تم تسجيل التواصل مع $relativeName | _ |
| relative_detail_screen.dart:462 | Voice-upload partial fail | تم تسجيل التواصل، لكن تعذّر رفع المقطع الصوتي. | _ |
| relative_detail_screen.dart:474 | Log failure | تعذّر تسجيل التواصل. حاول مرة أخرى. | _ |
| relative_detail_screen.dart:497 | Delete-confirm title | تأكيد الحذف | _ |
| relative_detail_screen.dart:510 | Delete-confirm body | هل أنت متأكد من حذف هذا القريب؟ | _ |
| relative_detail_screen.dart:515 | Delete-confirm name line | اسم: ${relative.fullName} | _ |
| relative_detail_screen.dart:525 | Delete-confirm relation line | صلة القرابة: ${getSideAwareLabel(...)} | _ |
| relative_detail_screen.dart:540 | Irreversibility note | هذا الإجراء لا يمكن التراجع عنه | _ |
| relative_detail_screen.dart:565 | Delete button | حذف | _ |
| relative_detail_screen.dart:605 | Delete success snackbar | تم حذف ${relative.fullName} بنجاح | _ |

### Detail-page widgets

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| relative_contact_actions.dart:52 | Action button | اتصال | _ |
| relative_contact_actions.dart:60 | Action button | واتساب | _ |
| relative_contact_actions.dart:69 | Action button | رسالة | _ |
| relative_contact_actions.dart:77 | Action button | تفاصيل | _ |
| relative_contact_actions.dart:95 | Log-interaction CTA | تسجيل تواصل | _ |
| relative_contact_actions.dart:110 | Log-type "visit" | زيارة | _ |
| relative_contact_actions.dart:120 | Log-type "gift" | هدية | _ |
| relative_contact_actions.dart:130 | Log-type "occasion" | مناسبة | _ |
| relative_contact_actions.dart:331 | Conversation-starters CTA | أفكار للحديث | _ |
| relative_header_widget.dart:137 | Favorite badge | مفضل | _ |
| relative_header_widget.dart:186 | Priority "high" | عالية | _ |
| relative_header_widget.dart:190 | Priority "medium" | متوسطة | _ |
| relative_header_widget.dart:194 | Priority "low" | منخفضة | _ |
| relative_details_card.dart:31 | Section title | التفاصيل | _ |
| relative_details_card.dart:42 | Field label | رقم الهاتف | _ |
| relative_details_card.dart:51 | Field label | البريد الإلكتروني | _ |
| relative_details_card.dart:61 | Field label | العنوان | _ |
| relative_details_card.dart:71 | Field label | المدينة | _ |
| relative_details_card.dart:81 | Field label | ملاحظات | _ |
| relative_details_card.dart:91 | Field label | أفضل وقت للتواصل | _ |
| relative_details_card.dart:101 | Field label | الجنس | _ |
| relative_stats_card.dart:32 | Stat label | آخر تواصل | _ |
| relative_stats_card.dart:34 | Stat value (none) | لم يتم | _ |
| relative_stats_card.dart:36 | Stat value (today) | اليوم | _ |
| relative_stats_card.dart:37 | Stat value (days ago) | منذ $daysSince يوم | _ |
| relative_stats_card.dart:49 | Stat label | التفاعلات | _ |
| relative_stats_card.dart:62 | Stat label | الحالة | _ |
| relative_stats_card.dart:63 | Status value needs/done | يحتاج تواصل / تم التواصل | _ |
| relative_interactions_list.dart:54 | Empty state | لا توجد تفاعلات بعد | _ |
| relative_interactions_list.dart:61 | Empty state CTA | ابدأ بتسجيل تواصلك مع هذا القريب | _ |
| relative_interactions_list.dart:194 | Photo count | ${count} صور | _ |
| relative_streak_badge.dart:78 | No-streak label | لا شعلة | _ |
| ai_conversation_starters_sheet.dart:153 | Sheet title | مواضيع للحديث | _ |
| ai_conversation_starters_sheet.dart:161 | Sheet subtitle | مع ${relative.fullName} | _ |
| ai_conversation_starters_sheet.dart:272 | Refresh button | اقتراحات جديدة | _ |
| ai_conversation_starters_sheet.dart:410 | Loading state | جاري توليد مواضيع للحديث... | _ |
| ai_conversation_starters_sheet.dart:463 | Error state | تعذر تحميل الاقتراحات | _ |
| ai_conversation_starters_sheet.dart:487 | Retry | إعادة المحاولة | _ |
| ai_conversation_starters_sheet.dart:518 | Copy success | تم نسخ الموضوع | _ |
| ai_conversation_starters_sheet.dart:585 | Copy button | نسخ | _ |

### edit_relative_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| edit_relative_screen.dart:257 | Update success | تم تحديث ${name} بنجاح! ✅ | _ |
| edit_relative_screen.dart:336 | Title | تعديل بيانات القريب | _ |
| edit_relative_screen.dart:363 | Field label | الاسم الكامل | _ |
| edit_relative_screen.dart:367 | Validator | الرجاء إدخال الاسم | _ |
| edit_relative_screen.dart:390 | Field label | رقم الهاتف | _ |
| edit_relative_screen.dart:399 | Field label | البريد الإلكتروني | _ |
| edit_relative_screen.dart:408 | Field label | العنوان | _ |
| edit_relative_screen.dart:416 | Field label | المدينة | _ |
| edit_relative_screen.dart:428 | Field label | ملاحظات | _ |
| edit_relative_screen.dart:449 | Save button | حفظ التعديلات | _ |
| edit_relative_screen.dart:630 | Section header | صلة القرابة | _ |
| edit_relative_screen.dart:689 | Priority section header | الأولوية | _ |
| edit_relative_screen.dart:696 | Auto-priority hint | تم تعيين الأولوية تلقائياً بناءً على صلة القرابة | _ |
| edit_relative_screen.dart:705 | Priority chip | عالية 🔥 | _ |
| edit_relative_screen.dart:708 | Priority chip | متوسطة ⭐ | _ |
| edit_relative_screen.dart:712 | Priority chip | منخفضة 📌 | _ |
| edit_relative_screen.dart:762 | Favorite toggle | إضافة للمفضلة | _ |
| edit_relative_screen.dart:798 | Avatar section header | اختر الأفاتار | _ |
| edit_relative_screen.dart:804 | Avatar section subtitle | اختياري - سيتم اقتراح أفاتار تلقائياً | _ |
| edit_relative_screen.dart:900 | "Suggested" badge | مقترح | _ |
| edit_relative_screen.dart:919 | Selected-avatar a11y | الأفاتار المختار: ${name} | _ |
| edit_relative_screen.dart:920 | Suggested-avatar a11y | الأفاتار المقترح: ${name} | _ |

---

## 5. Relatives list

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| relatives_screen.dart:137 | Loading | جاري تحميل الأقارب... | _ |
| relatives_screen.dart:170 | Page title | الأقارب | _ |
| relatives_screen.dart:200 | Search hint | ابحث عن قريب... | _ |
| relatives_screen.dart:244 | Filter chip | الكل | _ |
| relatives_screen.dart:248 | Filter chip | يحتاجون تواصل | _ |
| relatives_screen.dart:252 | Filter chip | المفضلة | _ |
| relatives_screen.dart:266 | Category chip | 🏠 أهل البيت | _ |
| relatives_screen.dart:270 | Category chip | 📞 ممتدة | _ |
| relatives_screen.dart:274 | Category chip | 🌙 مناسبات | _ |
| relatives_screen.dart:406 | Quick-log default note | تواصل سريع | _ |
| relatives_screen.dart:441 | Empty title | لا يوجد أقارب بعد | _ |
| relatives_screen.dart:449 | Empty body | ابدأ بإضافة أفراد عائلتك\nوالديك، إخوتك، أجدادك | _ |
| relatives_screen.dart:460 | Empty CTA | إضافة أول قريب | _ |
| relatives_screen.dart:486 | No-search-results title | لا توجد نتائج | _ |
| relatives_screen.dart:491 | No-search-results body | جرب البحث بكلمة أخرى | _ |
| relatives_screen.dart:521 | Error title | حدث خطأ في تحميل الأقارب | _ |
| relatives_screen.dart:527 | Error body | يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى | _ |
| relatives_screen.dart:540 | Retry button | إعادة المحاولة | _ |

---

## 6. Family Tree & Family Groups

### family_tree_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| family_tree_screen.dart:79 | Default tree title | شجرة العائلة | _ |
| family_tree_screen.dart:199 | Migrate-to-shared dialog title | نقل أقاربك إلى الشجرة المشتركة؟ | _ |
| family_tree_screen.dart:203 | Migrate dialog body | الأقارب اللي عندك حالياً: $count. تبي تنقلهم للشجرة المشتركة عشان أهل المجموعة يقدرون يشوفونهم؟ | _ |
| family_tree_screen.dart:209 | Keep-separate button | اتركهم منفصلين | _ |
| family_tree_screen.dart:213 | Move button | انقلهم | _ |
| family_tree_screen.dart:235 | Share text (capture) | شجرة عائلتي من صلني 🌳 | _ |
| family_tree_screen.dart:296 | Error title | تعذّر تحميل شجرة العائلة | _ |
| family_tree_screen.dart:302 | Error body | تحقق من الاتصال بالإنترنت ثم حاول مرة أخرى | _ |
| family_tree_screen.dart:316 | Retry button | إعادة المحاولة | _ |
| family_tree_screen.dart:365 | Snapshot fail | لا يمكن التقاط صورة الشجرة حالياً | _ |
| family_tree_screen.dart:402 | Share text (alt) | شجرة عائلتي من صِلني 🌳 | _ |
| family_tree_screen.dart:423 | Share-error snackbar | حدث خطأ أثناء المشاركة | _ |
| family_tree_screen.dart:436 | "Me" fallback name | أنا | _ |
| family_tree_screen.dart:575 | CTA card title | شارك شجرتك مع أفراد عائلتك | _ |
| family_tree_screen.dart:583 | CTA card body | أنشئ مجموعة عائلية ليتمكن أقاربك من رؤية الشجرة والمشاركة فيها | _ |
| family_tree_screen.dart:602 | Create-group CTA | إنشاء مجموعة عائلية ✨ | _ |
| family_tree_screen.dart:691 | Tooltip create-group | إنشاء مجموعة عائلية ✨ | _ |
| family_tree_screen.dart:695 | Tooltip share | مشاركة الشجرة | _ |
| family_tree_screen.dart:730 | Tooltip zoom-out | تصغير | _ |
| family_tree_screen.dart:744 | Tooltip zoom-in | تكبير | _ |
| family_tree_screen.dart:757 | Tooltip reset | إعادة ضبط | _ |
| family_tree_screen.dart:781 | Add-relative hint | لإضافة المزيد\nعم، خال، وغيرهم | _ |
| family_tree_screen.dart:867 | Add-relative pick contact | اختيار جهة اتصال | _ |
| family_tree_screen.dart:1370 | Add success | تم إضافة $fullName بنجاح | _ |
| family_tree_screen.dart:1378 | Add error | حدث خطأ أثناء الإضافة | _ |
| family_tree_screen.dart:1480 | Section heading | شجرة عائلتي | _ |
| family_tree_screen.dart:1512 | Error section | حدث خطأ في تحميل شجرة العائلة | _ |
| family_tree_screen.dart:1560 | Header pill | شجرة العائلة | _ |
| family_tree_screen.dart:1625 | Preview node label | الأب | _ |
| family_tree_screen.dart:1626 | Preview node label | الأم | _ |
| family_tree_screen.dart:1627 | Preview node label (you) | أنت | _ |
| family_tree_screen.dart:1628 | Preview node label | الأخ | _ |
| family_tree_screen.dart:1629 | Preview node label | الأخت | _ |
| family_tree_screen.dart:1630 | Preview node label | الابن | _ |
| family_tree_screen.dart:1867 | Premium upsell title | اكتشف شجرة عائلتك | _ |
| family_tree_screen.dart:1876 | Premium upsell body | اعرض شجرة عائلتك بشكل تفاعلي\nوشاركها مع أفراد عائلتك | _ |
| family_tree_screen.dart:1913 | Upgrade button | ترقية للاشتراك المميز | _ |

### create_group_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| create_group_screen.dart:87 | "Me" fallback | أنا | _ |
| create_group_screen.dart:113 | Create error | حدث خطأ أثناء إنشاء المجموعة: $e | _ |
| create_group_screen.dart:163 | Title | إنشاء مجموعة عائلية | _ |
| create_group_screen.dart:249 | Step 1 title | سمّ مجموعتك العائلية | _ |
| create_group_screen.dart:259 | Step 1 subtitle | اختر اسمًا لمجموعتك العائلية | _ |
| create_group_screen.dart:279 | Name field hint | مثال: عائلة الأحمد | _ |
| create_group_screen.dart:295 | Name validator empty | يرجى إدخال اسم المجموعة | _ |
| create_group_screen.dart:298 | Name validator min | اسم المجموعة يجب أن يكون حرفين على الأقل | _ |
| create_group_screen.dart:301 | Name validator max | اسم المجموعة يجب أن لا يتجاوز 50 حرف | _ |
| create_group_screen.dart:314 | Next button | التالي | _ |
| create_group_screen.dart:339 | Step 2 title | مراجعة الأقارب | _ |
| create_group_screen.dart:370 | Share-count summary | سيتم مشاركة ${count} من أقاربك | _ |
| create_group_screen.dart:439 | Submit | إنشاء المجموعة | _ |
| create_group_screen.dart:450 | Back step | السابق | _ |
| create_group_screen.dart:475 | No-relatives note | لا يوجد أقارب حالياً. يمكنك إضافتهم لاحقاً | _ |
| create_group_screen.dart:508 | Success message | تم إنشاء المجموعة بنجاح! | _ |
| create_group_screen.dart:531 | Invite-members CTA | دعوة أفراد العائلة | _ |
| create_group_screen.dart:549 | View-tree link | عرض شجرة العائلة | _ |

### join_group_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| join_group_screen.dart:58 | Invite invalid | رمز الدعوة غير صالح | _ |
| join_group_screen.dart:107 | Lookup-error | حدث خطأ أثناء البحث عن المجموعة | _ |
| join_group_screen.dart:169 | Invite-expired | رمز الدعوة غير صالح أو منتهي الصلاحية | _ |
| join_group_screen.dart:170 | Generic-join error | حدث خطأ أثناء الانضمام للمجموعة. يرجى المحاولة مرة أخرى | _ |
| join_group_screen.dart:213 | Title | انضمام لمجموعة عائلية | _ |
| join_group_screen.dart:257 | Unknown error | حدث خطأ غير معروف | _ |
| join_group_screen.dart:265 | Back-home button | العودة للرئيسية | _ |
| join_group_screen.dart:292 | Invite intro | تمت دعوتك للانضمام إلى | _ |
| join_group_screen.dart:329 | Already-member | أنت عضو بالفعل في هذه المجموعة | _ |
| join_group_screen.dart:339 | View-group button | عرض المجموعة | _ |
| join_group_screen.dart:347 | Login-required prompt | سجّل دخولك أولاً للانضمام | _ |
| join_group_screen.dart:355 | Login button | تسجيل الدخول | _ |
| join_group_screen.dart:366 | Join button | انضم للمجموعة | _ |

### family_group_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| family_group_screen.dart:89 | Remove-member dialog title | إزالة العضو | _ |
| family_group_screen.dart:95 | Remove-member dialog body | هل تريد إزالة ${name} من المجموعة؟ | _ |
| family_group_screen.dart:111 | Remove confirm button | إزالة | _ |
| family_group_screen.dart:134 | Removed snackbar | تمت إزالة العضو | _ |
| family_group_screen.dart:140 | Remove error | حدث خطأ أثناء إزالة العضو: ${msg} | _ |
| family_group_screen.dart:180 | Leave-with-transfer body | سيتم نقل الإدارة إلى ${name} ومغادرة المجموعة. متابعة؟ | _ |
| family_group_screen.dart:181 | Leave body | هل أنت متأكد من مغادرة هذه المجموعة؟ | _ |
| family_group_screen.dart:191 | Leave dialog title | مغادرة المجموعة | _ |
| family_group_screen.dart:213 | Leave confirm | مغادرة | _ |
| family_group_screen.dart:252 | Leave error | حدث خطأ أثناء مغادرة المجموعة: ${msg} | _ |
| family_group_screen.dart:272 | Choose-new-admin title | اختر المسؤول الجديد | _ |
| family_group_screen.dart:295 | Member-default name | عضو | _ |
| family_group_screen.dart:329 | Delete-group title | حذف المجموعة | _ |
| family_group_screen.dart:335 | Delete-group body | سيتم حذف المجموعة وجميع البيانات المشتركة نهائيًا. هل تريد المتابعة؟ | _ |
| family_group_screen.dart:351 | Delete confirm | حذف | _ |
| family_group_screen.dart:378 | Delete error | حدث خطأ أثناء حذف المجموعة: ${msg} | _ |
| family_group_screen.dart:439 | Group-default name | المجموعة | _ |
| family_group_screen.dart:471 | Not-found | لم يتم العثور على المجموعة | _ |
| family_group_screen.dart:563 | Renew-link error | حدث خطأ أثناء تجديد الرابط: ${msg} | _ |
| family_group_screen.dart:581 | Members section title | الأعضاء | _ |
| family_group_screen.dart:601 | Members error | حدث خطأ في تحميل الأعضاء | _ |
| family_group_screen.dart:612 | Members retry | إعادة المحاولة | _ |
| family_group_screen.dart:653 | Leave-group action | غادر المجموعة | _ |
| family_group_screen.dart:694 | Delete-group action | حذف المجموعة | _ |
| family_group_screen.dart:720 | No-members empty | لا يوجد أعضاء بعد | _ |
| family_group_screen.dart:790 | Admin badge | مسؤول | _ |

### invitation_detail_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| invitation_detail_screen.dart:60 | Invite-not-found | الدعوة غير موجودة أو لم تعد متاحة | _ |
| invitation_detail_screen.dart:76 | Load-error | حدث خطأ أثناء تحميل الدعوة | _ |
| invitation_detail_screen.dart:126 | Accept-success | تم قبول الدعوة بنجاح! مرحباً بك في العائلة | _ |
| invitation_detail_screen.dart:137 | Accept-error | حدث خطأ أثناء قبول الدعوة. يرجى المحاولة مرة أخرى | _ |
| invitation_detail_screen.dart:152 | Decline-confirm title | رفض الدعوة | _ |
| invitation_detail_screen.dart:159 | Decline-confirm body | هل تريد رفض الدعوة؟ | _ |
| invitation_detail_screen.dart:179 | Decline-confirm yes | نعم، رفض | _ |
| invitation_detail_screen.dart:235 | Title | دعوة عائلية | _ |
| invitation_detail_screen.dart:323 | Group-default name | مجموعة عائلية | _ |
| invitation_detail_screen.dart:333 | Inviter | دعاك ${name} | _ |
| invitation_detail_screen.dart:356 | Joining-as prefix | ستنضم كـ | _ |
| invitation_detail_screen.dart:374 | Accept | قبول الدعوة | _ |
| invitation_detail_screen.dart:386 | Decline | رفض | _ |

### Family group widgets

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| family_activity_card.dart:94 | Family activity card title | نشاط العائلة هالشهر | _ |
| family_activity_card.dart:101 | Family activity body | $familyName تواصلوا $totalInteractions مرة هالشهر | _ |
| family_activity_card.dart:108 | Active members | $activeMembers أعضاء نشطين | _ |
| family_leaderboard.dart:34 | Title | 🏆 ترتيب الأسبوع | _ |
| family_leaderboard.dart:52 | Error | حدث خطأ في تحميل الترتيب | _ |
| family_leaderboard.dart:84 | Empty | ما فيه تواصل هالأسبوع بعد\nكن أول واحد يتواصل! | _ |
| family_leaderboard.dart:208 | Subtitle | كلم $arabicCount أقارب هالأسبوع | _ |
| family_leaderboard.dart:226 | Share tooltip | شارك الإنجاز | _ |
| family_leaderboard.dart:235 | Member fallback | أحد الأعضاء | _ |
| family_leaderboard.dart:243 | Self-celebration | كلم $arabicCount أقارب هالأسبوع! | _ |
| family_leaderboard.dart:245 | Top-place share | $displayName كلم $arabicCount أقارب هالأسبوع 🥇 #صِلني | _ |
| family_activity_feed.dart:101 | Member fallback | عضو | _ |
| family_activity_feed.dart:103 | Relative fallback | قريب | _ |
| family_activity_feed.dart:145 | Section title | آخر أخبار العائلة | _ |
| family_activity_feed.dart:187 | Verb (call) | اتصل بـ | _ |
| family_activity_feed.dart:188 | Verb (visit) | زار | _ |
| family_activity_feed.dart:189 | Verb (message) | راسل | _ |
| family_activity_feed.dart:190 | Verb (gift) | أهدى | _ |
| family_activity_feed.dart:191 | Verb (default) | تواصل مع | _ |
| family_activity_feed.dart:238 | Time ago < 1h | قبل ${n} دقيقة | _ |
| family_activity_feed.dart:239 | Time ago < 1d | قبل ${n} ساعة | _ |
| family_activity_feed.dart:240 | Time ago = 1d | أمس | _ |
| family_activity_feed.dart:241 | Time ago > 1d | قبل ${n} أيام | _ |
| invite_link_card.dart:41 | Section title | رابط الدعوة | _ |
| invite_link_card.dart:86 | WhatsApp share label | واتساب | _ |
| invite_link_card.dart:96 | Share label | مشاركة | _ |
| invite_link_card.dart:124 | Renew link CTA | تجديد الرابط | _ |
| invite_link_card.dart:147 | Renew dialog title | تجديد رابط الدعوة | _ |
| invite_link_card.dart:153 | Renew dialog body | سيتم إلغاء الرابط القديم ولن يعمل بعد الآن. هل تريد المتابعة؟ | _ |
| invite_link_card.dart:169 | Renew confirm | تجديد | _ |
| invite_link_card.dart:185 | Copy snackbar | تم نسخ الرابط | _ |
| invite_link_card.dart:192 | WhatsApp text | انضم لعائلتنا في صِلني 🌳 $link | _ |
| invite_link_card.dart:208 | Share text | انضم لعائلتنا في صِلني 🌳 $link | _ |

---

## 7. Reminders

### reminders_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| reminders_screen.dart:143 | Loading | جاري تحميل البيانات... | _ |
| reminders_screen.dart:176 | Page title | تذكير صلة الرحم | _ |
| reminders_screen.dart:178 | Page subtitle | نظّم تذكيراتك للتواصل مع أحبتك | _ |
| reminders_screen.dart:268 | Section header | إنشاء تذكير جديد | _ |
| reminders_screen.dart:289 | Empty state title | لا توجد جداول تذكير بعد | _ |
| reminders_screen.dart:296 | Empty state body | أنشئ أول تذكير للبدء بالتواصل مع أحبتك | _ |
| reminders_screen.dart:305 | Empty state CTA | أنشئ أول تذكير | _ |
| reminders_screen.dart:326 | No-relatives empty title | لا يوجد أقارب بعد | _ |
| reminders_screen.dart:334 | No-relatives empty body | أضف أقاربك أولاً لتتمكن من إنشاء تذكيرات | _ |
| reminders_screen.dart:343 | Add-relatives CTA | إضافة أقارب | _ |
| reminders_screen.dart:369 | Error title | حدث خطأ في تحميل البيانات | _ |
| reminders_screen.dart:375 | Error body | يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى | _ |
| reminders_screen.dart:389 | Retry | إعادة المحاولة | _ |
| reminders_screen.dart:420 | Paywall headline | تذكيرات غير محدودة | _ |
| reminders_screen.dart:540 | Update error | حدث خطأ أثناء تحديث التذكير | _ |
| reminders_screen.dart:576 | Delete success | تم حذف التذكير | _ |
| reminders_screen.dart:584 | Delete error | حدث خطأ أثناء حذف التذكير | _ |
| reminders_screen.dart:626 | Remove-relative error | حدث خطأ أثناء إزالة القريب من التذكير | _ |
| reminders_screen.dart:689 | Delete-confirm title | حذف التذكير | _ |
| reminders_screen.dart:705 | Delete-confirm body | هل أنت متأكد من حذف هذا التذكير؟\nلا يمكن التراجع عن هذا الإجراء. | _ |

### reminders_due_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| reminders_due_screen.dart:72 | Loading | جاري تحميل التذكيرات... | _ |
| reminders_due_screen.dart:106 | Title | حان وقت التواصل | _ |
| reminders_due_screen.dart:113 | Subtitle | تواصل مع أحبتك اليوم | _ |
| reminders_due_screen.dart:277 | Total count | $totalCount أقارب للتواصل | _ |
| reminders_due_screen.dart:283 | Done count | تم التواصل مع $contactedCount | _ |
| reminders_due_screen.dart:305 | All-done banner | أحسنت! أكملت صلة رحمك اليوم | _ |
| reminders_due_screen.dart:410 | Last contact today | آخر تواصل: اليوم | _ |
| reminders_due_screen.dart:412 | Last contact yesterday | آخر تواصل: أمس | _ |
| reminders_due_screen.dart:413 | Last contact n days | آخر تواصل: منذ $daysSinceContact يوم | _ |
| reminders_due_screen.dart:438 | Action label | اتصال | _ |
| reminders_due_screen.dart:452 | Action label | واتساب | _ |
| reminders_due_screen.dart:467 | Action label | رسالة | _ |
| reminders_due_screen.dart:479 | Done/Details label | التفاصيل / تم | _ |
| reminders_due_screen.dart:505 | Empty title | لا يوجد أقارب للتواصل الآن | _ |
| reminders_due_screen.dart:513 | Empty body | أحسنت! أنت متواصل مع جميع أحبتك | _ |
| reminders_due_screen.dart:522 | Back-home | العودة للرئيسية | _ |
| reminders_due_screen.dart:547 | Error title | حدث خطأ في تحميل البيانات | _ |
| reminders_due_screen.dart:558 | Retry | إعادة المحاولة | _ |
| reminders_due_screen.dart:604 | Quick-log default note | تم التواصل من شاشة التذكيرات | _ |
| reminders_due_screen.dart:612 | Log success | تم تسجيل التواصل مع ${name} | _ |
| reminders_due_screen.dart:620 | Log error | حدث خطأ أثناء تسجيل التواصل | _ |

### Schedule dialogs / widgets

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| create_schedule_dialog.dart:69 | Validator weekday | يرجى اختيار يوم من أيام الأسبوع | _ |
| create_schedule_dialog.dart:79 | Validator day-of-month | يرجى اختيار يوم من الشهر | _ |
| create_schedule_dialog.dart:109 | Create success | تم إنشاء التذكير بنجاح | _ |
| create_schedule_dialog.dart:116 | Create error | حدث خطأ أثناء إنشاء التذكير | _ |
| create_schedule_dialog.dart:129 | Title (template) | إنشاء ${template.title} | _ |
| create_schedule_dialog.dart:156 | Time field | وقت التذكير | _ |
| create_schedule_dialog.dart:181 | Section title | يوم الأسبوع | _ |
| create_schedule_dialog.dart:184 | No-day-selected | لم يتم اختيار يوم بعد | _ |
| create_schedule_dialog.dart:207 | Day-of-month section | يوم من الشهر | _ |
| create_schedule_dialog.dart:210 | Pick day-of-month | اختر يوم من الشهر | _ |
| create_schedule_dialog.dart:211 | Selected day-of-month | اليوم $_selectedDayOfMonth | _ |
| create_schedule_dialog.dart:228 | Submit | إنشاء | _ |
| edit_schedule_dialog.dart:54 | Validator weekly | يرجى اختيار يوم للتذكير الأسبوعي | _ |
| edit_schedule_dialog.dart:63 | Validator monthly | يرجى اختيار يوم من الشهر | _ |
| edit_schedule_dialog.dart:91 | Update success | تم تحديث التذكير بنجاح | _ |
| edit_schedule_dialog.dart:107 | Title | تعديل التذكير | _ |
| edit_schedule_dialog.dart:120 | Field | وقت التذكير | _ |
| edit_schedule_dialog.dart:148 | Section | يوم الأسبوع | _ |
| edit_schedule_dialog.dart:180 | Section | يوم من الشهر | _ |
| edit_schedule_dialog.dart:204 | Save | حفظ | _ |
| reminder_templates_widget.dart:72 | Section header | اختر نوع التذكير | _ |
| add_relatives_dialog.dart:92 | Dialog title | إضافة أقارب للتذكير | _ |
| add_relatives_dialog.dart:140 | Add-success | تم إضافة ${count} أقارب للتذكير | _ |
| add_relatives_dialog.dart:174 | All-already-added | جميع الأقارب مضافون بالفعل | _ |
| add_relatives_dialog.dart:250 | Empty CTA | اختر أقارب | _ |
| add_relatives_dialog.dart:251 | Add CTA with count | إضافة (${count}) | _ |
| schedule_card_widget.dart:86 | Edit menu | تعديل | _ |
| schedule_card_widget.dart:123 | Delete menu | حذف | _ |
| schedule_card_widget.dart:165 | Relatives count | ${n} أقارب | _ |
| schedule_card_widget.dart:353 | Add CTA | إضافة أقارب | _ |
| schedule_card_widget.dart:411 | Empty hint | اضغط لإضافة أقارب | _ |
| smart_suggestion_widget.dart:83 | All scheduled | كل الأقارب مجدولين ✓ | _ |
| smart_suggestion_widget.dart:84 | Unscheduled count | أقارب بدون تذكير (${n}) | _ |
| smart_suggestion_widget.dart:372 | Picker title | اختر التذكير | _ |
| smart_suggestion_widget.dart:426 | No reminders | لا توجد تذكيرات | _ |
| smart_suggestion_widget.dart:427 | Already in all | مضاف لكل التذكيرات | _ |
| smart_suggestion_widget.dart:435 | First-create reminder | أنشئ تذكير أولاً لإضافة الأقارب | _ |
| smart_suggestion_widget.dart:436 | All reminders covered | هذا القريب مضاف لجميع التذكيرات المتاحة | _ |
| smart_suggestion_widget.dart:462 | Loading | جاري الإضافة... | _ |
| smart_suggestion_widget.dart:507 | Success | تمت الإضافة بنجاح! | _ |
| smart_suggestion_widget.dart:649 | Count valid | ${n} أقارب | _ |
| day_selector_widget.dart:44 | Hint single | اختر يوم واحد للتذكير الأسبوعي | _ |
| day_selector_widget.dart:45 | Hint multi | اختر أيام التذكير | _ |

---

## 8. AI Hub

### ai_hub_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| ai_hub_screen.dart:50 | Hub subtitle | مساعدك الذكي لصلة الرحم | _ |
| ai_hub_screen.dart:62 | Counselor card title | المستشار | _ |
| ai_hub_screen.dart:63 | Counselor card desc | محادثة ذكية للنصائح والمواقف الصعبة | _ |
| ai_hub_screen.dart:71 | Scripts card title | سيناريوهات التواصل | _ |
| ai_hub_screen.dart:72 | Scripts card desc | نصوص جاهزة لبدء المحادثات وإصلاح العلاقات | _ |
| ai_hub_screen.dart:80 | Weekly-report card title | التقرير الأسبوعي | _ |
| ai_hub_screen.dart:81 | Weekly-report card desc | ملخص أسبوعي لتواصلك مع أهلك | _ |

### ai_chat_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| ai_chat_screen.dart:281 | Welcome line 1 | مرحباً، أنا ${AIIdentity.name} | _ |
| ai_chat_screen.dart:301 | Welcome line 2 | مساعدك الذكي في صلة الرحم | _ |
| ai_chat_screen.dart:317 | Suggestions header | جرب أحد هذه الأسئلة | _ |
| ai_chat_screen.dart:384 | Edit-message dialog title | تعديل الرسالة | _ |
| ai_chat_screen.dart:403 | Edit-message hint | اكتب رسالتك المعدلة... | _ |
| ai_chat_screen.dart:436 | Cancel | إلغاء | _ |
| ai_chat_screen.dart:462 | Send | إرسال | _ |
| ai_chat_screen.dart:646 | Compose hint | اكتب رسالتك... | _ |
| ai_chat_screen.dart:710 | New-chat dialog title | بدء محادثة جديدة؟ | _ |
| ai_chat_screen.dart:718 | New-chat dialog body | سيتم مسح المحادثة الحالية وبدء محادثة جديدة | _ |
| ai_chat_screen.dart:761 | New-chat confirm | بدء جديدة | _ |
| ai_chat_screen.dart:213 | Drawer tooltip | المحادثات السابقة | _ |
| ai_chat_screen.dart:225 | New-chat tooltip | محادثة جديدة | _ |

### communication_scripts_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| communication_scripts_screen.dart:154 | Generate-error | حدث خطأ في إنشاء السيناريو | _ |
| communication_scripts_screen.dart:220 | Title | سيناريوهات التواصل | _ |
| communication_scripts_screen.dart:233 | Restart tooltip | البدء من جديد | _ |
| communication_scripts_screen.dart:321 | Loading line 1 | ${AIIdentity.name} يجهز السيناريو... | _ |
| communication_scripts_screen.dart:322 | Loading line 2 | يحلل الموقف... | _ |
| communication_scripts_screen.dart:323 | Loading line 3 | يصيغ العبارات المناسبة... | _ |
| communication_scripts_screen.dart:324 | Loading line 4 | يختار الكلمات بعناية... | _ |
| communication_scripts_screen.dart:325 | Loading line 5 | لحظات ويجهز... | _ |
| communication_scripts_screen.dart:371 | Step 1 title | اختر نوع السيناريو | _ |
| communication_scripts_screen.dart:385 | Step 1 subtitle | ${AIIdentity.name} يساعدك تصيغ كلامك بشكل مناسب | _ |
| communication_scripts_screen.dart:437 | Step 2 title | اختر القريب (اختياري) | _ |
| communication_scripts_screen.dart:462 | No-relative chip | بدون تحديد قريب | _ |
| communication_scripts_screen.dart:568 | Generate button | اكتب السيناريو | _ |
| communication_scripts_screen.dart:792 | With-relative subtitle | مع ${name} | _ |
| communication_scripts_screen.dart:816 | Section title | جملة الافتتاح | _ |
| communication_scripts_screen.dart:827 | Section title | النقاط الرئيسية | _ |
| communication_scripts_screen.dart:838 | Section title | عبارات مفيدة | _ |
| communication_scripts_screen.dart:850 | Section title | عبارات يجب تجنبها | _ |
| communication_scripts_screen.dart:862 | Section title | جملة الختام | _ |
| communication_scripts_screen.dart:907 | Copy-all CTA | نسخ الكل | _ |
| communication_scripts_screen.dart:959 | Copy-success snackbar | تم نسخ السيناريو كاملاً | _ |
| communication_scripts_screen.dart:1068 | Copied label | تم النسخ | _ |
| communication_scripts_screen.dart:1073 | Copy tooltip | نسخ | _ |

### weekly_report_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| weekly_report_screen.dart:109 | Empty-state body | أضف أقاربك لتحصل على تقرير مفصل عن علاقاتك العائلية. | _ |
| weekly_report_screen.dart:111 | Empty-state body 2 | ابدأ بإضافة والديك وإخوتك، ثم توسع لباقي العائلة. | _ |
| weekly_report_screen.dart:211 | AI fail fallback | تعذر إنشاء التقرير. حاول مرة أخرى. | _ |
| weekly_report_screen.dart:212 | Tip fallback | صلة الرحم تزيد في الرزق والعمر. | _ |
| weekly_report_screen.dart:334 | Title | التقرير الأسبوعي | _ |
| weekly_report_screen.dart:364 | Section header | ملخص صلة الرحم | _ |
| weekly_report_screen.dart:456 | AI summary header | ملخص ${AIIdentity.name} | _ |
| weekly_report_screen.dart:479 | Loading-text fallback | جاري تحليل بياناتك... | _ |
| weekly_report_screen.dart:520 | Generic loading | جاري التحليل... | _ |
| weekly_report_screen.dart:582 | Stats header | إحصائيات الأسبوع | _ |
| weekly_report_screen.dart:601 | Stat label | تواصل | _ |
| weekly_report_screen.dart:610 | Stat label | معدل يومي | _ |
| weekly_report_screen.dart:619 | Stat label | أيام متتالية | _ |
| weekly_report_screen.dart:742 | Most-contacted label | أكثر من تواصلت معهم | _ |
| weekly_report_screen.dart:891 | Tip header | نصيحة الأسبوع | _ |
| weekly_report_screen.dart:910 | Loading | جاري التحميل... | _ |
| weekly_report_screen.dart:919 | Default tip | صلة الرحم تزيد في الرزق وتبارك في العمر. | _ |

### occasion_messages_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| occasion_messages_screen.dart:62 | Loading line 1 (Ramadan) | يكتب رسائل رمضان مميزة... | _ |
| occasion_messages_screen.dart:63 | Loading line 2 | يختار كلمات دافئة لعائلتك... | _ |
| occasion_messages_screen.dart:64 | Loading line 3 | يراعي شخصية كل فرد... | _ |
| occasion_messages_screen.dart:65 | Loading line 4 | لحظات وتكون الرسائل جاهزة... | _ |
| occasion_messages_screen.dart:70 | Loading line 1 (Eid) | يكتب رسائل العيد لأحبابك... | _ |
| occasion_messages_screen.dart:71 | Loading line 2 (Eid) | يختار كلمات تناسب كل شخص... | _ |
| occasion_messages_screen.dart:77 | Loading line 1 (National) | يكتب رسائل اليوم الوطني... | _ |
| occasion_messages_screen.dart:78 | Loading line 2 (National) | يختار كلمات وطنية مميزة... | _ |
| occasion_messages_screen.dart:137 | Title | ${emoji} رسائل ${occasionArabicName} | _ |
| occasion_messages_screen.dart:159 | Empty body | أضف أقاربك أولا لتظهر لك الرسائل | _ |
| occasion_messages_screen.dart:227 | Error | حدث خطأ في تحميل الأقارب | _ |
| occasion_messages_screen.dart:312 | Copy success | تم نسخ رسالة ${name} | _ |
| occasion_messages_screen.dart:321 | Copy tooltip | نسخ | _ |
| occasion_messages_screen.dart:334 | Share suffix tag | #صِلني | _ |
| occasion_messages_screen.dart:342 | Share-as-card tooltip | مشاركة كبطاقة | _ |
| occasion_messages_screen.dart:360 | WhatsApp tooltip | واتساب | _ |
| occasion_messages_screen.dart:380 | Share tooltip | مشاركة | _ |

---

## 9. Settings & Profile

### settings_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| settings_screen.dart:58 | Section header | الحساب | _ |
| settings_screen.dart:61 | Tile | الملف الشخصي | _ |
| settings_screen.dart:68 | Tile | تغيير كلمة المرور | _ |
| settings_screen.dart:75 | Tile | تسجيل الخروج | _ |
| settings_screen.dart:98 | Tile (destructive) | حذف الحساب | _ |
| settings_screen.dart:112 | Section header | التطبيق | _ |
| settings_screen.dart:117 | Tile | الإشعارات | _ |
| settings_screen.dart:125 | Tile | دعوة صديق | _ |
| settings_screen.dart:133 | Invite-friend share text | حمّل تطبيق صِلني وصِل رحمك 🌳\n\n | _ |
| settings_screen.dart:144 | Tile | قيّم التطبيق | _ |
| settings_screen.dart:160 | Section header | الاشتراك | _ |
| settings_screen.dart:176 | Page title | الإعدادات | _ |
| settings_screen.dart:331 | Change-pwd dialog title | تغيير كلمة المرور | _ |
| settings_screen.dart:349 | Current pwd label | كلمة المرور الحالية | _ |
| settings_screen.dart:355 | Validator empty | الرجاء إدخال كلمة المرور الحالية | _ |
| settings_screen.dart:364 | New pwd label | كلمة المرور الجديدة | _ |
| settings_screen.dart:370 | Validator empty | الرجاء إدخال كلمة المرور الجديدة | _ |
| settings_screen.dart:373 | Validator min | كلمة المرور يجب أن تكون 8 أحرف على الأقل | _ |
| settings_screen.dart:391 | Confirm-pwd label | تأكيد كلمة المرور الجديدة | _ |
| settings_screen.dart:430 | User-not-found error (raw) | المستخدم غير موجود | _ |
| settings_screen.dart:449 | Pwd-changed snackbar | تم تغيير كلمة المرور بنجاح | _ |
| settings_screen.dart:467 | Pwd-change-error snackbar | حدث خطأ أثناء تغيير كلمة المرور | _ |
| settings_screen.dart:486 | Submit button | تغيير | _ |

### profile_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| profile_screen.dart:101 | Section header | 📊 إحصائياتي | _ |
| profile_screen.dart:127 | Section header | 👨‍👩‍👧 العائلة المشتركة | _ |
| profile_screen.dart:149 | CTA | إنشاء مجموعة عائلية ✨ | _ |
| profile_screen.dart:153 | CTA subtitle | شارك شجرتك مع أهلك ليرى كل واحد علاقاته | _ |
| profile_screen.dart:171 | Group tile | مجموعتي العائلية | _ |
| profile_screen.dart:175 | Group subtitle | إدارة الأعضاء والدعوات | _ |
| profile_screen.dart:202 | Section header | ⚙️ إعدادات الحساب | _ |
| profile_screen.dart:221 | Privacy-soon snackbar | إعدادات الخصوصية قريباً | _ |
| profile_screen.dart:250 | Settings button | الإعدادات | _ |
| profile_screen.dart:276 | Sign-out button | تسجيل الخروج | _ |
| profile_screen.dart:311 | User fallback | المستخدم | _ |
| profile_screen.dart:355 | Avatar update success | تم تحديث الصورة الشخصية بنجاح! ✅ | _ |
| profile_screen.dart:389 | Empty-name validation | الاسم لا يمكن أن يكون فارغاً | _ |
| profile_screen.dart:398 | Min-length validation | الاسم يجب أن يكون حرفين على الأقل | _ |
| profile_screen.dart:424 | Name save success | تم حفظ الاسم بنجاح | _ |

### profile_dialogs.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| profile_dialogs.dart:34 | Image-source dialog title | اختر مصدر الصورة | _ |
| profile_dialogs.dart:44 | Gallery option | المعرض | _ |
| profile_dialogs.dart:55 | Camera option | الكاميرا | _ |
| profile_dialogs.dart:69 | Cancel | إلغاء | _ |
| profile_dialogs.dart:90 | Auth required | يرجى تسجيل الدخول أولاً | _ |
| profile_dialogs.dart:104 | Export paywall headline | صدّر بياناتك مع صِلني MAX | _ |
| profile_dialogs.dart:149 | Delete-step1 title | حذف الحساب | _ |
| profile_dialogs.dart:158 | Delete-step1 body | هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك بشكل نهائي ولا يمكن التراجع عن هذا الإجراء. | _ |
| profile_dialogs.dart:163 | Subscription-not-cancelled note | ملاحظة: اشتراك صلني MAX مرتبط بحساب Apple أو Google عندك، وحذف الحساب لا يلغي الاشتراك. لإلغاء الاشتراك افتح إعدادات متجر التطبيقات > الاشتراكات. | _ |
| profile_dialogs.dart:187 | Continue button | متابعة | _ |
| profile_dialogs.dart:219 | Delete success | تم حذف حسابك بنجاح | _ |
| profile_dialogs.dart:273 | Verification fallback | تعذّر التحقق من البريد الإلكتروني — حاول تسجيل الخروج وإعادة الدخول. | _ |
| profile_dialogs.dart:311 | Step-2 title | تأكيد حذف الحساب | _ |
| profile_dialogs.dart:320 | Confirm-word prompt | اكتب كلمة "$_confirmWord" لتأكيد طلبك: | _ |
| profile_dialogs.dart:343 | Re-auth prompt | أدخل كلمة المرور لتأكيد هويتك: | _ |
| profile_dialogs.dart:354 | Password hint | كلمة المرور | _ |
| profile_dialogs.dart:401 | Final delete CTA | احذف الحساب | _ |

### profile_actions_widget.dart, profile_info_card.dart, profile_header_widget.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| profile_actions_widget.dart:31 | Tile | الخصوصية والأمان | _ |
| profile_actions_widget.dart:50 | Tile | تصدير بياناتي | _ |
| profile_actions_widget.dart:54 | Tile subtitle | تحميل نسخة من جميع بياناتك | _ |
| profile_actions_widget.dart:75 | Tile | حذف الحساب | _ |
| profile_info_card.dart:31 | Section title | معلومات الحساب | _ |
| profile_info_card.dart:43 | Field label | البريد الإلكتروني | _ |
| profile_info_card.dart:44 | Email fallback | غير متوفر | _ |
| profile_info_card.dart:52 | Field label | حالة التحقق | _ |
| profile_info_card.dart:54 | Verified value | تم التحقق ✓ | _ |
| profile_info_card.dart:55 | Unverified value | لم يتم التحقق | _ |
| profile_info_card.dart:63 | Field label | تاريخ الانضمام | _ |
| profile_header_widget.dart:33 | Default name | المستخدم | _ |

### Paywall

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| paywall_screen.dart:42 | Feature blurb (AI chat) | احصل على مساعد ذكي لعلاقاتك | _ |
| paywall_screen.dart:43 | Feature blurb (reminders) | لا تنسَ أحداً — تذكيرات بلا حدود | _ |
| paywall_screen.dart:44 | Feature blurb (analytics) | اعرف من تواصلت معه ومن نسيته | _ |
| paywall_screen.dart:45 | Feature blurb (tree) | شاهد شجرة عائلتك التفاعلية | _ |
| paywall_screen.dart:46 | Feature blurb (weekly) | تقارير أسبوعية عن تواصلك | _ |
| paywall_screen.dart:47 | Feature blurb (occasion) | رسائل مناسبات بالذكاء الاصطناعي | _ |
| paywall_screen.dart:48 | Feature blurb (scripts) | نصوص جاهزة للتواصل مع أقاربك | _ |
| paywall_screen.dart:49 | Feature blurb (export) | صدّر بياناتك بصيغة JSON | _ |
| paywall_screen.dart:152 | Headline (post-trial) | ميزات كنت تستخدمها | _ |
| paywall_screen.dart:152 | Headline (default) | الاشتراك المميز | _ |
| paywall_screen.dart:206 | Trial-end body | لقد جربت واصل — مساعدك الذكي للعائلة | _ |
| paywall_screen.dart:213 | Trial-end CTA-line | استمر بالاستمتاع بالميزات المميزة | _ |
| paywall_screen.dart:253 | Trial badge title | جرّب MAX مجاناً — ٠ ريال لمدة $trialDuration | _ |
| paywall_screen.dart:260 | Trial badge subtitle | استكشف جميع الميزات بدون التزام | _ |
| paywall_screen.dart:279 | Compare title | مقارنة الخطط | _ |
| paywall_screen.dart:290 | Compare row | إدارة الأقارب | _ |
| paywall_screen.dart:291 | Compare row | شجرة العائلة | _ |
| paywall_screen.dart:292 | Compare row | المظاهر المخصصة | _ |
| paywall_screen.dart:293 | Compare row | التذكيرات | _ |
| paywall_screen.dart:294 | Compare row | مساعد AI | _ |
| paywall_screen.dart:295 | Compare row | كتابة الرسائل | _ |
| paywall_screen.dart:296 | Compare row | تحليل العلاقات | _ |
| paywall_screen.dart:297 | Compare row | إحصائيات متقدمة | _ |
| paywall_screen.dart:298 | Compare row | لوحة المتصدرين | _ |
| paywall_screen.dart:299 | Compare row | تصدير البيانات | _ |
| paywall_screen.dart:313 | Plan label | مجاني | _ |
| paywall_screen.dart:407 | Plan toggle | شهري | _ |
| paywall_screen.dart:436 | Plan toggle | سنوي | _ |
| paywall_screen.dart:452 | Savings badge | وفر $savingsPercent% | _ |
| paywall_screen.dart:496 | Period word | سنوياً / شهرياً | _ |
| paywall_screen.dart:530 | Plan name | صلني MAX | _ |
| paywall_screen.dart:566 | Monthly equivalent | ≈ ${n} ${currency}/شهرياً | _ |
| paywall_screen.dart:578 | Plan feature | مساعد الذكاء الاصطناعي | _ |
| paywall_screen.dart:579 | Plan feature | سيناريوهات التواصل | _ |
| paywall_screen.dart:580 | Plan feature | التقرير الأسبوعي | _ |
| paywall_screen.dart:581 | Plan feature | تذكيرات غير محدودة | _ |
| paywall_screen.dart:582 | Plan feature | تصدير البيانات | _ |
| paywall_screen.dart:608 | Footer link | استعادة المشتريات | _ |
| paywall_screen.dart:627 | Footer link | سياسة الخصوصية | _ |
| paywall_screen.dart:644 | Footer link | الشروط والأحكام | _ |
| paywall_screen.dart:665 | Trial CTA | ابدأ التجربة المجانية | _ |
| paywall_screen.dart:667 | Continue-MAX CTA | استمر مع صلني MAX | _ |
| paywall_screen.dart:710 | Subscribe button | اشترك بـ ${price}/$period | _ |
| paywall_screen.dart:712 | Subscribe button (no price) | اشترك الآن | _ |
| paywall_screen.dart:717 | No-offers error | لا توجد عروض متاحة حالياً | _ |
| paywall_screen.dart:766 | Product-missing error | المنتج غير متاح - تأكد من إكمال بيانات المنتج في App Store Connect | _ |
| paywall_screen.dart:769 | Generic purchase error | حدث خطأ أثناء الشراء | _ |
| paywall_screen.dart:803 | No prior purchases | لم يتم العثور على مشتريات سابقة | _ |

### Subscription card

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| subscription_card.dart:118 | Trial-active subtitle | تجربة مجانية — متبقي $trialDays أيام | _ |
| subscription_card.dart:120 | Renews-on subtitle | يجدّد ${date} | _ |
| subscription_card.dart:121 | Active subtitle | مفعّل | _ |
| subscription_card.dart:158 | Card title | الاشتراك | _ |
| subscription_card.dart:191 | Manage button | إدارة | _ |
| subscription_card.dart:332 | Upgrade CTA | ترقية لـ MAX | _ |
| subscription_card.dart:358 | Restore | استعادة المشتريات | _ |
| subscription_card.dart:478 | Upgrade subtitle | ترقية للحصول على ميزات أكثر | _ |
| subscription_card.dart:509 | Upgrade button | ترقية الآن | _ |
| subscription_card.dart:545 | Manage iOS hint | افتح الإعدادات > Apple ID > الاشتراكات | _ |
| subscription_card.dart:559 | Manage Android hint | افتح متجر Google Play > الاشتراكات | _ |
| subscription_card.dart:573 | Restoring | جاري استعادة المشتريات... | _ |
| subscription_card.dart:586 | Restore success | تم استعادة الاشتراك بنجاح! | _ |
| subscription_card.dart:587 | No prior purchases | لم يتم العثور على مشتريات سابقة | _ |
| subscription_card.dart:597 | Restore error | حدث خطأ أثناء استعادة المشتريات | _ |

### Notifications screens

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| notifications_screen.dart:88 | Section title | إدارة إشعارات صلني من إعدادات النظام | _ |
| notifications_screen.dart:97 | Body | لتشغيل أو إيقاف التذكيرات والإشعارات، افتح إعدادات الإشعارات الخاصة بصلني من خلال إعدادات النظام. | _ |
| notifications_screen.dart:107 | CTA | افتح إعدادات النظام | _ |
| notifications_screen.dart:146 | Open-failed (iOS) | تعذّر فتح الإعدادات. افتح إعدادات الجهاز > صلني > الإشعارات. | _ |
| notifications_screen.dart:156 | Open-failed (Android) | افتح إعدادات الجهاز > التطبيقات > صلني > الإشعارات. | _ |
| notifications_screen.dart:183 | Page title | إعدادات الإشعارات | _ |
| notification_history_screen.dart:53 | Loading | جاري تحميل الإشعارات... | _ |
| notification_history_screen.dart:89 | Page title | الإشعارات | _ |
| notification_history_screen.dart:96 | Subtitle | سجل الإشعارات السابقة | _ |
| notification_history_screen.dart:114 | Mark-all-read snackbar | تم تحديد جميع الإشعارات كمقروءة | _ |
| notification_history_screen.dart:119 | Mark-all-read tooltip | تحديد الكل كمقروء | _ |
| notification_history_screen.dart:323 | Time "now" | الآن | _ |
| notification_history_screen.dart:325 | Time "n minutes ago" | منذ ${n} دقيقة | _ |
| notification_history_screen.dart:327 | Time "n hours ago" | منذ ${n} ساعة | _ |
| notification_history_screen.dart:329 | Time "yesterday" | أمس | _ |
| notification_history_screen.dart:331 | Time "n days ago" | منذ ${n} أيام | _ |
| notification_history_screen.dart:393 | Empty title | لا توجد إشعارات | _ |
| notification_history_screen.dart:400 | Empty body | ستظهر إشعاراتك هنا | _ |
| notification_history_screen.dart:422 | Error title | حدث خطأ في تحميل الإشعارات | _ |

---

## 10. Home

### home_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| home_screen.dart:140 | Default badge name | وسام جديد | _ |
| home_screen.dart:141 | Default badge desc | أحسنت! | _ |
| home_screen.dart:154 | Encouragement notif 1 | 💛 تذكير: عائلتك تشتاق لك — تواصل بسيط يفرق | _ |
| home_screen.dart:167 | Encouragement notif 2 | 🤍 تذكير بسيط: وقت حلو تتواصل مع أهلك | _ |
| home_screen.dart:184 | Streak-freeze notif | ❄️ تم استخدام تجميد السلسلة! سلسلتك محمية اليوم | _ |
| home_screen.dart:205 | Loading | جاري تحميل الصفحة الرئيسية... | _ |
| home_screen.dart:215 | User fallback | المستخدم | _ |

### Home widgets

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| home_header_widget.dart:42 | Greeting (default) | السلام عليكم | _ |
| home_header_widget.dart:44 | Greeting (morning) | صباح الخير | _ |
| home_header_widget.dart:46 | Greeting (evening) | مساء الخير | _ |
| islamic_reminder_widget.dart:90 | Card variant title (hadith) | حديث اليوم | _ |
| islamic_reminder_widget.dart:91 | Card variant title (scholar) | قول العلماء | _ |
| quick_actions_widget.dart:31 | Action title | التذكيرات | _ |
| quick_actions_widget.dart:32 | Action subtitle | نظّم تذكيراتك | _ |
| quick_actions_widget.dart:43 | AI subtitle | مساعدك الذكي | _ |
| quick_actions_widget.dart:274 | Tree action title | شجرة العائلة | _ |
| quick_actions_widget.dart:281 | Tree action subtitle | اكتشف روابط عائلتك | _ |
| streak_badge_bar.dart:244 | Empty-state CTA | ابدأ رحلتك | _ |
| streak_badge_bar.dart:423 | Day word | يوم | _ |
| streak_badge_bar.dart:454 | Countdown ended | انتهى | _ |
| streak_badge_bar.dart:458 | Countdown hh+mm | ${h}س ${m}د | _ |
| streak_badge_bar.dart:460 | Countdown mm | ${m}د | _ |
| due_reminders_card.dart:107 | No-reminders title | لا توجد تذكيرات | _ |
| due_reminders_card.dart:115 | No-reminders body | أضف تذكيرات لتبقى على تواصل مع أقاربك | _ |
| due_reminders_card.dart:138 | Add reminder CTA | إضافة تذكير | _ |
| due_reminders_card.dart:180 | Unscheduled banner | لديك ${n} أقارب بدون تذكيرات | _ |
| due_reminders_card.dart:188 | Unscheduled subtitle | جدوّل تواصلك معهم لتبقى قريبًا منهم | _ |
| due_reminders_card.dart:227 | Good-coverage title | أنت على تواصل جيد! | _ |
| due_reminders_card.dart:235 | Good-coverage body | لا توجد تذكيرات لليوم | _ |
| due_reminders_card.dart:269 | Done-today title | أحسنت! أكملت مهامك | _ |
| due_reminders_card.dart:277 | Done-today body | تواصلت مع جميع الأقارب في تذكيراتك اليوم | _ |
| due_reminders_card.dart:308 | Section title | تذكيرات اليوم | _ |
| due_reminders_card.dart:374 | More-button | عرض ${n} المزيد... | _ |
| due_reminders_card.dart:504 | Mark-done button | تم | _ |
| todays_activity_widget.dart:64 | Section title | سجل التواصل | _ |
| todays_activity_widget.dart:104 | Relative fallback | قريب | _ |
| family_circles_widget.dart:64 | Circle label | أهل البيت | _ |
| family_circles_widget.dart:67 | Circle label | تواصل دائم | _ |
| family_circles_widget.dart:70 | Circle label | مناسبات | _ |
| family_circles_widget.dart:88 | Section title | عائلتك | _ |
| family_circles_widget.dart:105 | "View all" link | عرض الكل | _ |
| family_circles_widget.dart:379 | Add CTA | إضافة | _ |
| family_circles_widget.dart:404 | Empty title | ابدأ بإضافة أفراد عائلتك | _ |
| family_circles_widget.dart:412 | Empty body | أضف والديك، إخوتك، أجدادك وباقي أقاربك | _ |
| family_circles_widget.dart:420 | Empty CTA | إضافة أول قريب | _ |
| occasion_card.dart:40 | Eid teaser | رسائل العيد جاهزة لأقاربك ✉️ | _ |
| occasion_card.dart:42 | Ramadan teaser | رسائل رمضان جاهزة لأقاربك ✉️ | _ |
| occasion_card.dart:44 | National-day teaser | رسائل اليوم الوطني جاهزة لأقاربك ✉️ | _ |

---

## 11. Wrapped (yearly / monthly summary)

### monthly_wrapped_screen.dart

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| monthly_wrapped_screen.dart:84 | Error title | حدث خطأ أثناء تحميل الملخص | _ |
| monthly_wrapped_screen.dart:95 | Back button | رجوع | _ |
| monthly_wrapped_screen.dart:247 | Coverage praise (>=80%) | ما شاء الله! تواصلك مع عائلتك ممتاز | _ |
| monthly_wrapped_screen.dart:248 | Coverage praise (>=50%) | أحسنت! استمر في التواصل مع أقاربك | _ |
| monthly_wrapped_screen.dart:249 | Coverage praise (>=20%) | بداية طيبة، حاول تتواصل مع أقارب أكثر | _ |
| monthly_wrapped_screen.dart:250 | Coverage praise (low) | الشهر الجاي بإذن الله أفضل | _ |
| monthly_wrapped_screen.dart:398 | Month header prefix | شهر ${arabicMonthName} | _ |
| monthly_wrapped_screen.dart:418 | Section title | ملخص تواصلك | _ |
| monthly_wrapped_screen.dart:487 | Stat label | تفاعل هذا الشهر | _ |
| monthly_wrapped_screen.dart:509 | Stat unit | قريب | _ |
| monthly_wrapped_screen.dart:511 | Stat unit | تغطية | _ |
| monthly_wrapped_screen.dart:513 | Stat unit | أيام متتالية | _ |
| monthly_wrapped_screen.dart:585 | Top section | الأكثر تواصلاً | _ |
| monthly_wrapped_screen.dart:632 | Suffix | تفاعل | _ |
| monthly_wrapped_screen.dart:669 | Section title | أنواع تواصلك | _ |
| monthly_wrapped_screen.dart:753 | Personality intro | هذا أسلوبك في صلة الرحم | _ |
| monthly_wrapped_screen.dart:864 | Carousel hint | اسحب للمتابعة ← | _ |
| monthly_wrapped_screen.dart:958 | Share-card title | ملخص شهر ${arabicMonthName} | _ |
| monthly_wrapped_screen.dart:971 | Stat label | تفاعل | _ |
| monthly_wrapped_screen.dart:975 | Stat label | قريب | _ |
| monthly_wrapped_screen.dart:980 | Stat label | أيام متتالية | _ |
| monthly_wrapped_screen.dart:992 | Stat label | تغطية | _ |
| monthly_wrapped_screen.dart:997 | Stat label | أكثر نوع تواصل | _ |
| monthly_wrapped_screen.dart:1002 | Stat label | الأكثر تواصلاً | _ |
| monthly_wrapped_screen.dart:1041 | Share button | شارك ملخصك | _ |
| monthly_wrapped_screen.dart:1093 | Family wrap title | ملخص العائلة | _ |
| monthly_wrapped_screen.dart:1108 | Family stat | تفاعل عائلي | _ |
| monthly_wrapped_screen.dart:1112 | Family stat | أعضاء نشطين | _ |
| monthly_wrapped_screen.dart:1119 | Family top contributor | 🌟 الأكثر نشاطاً: ${name} | _ |

### Wrapped providers / models

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| wrapped_providers.dart:29 | Map key | إجمالي التواصلات | _ |
| wrapped_providers.dart:30 | Map key | عدد الأقارب | _ |
| wrapped_providers.dart:31 | Map key | نسبة التغطية | _ |
| wrapped_providers.dart:32 | Map key | أطول سلسلة تواصل | _ |
| wrapped_providers.dart:32 | Map value suffix | يوم | _ |
| wrapped_providers.dart:33 | Map key | التصنيف الحالي | _ |
| wrapped_providers.dart:37 | Map key | أكثر قريب تواصلاً | _ |
| wrapped_providers.dart:38 | Map key | عدد تواصلاته | _ |
| wrapped_providers.dart:42 | Map key | أكثر نوع تواصل | _ |
| wrapped_providers.dart:50 | Map key | توزيع التواصلات | _ |
| wrapped_providers.dart:54 | Map key | أيام نشطة | _ |
| wrapped_providers.dart:57 | Map key | أكثر شهر نشاطاً | _ |
| wrapped_providers.dart:58 | Map key | تواصلات الشهر الأكثر | _ |
| wrapped_providers.dart:282 | Member fallback | عضو | _ |
| wrapped_generator_service.dart:118,162 | Personality (default) | وصّال الرحم | _ |
| wrapped_generator_service.dart:125 | Personality (visits) | ملك الزيارات | _ |
| wrapped_generator_service.dart:130 | Personality (gifts) | الكريم | _ |
| wrapped_generator_service.dart:139 | Personality (night) | بومة الليل العائلية | _ |
| wrapped_generator_service.dart:148 | Personality (morning) | طائر الصباح العائلي | _ |
| wrapped_generator_service.dart:153 | Personality (coverage) | واصل العائلة | _ |
| wrapped_generator_service.dart:158 | Personality (calls) | صاحب المكالمات | _ |
| wrapped_card_widget.dart:76 | Card body suffix | تفاعل | _ |
| wrapped_card_widget.dart:90 | Watermark | صِلني | _ |

### Day / month names (used across reminders + wrapped + profile)

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| monthly_wrapped_model.dart:104-115 | Months | يناير، فبراير، مارس، أبريل، مايو، يونيو، يوليو، أغسطس، سبتمبر، أكتوبر، نوفمبر، ديسمبر | _ |
| monthly_wrapped_model.dart:121-127 | Weekday names | الاثنين، الثلاثاء، الأربعاء، الخميس، الجمعة، السبت، الأحد | _ |
| create_schedule_dialog.dart:52-58 | Weekday names (start Mon) | الاثنين … الأحد (same set) | _ |
| day_selector_widget.dart:26-32 | Weekday names (start Sun) | الأحد، الاثنين، … السبت | _ |
| activity_chart.dart:84 | Single-letter month labels | ي ف م أ م ي ي أ س أ ن د | _ |

---

## 12. Misc dialogs / errors

### Generic error sheet (shown across the app)

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| error_bottom_sheet.dart:51 | Default sheet title | حدث خطأ | _ |
| error_bottom_sheet.dart:94 | No-internet title | لا يوجد اتصال | _ |
| error_bottom_sheet.dart:95 | No-internet body | لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى. | _ |
| error_bottom_sheet.dart:108 | Session-expired title | انتهت صلاحية الجلسة | _ |
| error_bottom_sheet.dart:109 | Session-expired body | انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى. | _ |
| error_bottom_sheet.dart:225 | Retry button | إعادة المحاولة | _ |
| error_bottom_sheet.dart:235 | Cancel/OK button | إلغاء / حسناً | _ |

### app_errors.dart (default Arabic messages on AppError subclasses — surface depends on error)

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| app_errors.dart:32 | Network error | خطأ في الاتصال بالإنترنت | _ |
| app_errors.dart:48 | No internet | لا يوجد اتصال بالإنترنت | _ |
| app_errors.dart:66 | Timeout | انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى | _ |
| app_errors.dart:141 | Data load | خطأ في تحميل البيانات | _ |
| app_errors.dart:162 | Validation | بيانات غير صحيحة | _ |
| app_errors.dart:182 | Server | خطأ في الخادم، يرجى المحاولة لاحقاً | _ |
| app_errors.dart:199 | Local cache | خطأ في التخزين المحلي | _ |
| app_errors.dart:217 | Permission denied | تم رفض الإذن المطلوب | _ |
| app_errors.dart:251 | Unknown | حدث خطأ غير متوقع | _ |
| app_errors.dart:269 | Config | خطأ في إعدادات التطبيق | _ |
| app_errors.dart:289 | Not found | العنصر غير موجود | _ |

### Postgres / RPC error mappings (surfaced via error_handler service)

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| error_reporter.dart:141 | Unique-violation 23505 | هذا العنصر موجود بالفعل | _ |
| error_reporter.dart:144 | FK-violation 23503 | لا يمكن حذف هذا العنصر لوجود بيانات مرتبطة به | _ |
| error_reporter.dart:147 | RLS / 42501 | ليس لديك صلاحية للقيام بهذه العملية | _ |
| error_reporter.dart:151 | DB generic fallback | خطأ في قاعدة البيانات | _ |
| error_reporter.dart:171 | RPC: cross-user create | لا يمكن إنشاء مجموعة لمستخدم آخر | _ |
| error_reporter.dart:174 | RPC: empty group name | اسم المجموعة لا يمكن أن يكون فارغًا | _ |
| error_reporter.dart:177 | RPC: long group name | اسم المجموعة طويل جدًا | _ |
| error_reporter.dart:182 | RPC: cross-user transfer | لا يمكن نقل الإدارة لمستخدم آخر | _ |
| error_reporter.dart:185 | RPC: only-admin transfer | فقط المسؤولون يمكنهم نقل الإدارة | _ |
| error_reporter.dart:188 | RPC: only-admin remove | فقط المسؤولون يمكنهم إزالة الأعضاء | _ |
| error_reporter.dart:191 | RPC: cannot remove other admin | لا يمكن إزالة مسؤول آخر | _ |
| error_reporter.dart:195 | RPC: last admin | لا يمكن إزالة المسؤول الأخير من المجموعة | _ |
| error_reporter.dart:200 | RPC: leave on behalf | لا يمكن مغادرة المجموعة نيابة عن مستخدم آخر | _ |
| error_reporter.dart:205 | RPC: not a member | لست عضوًا في هذه المجموعة | _ |
| error_reporter.dart:208 | RPC: member not in group | العضو المطلوب غير موجود في المجموعة | _ |
| error_reporter.dart:211 | RPC: use leave option | استخدم خيار المغادرة لإزالة نفسك | _ |
| error_reporter.dart:216 | RPC: member not in tree | العضو المختار غير موجود في شجرة هذه المجموعة | _ |

### supabase_config.dart (init-time fatals — splash/login)

| File:line | Surface | Arabic text (verbatim) | ✅/✏️/❌ |
|---|---|---|---|
| supabase_config.dart:76 | Missing creds | بيانات الاعتماد مفقودة، يرجى إعادة بناء التطبيق | _ |
| supabase_config.dart:176 | Local-storage check fail | فشل التحقق من التخزين المحلي | _ |
| supabase_config.dart:239 | Supabase init network fail | فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى | _ |
| supabase_config.dart:253 | Not initialized | لم يتم تهيئة الاتصال بالخادم | _ |

---

## Notes for the founder

- **App name spelling:** The wordmark on splash uses fully-vocalized form **صِـلْـنِـي** (line 186 of `splash_screen.dart`). Other places use bare **صِلني**, **صلني**, or **صلني MAX**. Worth deciding on a single canonical spelling for marketing copy.
- **Dialect drift:** Some strings mix MSA (e.g. "هل تريد رفض الدعوة؟") with Khaleeji ("الشهر الجاي بإذن الله أفضل", "ما فيه تواصل هالأسبوع بعد", "كلم X أقارب هالأسبوع"). Decide whether you want consistency or if dialect is intentional in `family_leaderboard.dart` / `monthly_wrapped_screen.dart`.
- **Punctuation:** Mix of full-width comma "،" and "," — settle on Arabic comma everywhere.
- **"يوم" vs. "أيام":** Many counters use singular "يوم" with any number (e.g. `منذ $daysSince يوم`, `سلسلة $streakDays أيام`). Arabic plurals 3–10 take a specific plural; 11+ take singular. Worth a sweep.
- **Error fallbacks:** A lot of errors collapse to generic "حدث خطأ أثناء X" — fine, but you may want richer copy for the most-hit ones (login timeout, log-interaction failure, group-renew failure).
- **Strings excluded from this pass:** `RelationshipType.arabicLabel`, `InteractionType.arabicName`, `Avatar.arabicName`, `HadithModel`, `notification_templates.dart`, `relationship_label_helper.dart` perspective forms — review these as a separate enum-vocabulary pass since they're hundreds of single-word values.
