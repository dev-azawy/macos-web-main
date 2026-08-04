# macOS Web → تطبيق iOS (IPA) — دليل الإعداد

## اللي تم عمله في المشروع

- تمت إضافة تطبيقات: **Safari, Google, Chrome, GitHub, YouTube, Files** في الـ Dock.
- كل واحد منها (ما عدا Files) يفتح **نافذة متصفح حقيقية داخل التطبيق** — مش هيوديك لصفحة خارج النظام أو لتطبيق Safari الحقيقي على الجهاز.
- النوافذ بالكامل تدعم: سحب/تحريك (كان موجود أصلاً في المشروع)، تكبير/تصغير حر من الزاوية (تم إضافته)، وزر التكبير الكامل (Maximize) الموجود مسبقًا.
- الأيقونات المستخدمة **أشكال أصلية مستوحاة** من هوية كل تطبيق (بحث/متصفح/كود/تشغيل)، مش نسخة طبق الأصل من شعارات Google/Chrome/GitHub/YouTube المسجلة كعلامة تجارية — عشان تفادي مشاكل حقوق الملكية.

## ليه مش استخدمنا `<iframe>` بسيط؟

جوجل وGitHub بيرسلوا هيدر (`X-Frame-Options` / CSP) بيمنع عرض موقعهم جوه iframe. الحل اللي اتعمل: **Native Plugin بلغة Swift** (`packages/capacitor-native-webview`) بيفتح WKWebView حقيقي (مش iframe) ويحطه بالظبط فوق مكان نافذة الـ Safari/Google/... في الواجهة، ويحرّكه مع كل حركة سحب/تكبير للنافذة 60 مرة في الثانية. النتيجة: شكل ووظيفة "نافذة داخل التطبيق"، وفي نفس الوقت المواقع بتفتح فعليًا.

**قيود معروفة على هذا الحل:**
- الـ WKWebView الأصلي بيتحط دايمًا **فوق كل حاجة** في الواجهة (فوق الـ Dock والقوائم) طول ما هو مفتوح، لأنه مش جزء من نظام الـ z-index بتاع Svelte. لو فتحت أكتر من نافذة متصفح في نفس الوقت هيتم ترتيبهم صح مع بعض، لكن هيفضلوا فوق باقي الواجهة.
- تطبيق **Files** بيقرأ بس مجلد "Documents" الخاص بالتطبيق نفسه (بسبب Sandbox في iOS) — مش هو تطبيق "الملفات" الحقيقي بتاع النظام. الوصول للملفات الحقيقية محتاج ميزة إضافية (Document Picker) ممكن نضيفها بعدين لو حبيت.

## خطوات الحصول على IPA

### الطريقة 1: بدون حساب Apple Developer (تجريبي / sideload)

1. ارفع المشروع كامل على GitHub.
2. من تبويب **Actions** شغّل الـ workflow اسمه **"Build Unsigned IPA"**.
3. بعد ما يخلص، حمّل الملف من **Artifacts** (اسمه `MacOSWeb-unsigned-ipa`).
4. الملف ده **مش موقّع (unsigned)** — مش هيتثبت بمجرد الضغط عليه. تحتاج تستخدم أداة زي:
   - **AltStore** أو **Sideloadly** على الكمبيوتر، تسجل دخول بـ Apple ID عادي (مجاني)، والأداة هتوقّع التطبيق وتثبته على جهازك.
   - التطبيق هيشتغل لمدة **7 أيام** بس (قيود حساب Apple المجاني) وتحتاج تجدد التوقيع كل أسبوع عن طريق AltStore (فيه ميزة تجديد تلقائي لو الجهاز متصل بنفس الشبكة).

### الطريقة 2: لو عندك حساب Apple Developer مدفوع (99$/سنة)

استخدم workflow **"Build Signed IPA"** بدل الأول. محتاج تضيف الأسرار دي في:
`Settings → Secrets and variables → Actions → New repository secret`

| اسم الـ Secret | الوصف |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | شهادة التوقيع `.p12` بصيغة base64 |
| `P12_PASSWORD` | باسورد الشهادة اللي حطيته وقت التصدير |
| `BUILD_PROVISION_PROFILE_BASE64` | ملف `.mobileprovision` بصيغة base64 |
| `KEYCHAIN_PASSWORD` | أي باسورد، بيتستخدم مؤقت جوه الـ CI |
| `APPLE_TEAM_ID` | الـ Team ID بتاعك من developer.apple.com/account |
| `PROVISIONING_PROFILE_SPECIFIER` | *اسم* الـ Provisioning Profile (مش الـ UUID) |

لتوليد `BUILD_CERTIFICATE_BASE64` و`BUILD_PROVISION_PROFILE_BASE64` من أي جهاز (حتى ويندوز/لينكس):
```
base64 -i Certificates.p12 | pbcopy      # على ماك
base64 -w0 Certificates.p12              # على لينكس
```

بعدها شغّل الـ workflow يدويًا من تبويب Actions واختار نوع التصدير (`ad-hoc` للتجربة على أجهزة محددة، أو `app-store` لو هترفعه على TestFlight/App Store).

## تغيير اسم التطبيق / Bundle ID

عدّل في `capacitor.config.ts`:
```ts
appId: 'com.azawy.macosweb',   // غيّره لأي bundle id بتاعك
appName: 'MacOSWeb',
```

## تشغيل محلي (لو حصلت على جهاز Mac لاحقًا)

```bash
pnpm install
pnpm run ios:sync    # يبني الويب ويعمل cap sync
pnpm run ios:open    # يفتح المشروع في Xcode
```
