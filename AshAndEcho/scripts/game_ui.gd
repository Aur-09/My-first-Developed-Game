class_name GameUI
extends CanvasLayer

signal play_requested
signal instructions_requested
signal instructions_back_requested
signal tutorial_back_requested
signal tutorial_exit_requested
signal tutorial_viewed
signal tutorial_start_requested
signal intro_back_requested
signal intro_start_requested
signal round_continue_requested
signal retry_requested
signal home_requested
signal pause_requested
signal resume_requested

const PORTRAIT_SCRIPT := preload("res://scripts/character_portrait.gd")
const PORTRAIT_LURNA := "res://assets/portraits/lurna.png"
const PORTRAIT_NOFIA := "res://assets/portraits/nofia.png"
const PORTRAIT_IONA := "res://assets/portraits/iona.png"
const PORTRAIT_KEST := "res://assets/portraits/kest.png"
const COVER_IMAGE := "res://assets/cover/aur09_cover.png"
const BLUE := Color(0.22, 0.65, 0.95)
const RED := Color(0.96, 0.31, 0.24)
const PALE := Color(0.82, 0.88, 0.88)
const MUTED := Color(0.53, 0.63, 0.66)

var root_control: Control
var menu_root: PanelContainer
var menu_title: Label
var menu_body: Label
var menu_buttons: VBoxContainer
var portrait_gallery: HBoxContainer
var lurna_portrait: Control
var nofia_portrait: Control
var concept_image: TextureRect
var concept_caption: Label
var hud_root: Control
var status_label: Label
var story_prompt: Label
var energy_value: Label
var energy_fill: ColorRect
var combat_back_button: Button
var story_back_button: Button
var blue_fills: Array[ColorRect] = []
var red_fills: Array[ColorRect] = []
var tutorial_step := 0
var default_focus: Button
var menu_active := false

const TUTORIAL_STEPS := [
	{
		"title": "01  /  FIND YOUR FOOTING",
		"body": "Move through the arena with WASD or the arrow keys. The fight takes place on a broad 3D platform: watch your distance and make room to move."
	},
	{
		"title": "02  /  MAKE CONTACT",
		"body": "Press J or Space for a close-range gauntlet strike. Lurna faces the direction she last moved. Landing hits builds pulse energy."
	},
	{
		"title": "03  /  BREAK THE LINE",
		"body": "Press Shift or K to dash and briefly evade. Press E or L to spend 45 energy on a blue pulse. Pulse impacts warn nearby floor panels."
	},
	{
		"title": "04  /  WATCH THE FLOOR",
		"body": "Nofia's crew telegraphs heavy attacks with red-lit floor tiles. Leave the warning before it collapses. Your AI teammate Iona fights alongside you."
	}
]


func _ready() -> void:
	layer = 10
	_build_ui()
	show_home()


func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "GameInterface"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	_build_menu_panel()
	_build_hud()
	add_combat_back_button()


