# گزارش کشف و ارزیابی منابع Backend

تاریخ بررسی: 2026-10-27؛ پروژهٔ مرجع `C:/Projects/vehicle-inspection-integrated`؛ شاخه `feat/unified-ui-admin-3d`؛ Git مبنا `a0786ab51df6de1faaeeed989f647060c439453d`. ساختار واقعی کل `docs/`، ورودی‌های README، پوشه‌های API_FA، handover و AI_HANDOFF و منابع محصول، معماری، رسانه و استقرار بررسی شدند. مسیرهای زیر مسیر واقعی فعلی‌اند و بر نام‌های تاریخی فرض‌شده تکیه ندارند.

## پاسخ صریح دربارهٔ سند جامع قبلی

**نزدیک‌ترین سند موجود که همهٔ عملیات و قراردادهای API، جدول‌ها، ستون‌ها، DDL، ERD و هستهٔ گردش پروژه را یکجا دارد، `docs/handover/00-COMPLETE-BACKEND-SPECIFICATION-FA.md` است.** این سند واقعاً خودبسنده و تفصیلی است و ۲۷ بخش دارد؛ فقط مجموعه‌ای از لینک‌ها نیست. هستهٔ API و SQL آن دوباره طراحی نمی‌شود و فایل قبلی حفظ می‌شود.

هیچ سند موجودی تمام دامنهٔ درخواست تازه، شامل ساختار دقیق ۳۰ فصلی، گردش مستقل ۲۰ مرحله‌ای، فهرست تفصیلی قابلیت‌ها و محدودیت‌ها، گزارش کشف، ماتریس پوشش و اصلاحیهٔ تازهٔ Static Export را یکجا ندارد. بنابراین `handover_full.md` نمای همگام و قابل بازتولید تازه‌ای از همان منابع است. ایجاد آن برای تکمیل دامنه لازم است؛ ایجاد قرارداد یا schema مستقل و رقیب لازم نیست.

«کامل پیشنهادی» در جدول یعنی جزئیات برای بررسی و پیاده‌سازی پس از تصویب موجود است، نه اینکه API یا migration تولیدی اجرا شده باشد. «جاری» تازگی قاعده/مرز را بیان می‌کند، نه تضمین آمادگی تولید.

