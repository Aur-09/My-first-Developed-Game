extends Control

@export var portrait_name := "LURNA"
@export_range(0, 3) var character_variant := 0
@export var crew_color := Color(0.18, 0.78, 0.43)
@export var clothing_color := Color(0.08, 0.24, 0.17)
@export var skin_color := Color(0.66, 0.44, 0.34)
@export var hair_color := Color(0.08, 0.055, 0.05)


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color(0.028, 0.046, 0.052), true)
	draw_rect(bounds, crew_color.darkened(0.12), false, 2.0)
	draw_line(Vector2(12, size.y - 32), Vector2(size.x - 12, size.y - 32), crew_color, 2.0)
	var center_x := size.x * 0.5
	var head_center := Vector2(center_x, size.y * 0.39)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_x - 63, size.y - 34),
			Vector2(center_x - 48, size.y * 0.69),
			Vector2(center_x - 31, size.y * 0.62),
			Vector2(center_x + 31, size.y * 0.62),
			Vector2(center_x + 49, size.y * 0.70),
			Vector2(center_x + 64, size.y - 34)
		]),
		clothing_color
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_x - 25, size.y * 0.66),
			Vector2(center_x, size.y * 0.75),
			Vector2(center_x + 24, size.y * 0.66),
			Vector2(center_x + 16, size.y - 35),
			Vector2(center_x - 16, size.y - 35)
		]),
		Color(0.12, 0.15, 0.15)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_x - 29, size.y * 0.52),
			Vector2(center_x + 29, size.y * 0.52),
			Vector2(center_x + 24, size.y * 0.65),
			Vector2(center_x, size.y * 0.71),
			Vector2(center_x - 24, size.y * 0.65)
		]),
		skin_color.darkened(0.08)
	)
	draw_circle(head_center + Vector2(0, 1), size.x * 0.215, skin_color)
	_draw_hair(center_x, head_center)
	draw_line(head_center + Vector2(-20, 1), head_center + Vector2(-8, 1), hair_color.darkened(0.2), 2.3)
	draw_line(head_center + Vector2(8, 1), head_center + Vector2(20, 1), hair_color.darkened(0.2), 2.3)
	draw_circle(head_center + Vector2(-14, 4), 1.8, Color(0.91, 0.83, 0.71))
	draw_circle(head_center + Vector2(14, 4), 1.8, Color(0.91, 0.83, 0.71))
	draw_line(head_center + Vector2(-7, 19), head_center + Vector2(7, 19), Color(0.32, 0.15, 0.13), 1.4)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_x + 41, size.y * 0.69),
			Vector2(center_x + 54, size.y * 0.83),
			Vector2(center_x + 42, size.y - 34),
			Vector2(center_x + 27, size.y - 34)
		]),
		crew_color
	)
	var font := get_theme_default_font()
	if font:
		draw_string(
			font,
			Vector2(9, size.y - 11),
			portrait_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x - 18,
			14,
			Color(0.9, 0.92, 0.86)
		)


func _draw_hair(center_x: float, head_center: Vector2) -> void:
	match character_variant:
		0:
			draw_colored_polygon(
				PackedVector2Array([
					head_center + Vector2(-32, 2),
					head_center + Vector2(-29, -27),
					head_center + Vector2(-10, -37),
					head_center + Vector2(20, -31),
					head_center + Vector2(32, -10),
					head_center + Vector2(11, -17),
					head_center + Vector2(-8, -6),
					head_center + Vector2(-18, 3)
				]),
				hair_color
			)
			for curl in range(5):
				draw_circle(head_center + Vector2(-23 + curl * 10, -25 - (curl % 2) * 5), 6, hair_color)
		1:
			draw_colored_polygon(
				PackedVector2Array([
					head_center + Vector2(-31, 4),
					head_center + Vector2(-28, -28),
					head_center + Vector2(-9, -37),
					head_center + Vector2(21, -31),
					head_center + Vector2(31, -3),
					head_center + Vector2(23, 16),
					head_center + Vector2(18, -15),
					head_center + Vector2(-10, -6)
				]),
				hair_color
			)
			draw_circle(head_center + Vector2(17, -35), 12, hair_color)
			draw_line(head_center + Vector2(23, -24), head_center + Vector2(35, 19), hair_color, 4.0)
		2:
			draw_colored_polygon(
				PackedVector2Array([
					head_center + Vector2(-30, 0),
					head_center + Vector2(-28, -28),
					head_center + Vector2(-9, -36),
					head_center + Vector2(20, -31),
					head_center + Vector2(30, -3),
					head_center + Vector2(8, -15),
					head_center + Vector2(-5, -7),
					head_center + Vector2(-20, -12)
				]),
				hair_color
			)
			for curl in range(5):
				draw_circle(head_center + Vector2(-20 + curl * 10, -29 + (curl % 2) * 4), 6.5, hair_color)
		_:
			draw_colored_polygon(
				PackedVector2Array([
					head_center + Vector2(-31, 4),
					head_center + Vector2(-28, -28),
					head_center + Vector2(-9, -37),
					head_center + Vector2(20, -31),
					head_center + Vector2(31, -2),
					head_center + Vector2(28, 48),
					head_center + Vector2(20, 22),
					head_center + Vector2(17, -13),
					head_center + Vector2(-12, -5),
					head_center + Vector2(-24, 33)
				]),
				hair_color
			)
