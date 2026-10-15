@tool
extends EditorPlugin

var _export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	_export_plugin = AdiveryAndroidExport.new()
	add_export_plugin(_export_plugin)

func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null

class AdiveryAndroidExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "RamzoRazAdivery"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/adivery/bin/ramzoraz-adivery.aar"])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.adivery:sdk:4.9.0", "com.google.android.gms:play-services-ads-identifier:18.0.1"])
