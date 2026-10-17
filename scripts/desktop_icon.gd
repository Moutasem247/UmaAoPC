class_name DesktopIcon
extends PanelContainer
## An icon with a caption under it. Emits "activated" when the user opens it.

signal activated

## true = needs a double-click (like real Windows), false = one click opens it
var double_click_to_open := true

var _normal_style: StyleBoxEmpty
var _selected_style: StyleBoxFlat


func _init(icon: Texture2D, caption: String, on_desktop: bool = true) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Two looks for the background: invisible, or blue highlight when selected
	_normal_style = StyleBoxEmpty.new()
	_normal_style.set_content_margin_all(4)
	_selected_style = XPStyle.box(Color(0.19, 0.42, 0.78, 0.55), 2, Color(0.45, 0.65, 1.0, 0.9), 1, 4)
	add_theme_stylebox_override("panel", _normal_style)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	add_child(column)

	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = Vector2(48, 48)   # use (64, 64) for the icon's native size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)

	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 92
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if on_desktop:
		# White text with a dark shadow, like on the real XP desktop
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
	column.add_child(label)


func select() -> void:
	# Un-highlight the icons next to this one, then highlight this one
	var p := get_parent()
	if p:
		for sibling in p.get_children():
			if sibling is DesktopIcon:
				(sibling as DesktopIcon).deselect()
	add_theme_stylebox_override("panel", _selected_style)


func deselect() -> void:
	add_theme_stylebox_override("panel", _normal_style)


# Godot calls this automatically for mouse/keyboard events on this control.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		select()
		if not double_click_to_open or click.double_click:
			activated.emit()
