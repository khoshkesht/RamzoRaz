class_name PuzzleApplication
extends Node

const PUZZLE_SCENE := preload("res://PuzzleEngine/PuzzleScene.tscn")
var progress_path: String = "user://progress.json"
var settings_path: String = "user://settings.json"
var settings := PuzzleSettingsStore.new()
var _music_pauses: Dictionary = {}
var controller: PuzzleController
var manifest: Dictionary = {}
var loader := PuzzleLoader.new()
var progress := PuzzleProgressStore.new()
var test_enabled: bool = OS.is_debug_build()
@onready var home: PuzzleHomeScreen = $HomeLayer/Home
@onready var main_menu: PuzzleMainMenu = $MainMenuLayer/MainMenu
@onready var message_dialog: PuzzleOverlay = $MessageLayer/MessageDialog
@onready var settings_dialog: PuzzleSettingsDialog = $SettingsLayer/SettingsDialog
@onready var music_player: AudioStreamPlayer = $Music
@onready var development_tools: PuzzleDevelopmentTools = get_node_or_null("DevelopmentLayer/DevelopmentTools")
@onready var back_button: Button = $NavigationLayer/Root/SafeMargin/Layout/Footer/Back
@onready var build_label: Label = $NavigationLayer/Root/SafeMargin/Layout/BuildRow/Build

func _ready() -> void:
	home.play_requested.connect(play)
	home.reload_requested.connect(show_home)
	main_menu.home_requested.connect(_menu_home)
	main_menu.exit_requested.connect(_menu_exit)
	main_menu.settings_requested.connect(open_settings)
	main_menu.guide_requested.connect(open_guide)
	settings_dialog.save_requested.connect(_save_settings)
	settings_dialog.close_requested.connect(_close_settings)
	message_dialog.continue_requested.connect(_confirm_exit)
	message_dialog.dismiss_requested.connect(message_dialog.hide)
	if is_instance_valid(development_tools):
		development_tools.test_requested.connect(play_test)
		development_tools.reset_requested.connect(reset_progress)
	back_button.pressed.connect(show_home)
	var version: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://PuzzleEngine/BuildVersion.json"))
	build_label.text = "بیلد %s" % PuzzleHUD._persian(str(int(version["build_number"])))
	settings.path = settings_path
	settings.open()
	if music_player.stream is AudioStreamMP3:
		music_player.stream = music_player.stream.duplicate()
		(music_player.stream as AudioStreamMP3).loop = true
	show_home()
	_apply_settings()

func show_home() -> void:
	if settings_dialog.visible:
		return
	if is_instance_valid(controller):
		# Pending writes and an actual ad must finish before leaving their owner.
		if not controller._save_operation.is_empty() or not controller.ad_adapter.active.is_empty():
			return
		remove_child(controller)
		controller.queue_free()
		controller = null
	home.show()
	message_dialog.hide()
	main_menu.set_navigation_enabled(true)
	main_menu.show_home_menu()
	if is_instance_valid(development_tools):
		development_tools.configure(false)
	back_button.hide()
	progress.path = progress_path
	var loaded := loader.load_manifest()
	if not loaded["ok"]:
		home.display_error()
		return
	manifest = loaded["data"]
	if not progress.open(manifest):
		home.display_error()
		return
	home.display_progress(progress.data, manifest)
	_apply_settings()
	if is_instance_valid(development_tools):
		development_tools.configure(test_enabled and not manifest["levels"].is_empty(), manifest["levels"].size())

func play() -> void:
	if is_instance_valid(controller) or _development_dialog_open() or home.play_button.disabled or progress.data.is_empty() or progress.data.get("current_level_id") == null:
		return
	_start(-1)

func play_test(index: int) -> void:
	if not test_enabled or not OS.is_debug_build() or settings_dialog.visible or _reset_pending() or is_instance_valid(controller) or index < 0 or index >= manifest.get("levels", []).size():
		return
	_start(index)

func reset_progress() -> void:
	if not test_enabled or not OS.is_debug_build() or is_instance_valid(controller) or not home.visible or not _reset_pending():
		return
	if not progress.reset_progress():
		development_tools.reset_error.text = "ریست پیشرفت کامل نشد. دوباره تلاش کنید."
		return
	show_home()

func _development_dialog_open() -> bool:
	return message_dialog.visible or settings_dialog.visible or (is_instance_valid(development_tools) and development_tools.is_visible_in_tree() and development_tools.dialog.visible)