| موضوع | مسیر دقیق و بخش مربوط | کفایت | تازگی | اعتبار |
|---|---|---|---|---|
| ۱. هدف کسب‌وکار | `docs/02-project-overview/PROJECT_HANDBOOK.md`، محصول و مسئولیت‌ها؛ `docs/02-project-overview/PRODUCT_REQUIREMENTS.md`، محصول و نقش‌ها؛ `docs/API_FA/01-PROJECT-OVERVIEW.md`، رابطه با سامانه بیمه | کامل ترکیبی | جاری | قواعد محصول؛ طرح Backend پیشنهادی |
| ۲. تمام گردش مشتری | `docs/04-customer-workflow/CUSTOMER_WORKFLOW.md`، جدول مراحل، بازگشت، سیاست یازده‌عکسی؛ `docs/04-customer-workflow/CUSTOMER_MANUAL_FA.md`؛ `docs/API_FA/03-BUSINESS-REQUIREMENTS.md` | کامل ترکیبی | v2 جاری؛ v1 تاریخی | رفتار Frontend/قواعد قطعی؛ transport پیشنهادی |
| ۳. کارشناس و مدیر | `docs/API_FA/12-REVIEWER-OPERATIONS.md`، تراکنش تصمیم؛ `docs/API_FA/13-ADMIN-AND-SITE-SETTINGS.md`؛ `docs/05-admin-reviewer/REVIEWER_MANUAL_FA.md` و `ADMIN_MANUAL_FA.md` | کامل دامنهٔ فعلی؛ اختیارهای D10 باز | جاری و mock | الزام نقش/ارجاع قطعی؛ enforce سروری پیشنهادی |
| ۴. تمام عملیات Backend | `docs/12-api-reference/FRONTEND_API_REQUIREMENTS.md`، A تا G؛ `docs/API_FA/04-COMPLETE-API-REQUIREMENTS.md`؛ `docs/API_FA/contracts/operations.json` | کامل: ۶۳ عملیات | جاری؛ عملیات با endpoint فرق دارد | مرجع نیاز Frontend؛ قرارداد Backend پیشنهادی |
| ۵. قرارداد و JSON | `docs/API_FA/05-API-CONTRACTS.md`، P00 تا FW01، G01 تا G03 و فرهنگ DTO؛ `docs/API_FA/contracts/endpoints.json`، `schemas.json` و `examples.json` | کامل پیشنهادی: ۵۵ method/path و ۸۰ DTO؛ یک فایل عمومی جدا | جاری؛ AU02 مشروط | PROPOSED؛ D01/D04/D08 باز |
| ۶. تمام جدول‌ها | `docs/API_FA/06-DATABASE-DESIGN.md`؛ `docs/API_FA/sql/schema-manifest.json`، tables/classification | کامل: ۳۷ جدول؛ ۳۴ مسئولیت الزامی و ۳ مشروط | پیشنهاد جاری | SQL مصوب نیست؛ reuse نیازمند تصویب |
| ۷. تمام ستون‌ها | `docs/API_FA/24-DATABASE-TABLE-BLUEPRINTS.md`، شناسنامه و نمونهٔ هر جدول؛ `docs/API_FA/06-DATABASE-DESIGN.md` | کامل پیشنهادی: ۳۰۲ ستون، NULL، کلید، default، قید و index | همگام با manifest | اجرا نشده؛ نیازمند بررسی SQL |
| ۸. روابط و ERD | `docs/API_FA/07-DATABASE-RELATIONSHIPS.md`، جدول FK، قواعد فراتر از FK؛ `docs/API_FA/sql/DATABASE_DIAGRAM.md` | کامل: ۵۵ FK و کلید ترکیبی | جاری | پیشنهادی؛ تست migration واقعی لازم |
| ۹. نگاشت API/SQL | `docs/API_FA/20-API-DATABASE-MAPPING.md`، ماتریس و اثر تفصیلی عملیات | کامل برای ۶۳ عملیات | جاری | طرح پیشنهادیِ خواندن/نوشتن/فایل/تراکنش |
| ۱۰. رسانه و filesystem | `docs/12-api-reference/BROKERAGE_STORAGE_SPEC.md`، قواعد قطعی/چرخه؛ `docs/API_FA/08-MEDIA-FILE-STORAGE.md` و `09-UPLOAD-AND-MEDIA-PROCESSING.md` | کامل قواعد؛ limits/retention/path باز | جاری؛ ریشه مستقیم INSPECTION در BROKERAGE_STORAGE_SPEC و کد handoff Frontend تاریخی است | filesystem خصوصی قطعی؛ چیدمان `GUI_{CustomerId}/INSPECTION_{InspectionId}` پیشنهاد مرجح محصول و نیازمند تصویب Backend (D05) |
| ۱۱. هویت و SSO | `docs/08-auth-security/BROKERAGE_SSO_REQUIREMENTS.md`، توافق هویت؛ `docs/API_FA/10-AUTHENTICATION-AND-SSO.md`، مشتری/OTP/کارکنان/topology؛ `26-ROLES-AND-PERMISSIONS.md` در همان پوشه | الزام کامل؛ پروتکل/نشست تولیدی باز | جاری؛ restore محلی امنیت تولید نیست | مالکیت مبدأ قطعی؛ OIDC/ticket پیشنهادی |
| ۱۲. انتقال وضعیت | `docs/03-architecture/INSPECTION_STATE_MACHINE.md`؛ `docs/API_FA/11-INSPECTION-LIFECYCLE.md`؛ `src/features/inspection-status/lifecycle-model.ts` | کامل enum/محافظ فعلی؛ موتور سروری آینده | جاری؛ sending/retrying زیر FORWARD_PENDING | enum فعلی؛ تراکنش سروری پیشنهادی |
| ۱۳. امنیت و محدودیت دسترسی | `docs/08-auth-security/DATA_OWNERSHIP_AND_SECURITY.md`؛ `docs/API_FA/15-SECURITY-AND-TENANT-ISOLATION.md` و `26-ROLES-AND-PERMISSIONS.md` | کامل الزام؛ آزمون تولیدی تحویل نشده | جاری | معیار پذیرش، نه تضمین guard مرورگر |
| ۱۴. ارسال نهایی | `docs/API_FA/14-BROKERAGE-FORWARDING.md`، outbox/retry؛ `29-SOURCE-SYSTEM-CONTRACTS.md` در همان پوشه، تحویل نهایی؛ G02/G03/FW01 در قرارداد | مسئولیت کامل؛ URL/auth/payload نهایی باز | جاری؛ approval و delivery جدا | ack قطعی؛ قرارداد مقصد D11 پیشنهادی |
| ۱۵. White-Label | `docs/03-architecture/WHITE_LABEL_ARCHITECTURE.md`، تصمیم استقرار؛ `docs/09-deployment/WHITE_LABEL_CONFIGURATION.md`؛ `docs/API_FA/13-ADMIN-AND-SITE-SETTINGS.md` | کامل ترکیبی | معماری جاری؛ تعداد ۱۲ در سابقهٔ فاز ۱ تاریخی است | نصب/SQL/فایل مستقل و Neshan مرکزی قطعی؛ انتشار فعلاً mock |
| ۱۶. سرور و استقرار | `docs/API_FA/16-DEPLOYMENT-AND-SERVER-REQUIREMENTS.md`؛ `docs/09-deployment/STATIC_EXPORT_AUDIT.md`، موانع دقیق و اصلاحیه 2026-10-27؛ `STATIC_DEPLOYMENT_DECISION.md` در همان پوشه، گزینه A/دروازه؛ `docs/AI_HANDOFF/FULL_PROJECT_DEBUGGING_REPORT.md`، بخش ۸ | کامل موانع/طرح رفع؛ artifact کامل نداریم | probe تازه بر مسیر خطای probe قدیمی مقدم است | BLOCKED؛ مهاجرت منتظر تصویب |
| ۱۷. امکانات و محدودیت‌ها | `docs/02-project-overview/FEATURE_INVENTORY.md`، تمام ردیف‌ها و اجرا‌نشده‌ها؛ `PROJECT_STATUS_AND_NEXT_STEPS.md` در همان پوشه؛ `docs/AI_HANDOFF/FULL_PROJECT_DEBUGGING_REPORT.md`، بخش‌های ۶ تا ۱۰ | کامل ترکیبی؛ سند قبلی فصل مستقل همهٔ امکانات ندارد | inventory دارای baseline تاریخی؛ نتیجهٔ آزمون قبلی تضمین اکنون نیست | شواهد Frontend، mock و gate‌های Backend تفکیک‌شده |
| ۱۸. پرسش/تصمیم باز | `docs/API_FA/19-BACKEND-TEAM-QUESTIONS.md`، سه گروه پاسخ‌دهنده؛ `23-OPEN-DECISIONS.md`، D01 تا D18؛ `25-CONTRACT-STATUS-AND-PROVENANCE.md` در همان پوشه | کامل دفتر موجود؛ پاسخ هنوز ارائه نشده | جاری؛ هیچ موردی ضمنی بسته نمی‌شود | باز، نیازمند مالک/نسخه/تصویب |