func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.name = "CombatHUD"
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.visible = false
	root_control.add_child(hud_root)

	_add_panel(hud_root, Vector2(20, 18), Vector2(435, 104))
	_add_panel(hud_root, Vector2(825, 18), Vector2(435, 104))
	_add_label(hud_root, "BLUE CREW  /  LURNA + IONA", Vector2(36, 22), Vector2(390, 22), 13, BLUE)
	_add_label(hud_root, "RED CREW  /  NOFIA + KEST", Vector2(841, 22), Vector2(390, 22), 13, RED)

	for row in range(2):
		var y := 52.0 + float(row) * 32.0
		var left_name := _add_label(hud_root, "", Vector2(38, y), Vector2(84, 20), 11, PALE)
		var right_name := _add_label(hud_root, "", Vector2(843, y), Vector2(84, 20), 11, PALE)
		var left_bar_pos := Vector2(128, y + 5)
		var right_bar_pos := Vector2(933, y + 5)
		_add_bar_bg(hud_root, left_bar_pos, Vector2(310, 12))
		_add_bar_bg(hud_root, right_bar_pos, Vector2(310, 12))
		blue_fills.append(_add_bar_fill(hud_root, left_bar_pos + Vector2(2, 2), Vector2(306, 8), BLUE))
		red_fills.append(_add_bar_fill(hud_root, right_bar_pos + Vector2(2, 2), Vector2(306, 8), RED))
		left_name.name = "BlueName%d" % row
		right_name.name = "RedName%d" % row

	var center_plate := _add_panel(hud_root, Vector2(500, 18), Vector2(280, 62))
	_add_label(hud_root, "LAST PLATFORM", Vector2(500, 22), Vector2(280, 22), 14, PALE, HORIZONTAL_ALIGNMENT_CENTER)
	status_label = _add_label(hud_root, "ROUND 1", Vector2(500, 44), Vector2(280, 24), 12, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_add_panel(hud_root, Vector2(500, 92), Vector2(280, 42))
	_add_label(hud_root, "PULSE", Vector2(511, 99), Vector2(52, 24), 11, BLUE)
	_add_bar_bg(hud_root, Vector2(565, 106), Vector2(148, 12))
	energy_fill = _add_bar_fill(hud_root, Vector2(567, 108), Vector2(144, 8), BLUE)
	energy_value = _add_label(hud_root, "60 / 100", Vector2(718, 99), Vector2(70, 24), 11, PALE, HORIZONTAL_ALIGNMENT_RIGHT)
	_add_label(
		hud_root,
		"WASD / ARROWS  MOVE      J  STRIKE      SHIFT  DASH      E  PULSE",
		Vector2(260, 674),
		Vector2(760, 25),
		12,
		MUTED,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	story_prompt = _add_label(
		hud_root,
		"",
		Vector2(220, 632),
		Vector2(840, 30),
		13,
		Color(0.91, 0.79, 0.58),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	story_back_button = _make_button("BACK TO TITLE", home_requested.emit)
	story_back_button.name = "StoryBackButton"
	menu_buttons.remove_child(story_back_button)
	story_back_button.custom_minimum_size = Vector2(170, 38)
	story_back_button.position = Vector2(22, 660)
	story_back_button.focus_mode = Control.FOCUS_NONE
	hud_root.add_child(story_back_button)
	story_back_button.visible = false


func _build_menu_panel() -> void:
	var shade := ColorRect.new()
	shade.name = "MenuScrim"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.008, 0.015, 0.023, 0.70)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(shade)

	menu_root = PanelContainer.new()
	menu_root.name = "MenuPanel"
	menu_root.anchor_left = 0.5
	menu_root.anchor_top = 0.5
	menu_root.anchor_right = 0.5
	menu_root.anchor_bottom = 0.5
	menu_root.offset_left = -540
	menu_root.offset_top = -340
	menu_root.offset_right = 540
	menu_root.offset_bottom = 340
	menu_root.add_theme_stylebox_override("panel", _panel_style(Color(0.014, 0.024, 0.035, 0.98), Color(0.29, 0.40, 0.42, 0.86)))
	root_control.add_child(menu_root)
	menu_root.set_meta("scrim", shade)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 28)
	menu_root.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 11)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(layout)
	menu_title = _add_label(layout, "", Vector2.ZERO, Vector2(980, 48), 30, PALE, HORIZONTAL_ALIGNMENT_CENTER)
	_build_portrait_gallery(layout)
	menu_body = _add_label(layout, "", Vector2.ZERO, Vector2(980, 92), 16, PALE, HORIZONTAL_ALIGNMENT_CENTER)
	menu_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_buttons = VBoxContainer.new()
	menu_buttons.add_theme_constant_override("separation", 9)
	menu_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(menu_buttons)
	menu_body.custom_minimum_size.y = 72


