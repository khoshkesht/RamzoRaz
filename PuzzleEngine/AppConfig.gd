class_name PuzzleAppConfig
extends RefCounted

const SCHEMA_VERSION: int = 1
const DESIGN_SIZE: Vector2 = Vector2(1920, 1080)
const MANIFEST_PATH: String = "res://PuzzleEngine/PuzzleData/manifest.json"
const FONT_PATH: String = "res://assets/fonts/Vazirmatn-Regular.ttf"
const UI_PADDING: int = 40
const AUTHORED_LEVEL_COUNT: int = 101
const SCENE_PATHS: Dictionary = {
	"ImageObject": "res://PuzzleEngine/Objects/ImageObject.tscn",
	"TextObject": "res://PuzzleEngine/Objects/TextObject.tscn",
	"ClickableObject": "res://PuzzleEngine/Objects/ClickableObject.tscn",
	"DraggableObject": "res://PuzzleEngine/Objects/DraggableObject.tscn",
	"DropZone": "res://PuzzleEngine/Objects/DropZone.tscn",
	"PuzzleButton": "res://PuzzleEngine/Objects/PuzzleButton.tscn",
}

