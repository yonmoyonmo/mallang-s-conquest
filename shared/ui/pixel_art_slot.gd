class_name PixelArtSlot
extends Control
## Drop-in placeholder for pixel art that keeps the final source dimensions visible.

@export var asset_id: StringName = &"theme/mallang"
@export var variant_id: StringName = &"default"
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export var placeholder_color := Color("29354b"):
	set(value):
		placeholder_color = value
		queue_redraw()

var _caption := ""


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	queue_redraw()


func configure(
	new_asset_id: StringName,
	display_size: Vector2,
	caption: String = "",
	new_variant_id: StringName = &"default",
	new_texture: Texture2D = null,
) -> void:
	asset_id = new_asset_id
	variant_id = new_variant_id
	custom_minimum_size = display_size
	_caption = caption
	texture = new_texture if new_texture != null else _load_expected_texture()
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, placeholder_color)
	_draw_checker(rect)
	draw_rect(rect.grow(-1.0), Color("7081a1"), false, 2.0)

	if texture != null:
		var source_region := ArtCatalog.source_region(asset_id)
		var source_size := texture.get_size()
		if source_region.has_area():
			source_size = source_region.size
		var fitted := _fit_rect(Vector2(source_size), size)
		if source_region.has_area():
			draw_texture_rect_region(texture, fitted, source_region)
		else:
			draw_texture_rect(texture, fitted, false)
		return

	var source_size := ArtCatalog.source_size(asset_id)
	var title := _caption if not _caption.is_empty() else String(asset_id)
	var detail := "%d×%d px" % [source_size.x, source_size.y]
	_draw_centered_text(title, size.y * 0.46, 14, Color("f0f3fa"))
	_draw_centered_text(detail, size.y * 0.62, 12, Color("b8c3d9"))


func _draw_checker(rect: Rect2) -> void:
	var tile := 12.0
	var columns := int(ceil(rect.size.x / tile))
	var rows := int(ceil(rect.size.y / tile))
	for y in range(rows):
		for x in range(columns):
			if (x + y) % 2 == 0:
				continue
			draw_rect(
				Rect2(Vector2(x, y) * tile, Vector2.ONE * tile),
				Color(0.08, 0.1, 0.15, 0.18),
			)


func _draw_centered_text(
	text: String,
	y: float,
	font_size: int,
	color: Color,
) -> void:
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		Vector2((size.x - text_width) * 0.5, y),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color,
	)


func _fit_rect(texture_size: Vector2, available_size: Vector2) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2(Vector2.ZERO, available_size)
	var scale_factor := minf(
		available_size.x / texture_size.x,
		available_size.y / texture_size.y,
	)
	var integer_scale := maxf(1.0, floorf(scale_factor))
	var fitted_size := texture_size * integer_scale
	if fitted_size.x > available_size.x or fitted_size.y > available_size.y:
		fitted_size = texture_size * scale_factor
	return Rect2((available_size - fitted_size) * 0.5, fitted_size)


func _load_expected_texture() -> Texture2D:
	var path := ArtCatalog.expected_path(asset_id, variant_id)
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		return null
	return load(path) as Texture2D