## مسیرهای واقعی و منشأ خروجی

DDL مرجع `docs/API_FA/sql/PROPOSED_SCHEMA.sql` و کپی توزیعی آن `docs/handover/03-database/sql/PROPOSED_SCHEMA.sql` است. `DATABASE-DESIGN.md` در مسیر فعلی `docs/handover/03-database/DATABASE-DESIGN.md` و معادل مرجع `docs/API_FA/06-DATABASE-DESIGN.md` یافت شد. `FRONTEND_API_REQUIREMENTS.md` و `API_PHASE_READINESS.md` اکنون زیر `docs/12-api-reference/` هستند. فایل مستقلی با نام تاریخی `MASTER_PRODUCT_BUSINESS_SPECIFICATION_FA.md` در فهرست فعلی وجود ندارد؛ پوشش محصول از منابع بالا تأمین می‌شود، نه از سند فرضی. اطلاعات قیمت‌گذاری، درآمد یا پژوهش بازار در این تحویل ساخته نشده است.

`tools/generate-api-handoff.mjs` کاتالوگ/قرارداد/طرح/blueprint/DDL/ERD را از JSON مرجع می‌سازد. `tools/build_backend_handover.py` ماژول‌ها، هر دو نمای جامع، README، manifest و ZIP را تولید می‌کند. اصلاح قرارداد در مرجع انجام می‌شود؛ سپس خروجی‌ها همگام بازتولید می‌شوند. اسناد قدیمی حذف یا به قرارداد مستقلی تبدیل نمی‌شوند.
