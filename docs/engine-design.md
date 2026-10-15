# معماری Mini Puzzle Engine

این سند مرجع ساختار و ارتباط اجزاست. [قواعد پروژه](project-rules.md)، [قرارداد اجرایی](engine-contract.md) و [قواعد موبایل](mobile-ui-rules.md) به‌ترتیب روش کار، رفتار موتور و چیدمان را تعیین می‌کنند. وضعیت پیاده‌سازی و قابلیت‌های باقی‌مانده فقط در [برنامهٔ اجرا](engine-implementation-plan.md) ثبت می‌شود؛ نام جزء در این سند به‌معنای تکمیل آن نیست.

## اصل معماری

موتور ثابت و داده‌محور باشد: مرحلهٔ معمولی با تعریف اشیا، چند قانون و شرط برد ساخته شود، بدون اسکریپت تازه برای هر شیء یا مرحله. هدف تقریبی۹۰٪ محتوای داده‌محور و۱۰٪ منطق اختصاصی است و باید پس از ساخت محتوای واقعی سنجیده شود. Editor داخلی و دریافت/ویرایش آنلاین مرحله در دامنهٔ فعلی نیستند؛ ابزار Debug و اعتبارسنجی گروهی مستقل از Editor هستند.

«تعامل» ورودی بازیکن، «قانون» زمان و شرط واکنش و «اکشن» تغییر حاصل در صحنه یا وضعیت است. نوع‌ها، پیش‌فرض‌ها و ترتیب اجرای آن‌ها فقط در قرارداد موتور تعریف می‌شوند.

## اجزا و مسئولیت‌ها

| جزء | مسئولیت |
| --- | --- |
| `Application.tscn / Application.gd` | خانه، ناوبری، منوی مشترک، ابزار توسعه و ایجاد/حذف Controller |
| `PuzzleScene.tscn` | قالب مشترک World، اشیا، HUD و Overlay |
| `PuzzleController` | هماهنگی بارگذاری، چرخهٔ اجرا و اجزای منطق |
| `PuzzleLoader / PuzzleValidator` | خواندن JSON/manifest و اعتبارسنجی داده و منابع |
| `PuzzleState` | وضعیت جاری، متغیرها و run_id؛ مستقل از تعریف اولیه |
| `PuzzleObject` و Sceneهای `Objects/` | نمایش، ناحیهٔ تعامل، شناسه و وضعیت شیء؛ پایهٔ گونه‌های قابل بازاستفاده |
| `InteractionManager` | دریافت لمس/ماوس و تبدیل آن به رویداد تعامل |
| `RuleEvaluator` | صف رویداد، تطبیق قوانین، شروط و شرط برد |
| `ActionRunner` | اجرای اکشن‌های عمومی و مالکیت عملیات قابل لغو |
| `LevelClock / ResultCalculator` | زمان دقیق اجرا و محاسبهٔ نتیجه |
| `ProgressStore` | ذخیره/بازیابی مرحله، نتایج و هینت‌ها |
| `RewardedAdAdapter` | مرز مستقل شبکهٔ تبلیغاتی و منطق بازی |
| `addons/adivery` و پل Java | اتصال v2 اندروید به SDK ادیوری؛ Adapter مشترک با عمر Application به Controller جاری تحویل می‌شود؛ شناسه‌های پنل در `AdiveryConfig.gd` هستند |
| `PuzzleCustomHandler / Context` | منطق استثنایی با API محدود و وابسته به اجرا |
| `DebugOverlay` | مشاهدهٔ وضعیت، رویداد و قانون در توسعه؛ بدون Editor |
| `PuzzleData/manifest.json` و JSONها | ترتیب محتوا و تعریف مراحل؛ مستقل از کد موتور |

اجزای منطق تا حد ممکن بدون صحنهٔ نمایشی قابل بررسی باشند. اشیای معما Node2D و نمایش آن‌ها Sprite2D یا Label است؛ UI از اجزای مشترک Control/CanvasLayer استفاده می‌کند و جزئیات چیدمان در قواعد موبایل است.

## جریان داده

```text
manifest / JSON → Loader → Validator → Controller
                                      ├─ State و Objects
                                      ├─ HUD / Overlay
                                      └─ Clock
ورودی → InteractionManager → RuleEvaluator → ActionRunner → State / Objects
                                      └─ نتیجه → ProgressStore → Overlay
هینت → RewardedAdAdapter → تأیید پاداش → ProgressStore → Overlay
```

تعریف اولیه با وضعیت هر اجرا جداست؛ تعویض/Retry منابع اجرای قبلی را پاک می‌کند. handler اختصاصی جای هسته را نمی‌گیرد و فقط از Context استفاده می‌کند. قرارداد داده، لغو، مرز زمان، ذخیره و callbackها در [قرارداد موتور](engine-contract.md) است.

## اجزای مشترک برنامه

- `UI/HomeScreen` فقط خانه و نمایش اطلاعات پیشرفت را مدیریت می‌کند؛ ایجاد مرحله و کنترل ناوبری با Application است.
- یک نمونهٔ `UI/MainMenu.tscn` در `MainMenuLayer` می‌ماند. APIهای `show_home_menu / show_game_menu / close_menu / hide_menu` و سیگنال `menu_requested` ارتباط منو با Controller/Application را برقرار می‌کنند.
- `UI/DevelopmentTools.tscn` در `DevelopmentLayer` مستقل و اختیاری است. Application سیگنال‌های انتخاب مرحله و ریست را دریافت می‌کند؛ HomeScreen به ابزار وابسته نیست. حذف Layer و ارجاع Scene آن، رابط توسعه را حذف می‌کند.
- `UI/PuzzleTheme.tres` و `UI/PuzzleOverlay.tscn` اجزای مشترک پیام‌ها هستند؛ `show_confirmation` برای تأییدها و نمونهٔ `MessageLayer` برای پیام‌های برنامه استفاده می‌شود. مشخصات ظاهری و رفتاری فقط در بخش مربوط قرارداد موتور است.

برای ترتیب افزودن قابلیت‌ها و معیار پایان هر گام، [برنامهٔ اجرا](engine-implementation-plan.md) را دنبال کن؛ نمونهٔ JSON و جزئیات schema از قرارداد موتور و سناریوی مرحله از [جدول محتوا](100_interactive_persian_puzzles.md) خوانده شود.