func _build_portrait_gallery(layout: VBoxContainer) -> void:
	portrait_gallery = HBoxContainer.new()
	portrait_gallery.name = "CharacterIntroduction"
	portrait_gallery.custom_minimum_size = Vector2(980, 310)
	portrait_gallery.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_gallery.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_gallery.add_theme_constant_override("separation", 14)
	layout.add_child(portrait_gallery)

	# BLUE CREW (left): Lurna, then Iona
	lurna_portrait = _make_portrait(
		"PortraitLurna", "LURNA", 0,
		Color(0.22, 0.60, 0.95), Color(0.10, 0.20, 0.35),
		Color(0.66, 0.44, 0.34), Color(0.08, 0.055, 0.05),
		PORTRAIT_LURNA
	)
	lurna_portrait.custom_minimum_size = Vector2(130, 290)
	portrait_gallery.add_child(lurna_portrait)

	var iona_portrait := _make_portrait(
		"PortraitIona", "IONA", 2,
		Color(0.22, 0.60, 0.95), Color(0.10, 0.20, 0.35),
		Color(0.39, 0.26, 0.21), Color(0.055, 0.049, 0.047),
		PORTRAIT_IONA
	)
	iona_portrait.custom_minimum_size = Vector2(110, 290)
	portrait_gallery.add_child(iona_portrait)

	# CENTER: cover image
	var reference_column := VBoxContainer.new()
	reference_column.custom_minimum_size = Vector2(460, 290)
	reference_column.alignment = BoxContainer.ALIGNMENT_CENTER
	reference_column.add_theme_constant_override("separation", 6)
	portrait_gallery.add_child(reference_column)

	concept_image = TextureRect.new()
	concept_image.name = "ProvidedConceptReference"
	if ResourceLoader.exists(COVER_IMAGE):
		concept_image.texture = load(COVER_IMAGE)
	concept_image.custom_minimum_size = Vector2(460, 266)
	concept_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	concept_image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	concept_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	concept_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reference_column.add_child(concept_image)

	concept_caption = _add_label(
		reference_column,
		"USER MOODBOARD  /  NOT CANONICAL CHARACTER NAMES",
		Vector2.ZERO, Vector2(460, 18), 10, MUTED,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	# RED CREW (right): Nofia, then Kest
	nofia_portrait = _make_portrait(
		"PortraitNofia", "NOFIA", 2,
		Color(0.90, 0.20, 0.15), Color(0.30, 0.105, 0.09),
		Color(0.53, 0.35, 0.28), Color(0.055, 0.049, 0.047),
		PORTRAIT_NOFIA
	)
	nofia_portrait.custom_minimum_size = Vector2(130, 290)
	portrait_gallery.add_child(nofia_portrait)

	var kest_portrait := _make_portrait(
		"PortraitKest", "KEST", 2,
		Color(0.90, 0.20, 0.15), Color(0.30, 0.105, 0.09),
		Color(0.53, 0.35, 0.28), Color(0.10, 0.07, 0.05),
		PORTRAIT_KEST
	)
	kest_portrait.custom_minimum_size = Vector2(110, 290)
	portrait_gallery.add_child(kest_portrait)


func _make_portrait(
	node_name: String,
	display_name: String,
	variant: int,
	crew_color: Color,
	clothing_color: Color,
	skin_color: Color,
	hair_color: Color,
	texture_path: String = ""
) -> Control:
	var portrait := Control.new()
	portrait.name = node_name
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var painted: Texture2D = null
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		painted = load(texture_path) as Texture2D
	if painted != null:
		var frame := TextureRect.new()
		frame.name = "PaintedPortrait"
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		frame.texture = painted
		portrait.add_child(frame)
		var caption := Label.new()
		caption.text = display_name
		caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		caption.offset_top = -28
		caption.offset_bottom = -4
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 13)
		caption.add_theme_color_override("font_color", PALE)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(caption)
		return portrait
	portrait.set_script(PORTRAIT_SCRIPT)
	portrait.set("portrait_name", display_name)
	portrait.set("character_variant", variant)
	portrait.set("crew_color", crew_color)
	portrait.set("clothing_color", clothing_color)
	portrait.set("skin_color", skin_color)
	portrait.set("hair_color", hair_color)
	return portrait


