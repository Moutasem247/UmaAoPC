class_name XPWindow
extends PanelContainer
## A draggable Windows XP style window.
## Usage:  var win := XPWindow.new("Title", Vector2(600, 400))
##         win.set_content(some_control)
##         some_parent.add_child(win)

var title_text: String = "Window"

var _body: PanelContainer
var _dragging := false
var _drag_offset := Vector2.ZERO


func _init(title: String = "Window", window_size: Vector2 = Vector2(640, 480)) -> void:
	title_text = title
	custom_minimum_size = window_size
	size = window_size
	mouse_filter = Control.MOUSE_FILTER_STOP     # clicks on the window don't fall through
	gui_input.connect(_on_frame_gui_input)

	# --- the blue frame around everything ---
	var frame := XPStyle.box(Color("0831d9"), 0, Color.TRANSPARENT, 0, 3)
	frame.corner_radius_top_left = 8
	frame.corner_radius_top_right = 8
	frame.shadow_color = Color(0, 0, 0, 0.35)
	frame.shadow_size = 8
	frame.shadow_offset = Vector2(4, 4)
	add_theme_stylebox_override("panel", frame)

	var rows := VBoxContainer.new()          # title bar on top, body below
	rows.add_theme_constant_override("separation", 0)
	add_child(rows)

	# --- title bar (blue gradient) ---
	var bar_style := XPStyle.gradient_box(Color("3d95ff"), Color("0a5be0"), Color("0046d0"))
	bar_style.content_margin_left = 8
	bar_style.content_margin_right = 4
	bar_style.content_margin_top = 3
	bar_style.content_margin_bottom = 3
	var title_bar := PanelContainer.new()
	title_bar.custom_minimum_size.y = 28
	title_bar.add_theme_stylebox_override("panel", bar_style)
	title_bar.gui_input.connect(_on_title_gui_input)
	rows.add_child(title_bar)

	var bar_row := HBoxContainer.new()
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_row.add_theme_constant_override("separation", 2)
	title_bar.add_child(bar_row)

	var title_label := Label.new()
	title_label.text = title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	bar_row.add_child(title_label)

	bar_row.add_child(_make_title_button("_", Color("2f6fe8"), hide))    # minimize
	bar_row.add_child(_make_title_button("X", Color("d9532c"), close))   # close

	# --- body (beige area where your content goes) ---
	_body = PanelContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_stylebox_override("panel", XPStyle.box(Color("ece9d8"), 0, Color.TRANSPARENT, 0, 8))
	rows.add_child(_body)


## Put any Control inside the window.
func set_content(content: Control) -> void:
	_body.add_child(content)


func close() -> void:
	queue_free()


func _make_title_button(text: String, color: Color, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(22, 22)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_stylebox_override("normal", XPStyle.box(color, 4, Color.WHITE, 1, 0))
	b.add_theme_stylebox_override("hover", XPStyle.box(color.lightened(0.25), 4, Color.WHITE, 1, 0))
	b.add_theme_stylebox_override("pressed", XPStyle.box(color.darkened(0.25), 4, Color.WHITE, 1, 0))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.pressed.connect(callback)
	return b


# Move this window to the front (last child = drawn on top)
func _raise() -> void:
	var p := get_parent()
	if p:
		p.move_child(self, -1)


func _on_frame_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed:
		_raise()


# Dragging: remember where we grabbed, then follow the mouse
func _on_title_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT:
		_dragging = click.pressed
		if _dragging:
			_drag_offset = get_global_mouse_position() - global_position
			_raise()

	var motion := event as InputEventMouseMotion
	if motion and _dragging:
		var target := get_global_mouse_position() - _drag_offset
		var screen := get_viewport_rect().size
		target.x = clampf(target.x, 60.0 - size.x, screen.x - 60.0)   # keep the title bar reachable
		target.y = clampf(target.y, 0.0, screen.y - 60.0)
		global_position = target
