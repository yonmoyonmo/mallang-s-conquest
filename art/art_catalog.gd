class_name ArtCatalog
extends RefCounted
## Canonical pixel-art source sizes and future asset paths.
##
## UI code should refer to these IDs instead of inventing per-screen dimensions.

const LOGICAL_VIEWPORT := Vector2i(540, 960)

const SPECS := {
	"background/start": {
		"size": Vector2i(270, 480),
		"path": "res://art/backgrounds/start.png",
		"note": "화면에서 정확히 2배 확대",
	},
	"background/menu": {
		"size": Vector2i(270, 480),
		"path": "res://art/backgrounds/menu.png",
		"note": "화면에서 정확히 2배 확대",
	},
	"character/rival_full": {
		"size": Vector2i(180, 240),
		"path": "res://art/characters/<rival_id>.png",
		"note": "3:4 투명 배경 마스터",
	},
	"character/rival_card": {
		"size": Vector2i(72, 72),
		"path": "res://art/characters/<rival_id>.png",
		"region": Rect2i(54, 12, 72, 72),
		"note": "별도 제작하지 않음",
	},
	"character/rival_bust": {
		"size": Vector2i(96, 96),
		"path": "res://art/characters/<rival_id>.png",
		"region": Rect2i(42, 8, 96, 96),
		"note": "별도 제작하지 않음",
	},
	"theme/mallang": {
		"size": Vector2i(16, 16),
		"path": "res://art/themes/mallang/<theme_id>.png",
		"note": "투명 배경 단일 셀",
	},
	"theme/territory": {
		"size": Vector2i(16, 16),
		"path": "res://art/themes/territory/<theme_id>.png",
		"note": "무채색 반복 타일 또는 마스크",
	},
	"theme/emblem": {
		"size": Vector2i(24, 24),
		"path": "res://art/themes/emblems/<theme_id>.png",
		"note": "보상 카드와 테마 표식",
	},
	"ui/icon_small": {
		"size": Vector2i(16, 16),
		"path": "res://art/ui/icons/<icon_id>_16.png",
		"note": "보조 기능 아이콘",
	},
	"ui/icon": {
		"size": Vector2i(24, 24),
		"path": "res://art/ui/icons/<icon_id>_24.png",
		"note": "주요 버튼 아이콘",
	},
	"app/icon_master": {
		"size": Vector2i(256, 256),
		"path": "res://art/ui/app_icon_256.png",
		"note": "스토어 제출본은 최근접 4배로 1024×1024 출력",
	},
}


static func source_size(asset_id: StringName) -> Vector2i:
	var spec: Dictionary = SPECS.get(String(asset_id), {})
	return spec.get("size", Vector2i(16, 16))


static func expected_path(asset_id: StringName, variant_id: StringName = &"") -> String:
	var spec: Dictionary = SPECS.get(String(asset_id), {})
	var path: String = spec.get("path", "")
	var variant := String(variant_id)
	path = path.replace("<rival_id>", variant)
	path = path.replace("<theme_id>", variant)
	path = path.replace("<icon_id>", variant)
	return path


static func source_region(asset_id: StringName) -> Rect2i:
	var spec: Dictionary = SPECS.get(String(asset_id), {})
	return spec.get("region", Rect2i())


static func note(asset_id: StringName) -> String:
	var spec: Dictionary = SPECS.get(String(asset_id), {})
	return spec.get("note", "")