func _add_panel(parent: Control, panel_position: Vector2, panel_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = panel_position
	panel.size = panel_size
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.018, 0.026, 0.94), Color(0.26, 0.35, 0.37, 0.62)))
	parent.add_child(panel)
	return panel


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _add_label(
	parent: Control,
	text: String,
	label_position: Vector2,
	label_size: Vector2,
	font_size: int,
	color: Color,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	label.size = label_size
	label.custom_minimum_size = label_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _add_bar_bg(parent: Control, bar_position: Vector2, bar_size: Vector2) -> void:
	var bar := ColorRect.new()
	bar.position = bar_position
	bar.size = bar_size
	bar.color = Color(0.22, 0.28, 0.30)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)


func _add_bar_fill(parent: Control, bar_position: Vector2, bar_size: Vector2, color: Color) -> ColorRect:
	var bar := ColorRect.new()
	bar.position = bar_position
	bar.size = bar_size
	bar.color = color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	return bar


func _clear_menu() -> void:
	for child in menu_buttons.get_children():
		menu_buttons.remove_child(child)
		child.queue_free()
	default_focus = null


func _make_button(label: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(460, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	var fill := Color(0.07, 0.22, 0.35) if primary else Color(0.045, 0.075, 0.09)
	var hover := Color(0.10, 0.32, 0.48) if primary else Color(0.075, 0.13, 0.15)
	button.add_theme_stylebox_override("normal", _button_style(fill, Color(0.24, 0.36, 0.37)))
	button.add_theme_stylebox_override("hover", _button_style(hover, BLUE))
	button.add_theme_stylebox_override("focus", _button_style(hover, BLUE))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.10, 0.25, 0.38), BLUE))
	button.pressed.connect(callback)
	button.set_meta("navigation_role", "back" if label.begins_with("BACK") or label == "TITLE SCREEN" else "action")
	menu_buttons.add_child(button)
	if default_focus == null:
		default_focus = button
	return button


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(fill, border)
	style.set_corner_radius_all(4)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _show_menu(title: String, body: String, accent: Color) -> void:
	menu_active = true
	hud_root.visible = false
	menu_root.visible = true
	(menu_root.get_meta("scrim") as Control).visible = true
	menu_title.text = title
	menu_title.add_theme_color_override("font_color", accent)
	menu_body.text = body
	portrait_gallery.visible = false
	concept_image.visible = false
	concept_caption.visible = false
	_clear_menu()
	call_deferred("_focus_default")


func _focus_default() -> void:
	if is_instance_valid(default_focus):
		default_focus.grab_focus()


func show_home() -> void:
	_show_menu(
		"AUR09",
		"Lurna and Nofia were once the closest of friends. Now they stand on opposite shores.\n"
		+ "An original story of old promises, chosen family, and what survives the fall.",
		BLUE
	)
	_show_character_gallery(true)
	_make_button("BEGIN", play_requested.emit, true)
	_make_button("HOW TO PLAY", instructions_requested.emit)
	_make_button("QUIT", Callable(self, "_request_quit"))


func show_story_intro() -> void:
	_show_menu(
		"THE RIVER REMEMBERS",
		"Once, Lurna and Nofia crossed the Ash Yard side by side. When the reactor failed, each chose a different way to save their crew.\n\n"
		+ "At the edge of their old home, the friends must cross a burning forest before they can confront the choice that divided them.",
		BLUE,
	)
	_show_character_gallery(false)
	_make_button("BACK TO TUTORIAL", intro_back_requested.emit)
	_make_button("ENTER THE OLD HOUSE", intro_start_requested.emit, true)


func _show_character_gallery(show_reference: bool) -> void:
	portrait_gallery.visible = true
	concept_image.visible = show_reference
	concept_caption.visible = show_reference


