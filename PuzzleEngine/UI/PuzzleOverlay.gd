class_name PuzzleOverlay
extends Control

signal continue_requested
signal retry_requested
signal hint_action_requested
signal hint_purchase_requested
signal dismiss_requested

const STUDIO_URL: String = "http://gheleghstudio.ir"
const GAME_GUIDE: String = "در هر مرحله با یک سؤال کوتاه و صحنه‌ای پر از اشیای قابل تعامل روبه‌رو می‌شوی؛ برای پیدا کردن پاسخ باید محیط را بررسی کنی، اشیا را لمس، جابه‌جا یا استفاده کنی و حواست به دام‌ها و نکات پنهان باشد. کافی است راه‌حل را در خود صحنه اجرا کنی. وقتی حرکت درست را پیدا کنی، نتیجه همان لحظه در محیط بازی دیده می‌شود."

var mode: String = ""
@onready var hint_action: Button = $SafeMargin/Center/Panel/Padding/Content/HintAction
@onready var hint_purchase: Button = $SafeMargin/Center/Panel/Padding/Content/HintPurchase
@onready var dismiss_button: Button = $SafeMargin/Center/Panel/Padding/Content/Dismiss

@onready var title: Label = $SafeMargin/Center/Panel/Padding/Content/Title
@onready var details: Label = $SafeMargin/Center/Panel/Padding/Content/DetailsScroll/Details
@onready var continue_button: Button = $SafeMargin/Center/Panel/Padding/Content/Continue
@onready var retry_button: Button = $SafeMargin/Center/Panel/Padding/Content/Retry
@onready var studio_brand: VBoxContainer = $SafeMargin/Center/Panel/Padding/Content/Studio
@onready var studio_link: LinkButton = $SafeMargin/Center/Panel/Padding/Content/Studio/Brand/Row/Link

func _ready() -> void:
	hint_action.pressed.connect(func() -> void: hint_action_requested.emit())
	hint_purchase.pressed.connect(func() -> void: hint_purchase_requested.emit())
	dismiss_button.pressed.connect(func() -> void: dismiss_requested.emit())
	continue_button.pressed.connect(func() -> void: continue_requested.emit())
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	studio_link.pressed.connect(func() -> void: OS.shell_open(STUDIO_URL))

func show_result(result: Dictionary, last_level: bool, answer: String = "") -> void:
	_reset_buttons()
	title.text = "معما حل شد!"
	details.text = "امتیاز: %s\nستاره‌ها: %s از ۳" % [PuzzleHUD._persian(str(result["score"])), PuzzleHUD._persian(str(result["stars"]))]
	if not answer.is_empty():
		details.text = "پاسخ: %s\n\n%s" % [answer, details.text]
	continue_button.text = "پایان بازی" if last_level else "مرحلهٔ بعد"
	continue_button.disabled = false
	continue_button.show()
	retry_button.hide()
	show()

func show_failure() -> void:
	_reset_buttons()
	title.text = "زمان تمام شد"
	details.text = "دوباره تلاش کنید و پاسخ معما را پیدا کنید."
	continue_button.hide()
	retry_button.show()
	show()

func show_error() -> void:
	_reset_buttons()
	title.text = "اجرای مرحله انجام نشد"
	details.text = "لطفاً دوباره تلاش کنید."
	continue_button.hide()
	retry_button.show()
	show()

func show_game_finished(score: int, stars: int) -> void:
	_reset_buttons()
	title.text = "همهٔ معماها حل شدند!"
	details.text = "مجموع امتیاز: %s\nمجموع ستاره‌ها: %s" % [PuzzleHUD._persian(str(score)), PuzzleHUD._persian(str(stars))]
	continue_button.hide()
	retry_button.hide()
	show()

func _reset_buttons() -> void:
	mode = ""
	($SafeMargin/Center/Panel/Padding/Content/DetailsScroll as ScrollContainer).scroll_vertical = 0
	hint_action.hide()
	hint_purchase.hide()
	dismiss_button.hide()
	continue_button.hide()
	retry_button.hide()
	studio_brand.hide()

func _hint_panel(kind: String, heading: String, message: String, action: String = "") -> void:
	_reset_buttons()
	mode = kind
	title.text = heading
	details.text = message
	hint_action.text = action
	hint_action.visible = not action.is_empty()
	dismiss_button.text = "بستن"
	dismiss_button.show()
	show()

func show_hint_offer(score: int = 0) -> void:
	_hint_panel("offer", "راهنمای معما", "با پرداخت ۱۰۰ امتیاز یا تماشای کامل تبلیغ، راهنمای این مرحله را باز کنید.\nامتیاز موجود: %s" % PuzzleHUD._persian(str(score)), "تماشای تبلیغ")
	hint_purchase.text = "پرداخت ۱۰۰ امتیاز"
	hint_purchase.show()

func show_insufficient_points(score: int) -> void:
	show_hint_offer(score)
	details.text = "امتیاز کافی ندارید؛ برای دریافت راهنما به ۱۰۰ امتیاز نیاز دارید.\nامتیاز موجود: %s\nمی‌توانید با تماشای کامل تبلیغ راهنما را دریافت کنید." % PuzzleHUD._persian(str(score))

func show_hint(text: String) -> void:
	_hint_panel("hint", "راهنمای معما", text)

func show_ad_unavailable() -> void:
	_hint_panel("unavailable", "راهنما باز نشد", "تبلیغ تکمیل نشد یا در دسترس نیست. دوباره تلاش کنید.", "تلاش مجدد برای تبلیغ")
	hint_purchase.text = "پرداخت ۱۰۰ امتیاز"
	hint_purchase.show()

func show_simulated_ad() -> void:
	_hint_panel("ad", "تبلیغ آزمایشی", "این نمایش برای آزمایش دریافت پاداش است.", "تکمیل و دریافت راهنما")
	dismiss_button.text = "انصراف از تبلیغ"

func show_save_error() -> void:
	_reset_buttons()
	mode = "save_error"
	title.text = "ذخیره انجام نشد"
	details.text = "برای ذخیره یا بازیابی اطلاعات دوباره تلاش کنید."
	retry_button.show()
	show()

func show_confirmation(heading: String, message: String, confirm_text: String, kind: String = "confirmation") -> void:
	_reset_buttons()
	mode = kind
	title.text = heading
	details.text = message
	continue_button.text = confirm_text
	continue_button.disabled = false
	continue_button.show()
	dismiss_button.text = "انصراف"
	dismiss_button.show()
	show()

func show_game_guide() -> void:
	_hint_panel("guide", "راهنمای بازی", GAME_GUIDE)
	studio_brand.show()