func _reset_pending() -> bool:
	return is_instance_valid(development_tools) and development_tools.is_visible_in_tree() and development_tools.dialog.visible and development_tools.reset_panel.visible

func _start(test_index: int) -> void:
	controller = PUZZLE_SCENE.instantiate() as PuzzleController
	controller.loader.manifest_path = loader.manifest_path
	controller.progress_store.path = progress_path
	controller.return_to_home_after_advance = true
	if test_index >= 0:
		controller.progress_store.persistent = false
		controller.allow_development_loading = true
		controller.test_start_index = test_index
	controller.home_requested.connect(func() -> void: show_home.call_deferred())
	controller.menu_requested.connect(open_main_menu)
	home.hide()
	main_menu.hide_menu()
	if is_instance_valid(development_tools):
		development_tools.close()
		development_tools.hide()
	back_button.hide()
	add_child(controller)

func _process(_delta: float) -> void:
	_sync_music()
	if is_instance_valid(controller):
		back_button.disabled = _navigation_blocked() or settings_dialog.visible or message_dialog.visible
		controller.hud.menu_button.disabled = back_button.disabled
		main_menu.set_navigation_enabled(not back_button.disabled)
	else:
		main_menu.set_navigation_enabled(not settings_dialog.visible and not message_dialog.visible)

func open_main_menu() -> void:
	if not is_instance_valid(controller) or _navigation_blocked() or message_dialog.visible or settings_dialog.visible:
		return
	controller.interaction_manager.cancel_active_pointer()
	main_menu.show_game_menu()

func _navigation_blocked() -> bool:
	return is_instance_valid(controller) and (not controller._save_operation.is_empty() or not controller.ad_adapter.active.is_empty())

func _menu_home() -> void:
	if not home.visible and not _navigation_blocked() and not message_dialog.visible and not settings_dialog.visible:
		show_home.call_deferred()

func _menu_exit() -> void:
	if not _navigation_blocked() and not message_dialog.visible and not settings_dialog.visible:
		if is_instance_valid(controller):
			controller.interaction_manager.cancel_active_pointer()
		message_dialog.show_confirmation("خروج از بازی", "می‌خواهید از بازی خارج شوید؟", "خروج", "confirm_exit")

func _confirm_exit() -> void:
	if message_dialog.visible and message_dialog.mode == "confirm_exit" and not _navigation_blocked():
		get_tree().quit()

func _total_score() -> int:
	var saved := progress.data
	if is_instance_valid(controller) and controller.progress_store.persistent:
		saved = controller.progress_store.data
	return PuzzleProgressStore.available_score(saved)

func open_settings() -> void:
	if _navigation_blocked() or _development_dialog_open():
		return
	if is_instance_valid(controller):
		controller.interaction_manager.cancel_active_pointer()
	main_menu.close_menu()
	settings_dialog.open(settings.data, _total_score(), settings.error)
	main_menu.set_navigation_enabled(false)

func open_guide() -> void:
	if _navigation_blocked() or _development_dialog_open():
		return
	if is_instance_valid(controller):
		controller.interaction_manager.cancel_active_pointer()
	main_menu.close_menu()
	message_dialog.show_game_guide()
	main_menu.set_navigation_enabled(false)

func _save_settings(music_enabled: bool, background: int) -> void:
	if not settings_dialog.visible:
		return
	if not settings.save(music_enabled, background, _total_score()):
		settings_dialog.show_message(settings.error)
		return
	_apply_settings()
	_close_settings()

func _close_settings() -> void:
	settings_dialog.hide()
	main_menu.set_navigation_enabled(not _navigation_blocked())

func _apply_settings() -> void:
	var selected := settings.effective_background(_total_score())
	home.background_artwork.texture = load(PuzzleSettingsStore.BACKGROUNDS[selected - 1]) as Texture2D
	_sync_music()

func _sync_music() -> void:
	if not bool(settings.data["music_enabled"]):
		music_player.stop()
		return
	if not music_player.playing:
		music_player.play()
	var paused := not _music_pauses.is_empty()
	if is_instance_valid(controller):
		paused = paused or not controller.clock.pause_reasons.is_empty()
	music_player.stream_paused = paused

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_music_pauses["background"] = true
		NOTIFICATION_APPLICATION_RESUMED:
			_music_pauses.erase("background")
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_music_pauses["focus"] = true
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_music_pauses.erase("focus")
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_music_pauses["window_focus"] = true
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_music_pauses.erase("window_focus")
	if is_node_ready():
		_sync_music()