func show_instructions() -> void:
	_show_menu(
		"BEFORE THE FIRST ROUND",
		"Move: WASD / arrows     Strike: J / Space\n"
		+ "Dash: Shift / K     Energy pulse: E / L\n\n"
		+ "Land strikes to charge your pulse. Heavy attacks glow red before the floor gives way.\n"
		+ "LURNA: We said no one gets left behind.\n"
		+ "NOFIA: The breach left me one impossible choice.\n\n"
		+ "Mouse, keyboard focus, and controller D-pad navigation are supported.",
		PALE
	)
	_make_button("START THE TUTORIAL", Callable(self, "show_tutorial"), true)
	_make_button("BACK", instructions_back_requested.emit)


func show_tutorial(step_index: int = 0) -> void:
	tutorial_step = clampi(step_index, 0, TUTORIAL_STEPS.size() - 1)
	tutorial_viewed.emit()
	_show_tutorial_step()


func _show_tutorial_step() -> void:
	var step: Dictionary = TUTORIAL_STEPS[tutorial_step]
	_show_menu(step["title"], step["body"], BLUE if tutorial_step < 2 else RED)
	_show_character_gallery(false)
	_make_button("BACK", Callable(self, "_back_from_tutorial"))
	_make_button(
		"CONTINUE" if tutorial_step < TUTORIAL_STEPS.size() - 1 else "CONTINUE TO STORY",
		Callable(self, "_next_tutorial_step"),
		true
	)
	_make_button("SKIP TUTORIAL", tutorial_start_requested.emit)


func _previous_tutorial_step() -> void:
	tutorial_step = maxi(0, tutorial_step - 1)
	_show_tutorial_step()


func _back_from_tutorial() -> void:
	if tutorial_step > 0:
		_previous_tutorial_step()
	else:
		tutorial_exit_requested.emit()


func _next_tutorial_step() -> void:
	if tutorial_step >= TUTORIAL_STEPS.size() - 1:
		tutorial_start_requested.emit()
		return
	tutorial_step += 1
	_show_tutorial_step()


func show_combat() -> void:
	menu_active = false
	menu_root.visible = false
	(menu_root.get_meta("scrim") as Control).visible = false
	hud_root.visible = true
	combat_back_button.visible = true
	story_back_button.visible = false
	story_prompt.text = ""
	_focus_default_if_menu()


func show_exploration(location_name: String, objective: String) -> void:
	menu_active = false
	menu_root.visible = false
	(menu_root.get_meta("scrim") as Control).visible = false
	hud_root.visible = true
	combat_back_button.visible = false
	story_back_button.visible = true
	status_label.text = location_name.to_upper()
	story_prompt.text = objective
	_focus_default_if_menu()


func show_pause() -> void:
	_show_menu(
		"THE MOMENT HOLDS",
		"The crews wait on opposite sides of the broken ground. Return to the duel, or leave this round.",
		BLUE
	)
	_make_button("BACK TO THE FIGHT", resume_requested.emit, true)
	_make_button("BACK TO TITLE", home_requested.emit)
	hud_root.visible = false


func _focus_default_if_menu() -> void:
	if is_instance_valid(default_focus):
		default_focus.release_focus()


func show_round_result(won: bool, has_next_level: bool, round_number: int) -> void:
	var title: String
	if round_number == 2:
		title = "BLUE CREW WINS THE DUEL" if won else "RED CREW WINS THE DUEL"
	else:
		title = "ROUND %d / BLUE CREW ADVANCES" % round_number if won else "ROUND %d / RED CREW HOLDS" % round_number
	var body: String
	if won and has_next_level:
		body = "Lurna and Nofia meet again under different skies.\nThe people they once trusted still stand between them."
	elif won:
		body = "The blue crew holds the Floodline. Lurna offers Nofia her hand; Nofia doesn't take it yet.\nThe fight is over. Their friendship is unfinished."
	else:
		body = "Your crew is down. The arena holds its breath.\nTry a different approach, or return to the title screen."
	_show_menu(title, body, BLUE if won else RED)
	if won and has_next_level:
		_make_button("CONTINUE TO LEVEL TWO", round_continue_requested.emit, true)
	_make_button("PLAY AGAIN" if round_number == 2 and won else "RETRY THIS LEVEL", retry_requested.emit)
	_make_button("BACK TO TITLE", home_requested.emit)


func add_combat_back_button() -> void:
	var back_button := _make_button("PAUSE  /  BACK", pause_requested.emit)
	back_button.name = "CombatBackButton"
	menu_buttons.remove_child(back_button)
	back_button.custom_minimum_size = Vector2(150, 38)
	back_button.position = Vector2(1108, 132)
	back_button.focus_mode = Control.FOCUS_NONE
	hud_root.add_child(back_button)
	combat_back_button = back_button


func _request_quit() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if not menu_active:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.physical_keycode == KEY_ESCAPE:
			_navigate_back()
			get_viewport().set_input_as_handled()
		elif key.physical_keycode in [KEY_UP, KEY_W]:
			_focus_relative(-1)
			get_viewport().set_input_as_handled()
		elif key.physical_keycode in [KEY_DOWN, KEY_S, KEY_TAB]:
			_focus_relative(1)
			get_viewport().set_input_as_handled()
		elif key.physical_keycode in [KEY_ENTER, KEY_SPACE]:
			_activate_focused()
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton:
		var button := event as InputEventJoypadButton
		if not button.pressed:
			return
		if button.button_index == JOY_BUTTON_DPAD_UP:
			_focus_relative(-1)
			get_viewport().set_input_as_handled()
		elif button.button_index == JOY_BUTTON_DPAD_DOWN:
			_focus_relative(1)
			get_viewport().set_input_as_handled()
		elif button.button_index == JOY_BUTTON_A:
			_activate_focused()
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if motion.axis == JOY_AXIS_LEFT_Y and absf(motion.axis_value) > 0.7:
			_focus_relative(1 if motion.axis_value > 0.0 else -1)
			get_viewport().set_input_as_handled()


func _focus_relative(direction: int) -> void:
	var buttons: Array[Button] = []
	for child in menu_buttons.get_children():
		if child is Button:
			buttons.append(child as Button)
	if buttons.is_empty():
		return
	var current := buttons.find(get_viewport().gui_get_focus_owner() as Button)
	if current < 0:
		current = 0 if direction > 0 else buttons.size() - 1
	else:
		current = posmod(current + direction, buttons.size())
	buttons[current].grab_focus()


func _activate_focused() -> void:
	var focused := get_viewport().gui_get_focus_owner() as Button
	if focused == null or not focused.is_visible_in_tree():
		focused = default_focus
	if is_instance_valid(focused):
		focused.pressed.emit()


func _navigate_back() -> void:
	if tutorial_step > 0:
		tutorial_back_requested.emit()
	elif menu_title.text != "AUR09":
		instructions_back_requested.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not menu_active or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE:
		_navigate_back()
		get_viewport().set_input_as_handled()


func update_match(
	blue_team: Array[TeamFighter],
	red_team: Array[TeamFighter],
	energy: float,
	round_number: int
) -> void:
	for index in range(2):
		var blue: TeamFighter = blue_team[index]
		var red: TeamFighter = red_team[index]
		blue_fills[index].size.x = 306.0 * blue.health / blue.max_health
		red_fills[index].size.x = 306.0 * red.health / red.max_health
		(hud_root.get_node("BlueName%d" % index) as Label).text = blue.fighter_name.to_upper()
		(hud_root.get_node("RedName%d" % index) as Label).text = red.fighter_name.to_upper()
	energy_fill.size.x = 144.0 * energy / 100.0
	energy_value.text = "%d / 100" % roundi(energy)
	status_label.text = "ROUND %d  /  %s" % [round_number, "THE ASH YARD" if round_number == 1 else "THE FLOODLINE"]


func button_named(label: String) -> Button:
	for child in menu_buttons.get_children():
		if child is Button and (child as Button).text == label:
			return child as Button
	return null
