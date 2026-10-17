class_name ImageViewer
extends VBoxContainer
## Shows a list of images. Items look like: {"name": "Pretty Name.png", "path": "res://..."}

enum Fit { WIDTH, WINDOW, MANUAL }   # fit to width / fit whole image / user-chosen zoom

var _items: Array
var _index := 0
var _fit: Fit
var _zoom := 1.0
var _tex: Texture2D

var _scroll: ScrollContainer
var _pic: TextureRect
var _name_label: Label
var _zoom_label: Label
var _prev_btn: Button
var _next_btn: Button


func _init(items: Array, start_fit: Fit = Fit.WIDTH) -> void:
	_items = items
	_fit = start_fit
	add_theme_constant_override("separation", 6)

	# ----- toolbar -----
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	add_child(bar)

	_prev_btn = XPStyle.make_button("< Prev", _on_prev)
	_next_btn = XPStyle.make_button("Next >", _on_next)
	_prev_btn.visible = items.size() > 1     # hide arrows when there's only one image
	_next_btn.visible = items.size() > 1
	bar.add_child(_prev_btn)
	bar.add_child(_next_btn)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.clip_text = true
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bar.add_child(_name_label)

	bar.add_child(XPStyle.make_button("-", _zoom_by.bind(0.8), 30.0))
	_zoom_label = Label.new()
	_zoom_label.custom_minimum_size.x = 52
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(_zoom_label)
	bar.add_child(XPStyle.make_button("+", _zoom_by.bind(1.25), 30.0))
	bar.add_child(XPStyle.make_button("Fit width", _set_fit.bind(Fit.WIDTH), 80.0))
	bar.add_child(XPStyle.make_button("Fit page", _set_fit.bind(Fit.WINDOW), 80.0))

	# ----- the scrolling picture area -----
	var backdrop := PanelContainer.new()
	backdrop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	backdrop.add_theme_stylebox_override("panel", XPStyle.box(Color("6b6b6b"), 0, Color("7f9db9"), 1, 0))
	add_child(backdrop)

	_scroll = ScrollContainer.new()
	backdrop.add_child(_scroll)

	var center := CenterContainer.new()          # keeps small images centered
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(center)

	_pic = TextureRect.new()
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_SCALE
	_pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	center.add_child(_pic)

	# When the window is laid out or resized, recalculate the zoom
	_scroll.resized.connect(_apply_zoom)

	_show_item(0)


func _show_item(index: int) -> void:
	_index = clampi(index, 0, _items.size() - 1)
	var item: Dictionary = _items[_index]

	_name_label.text = str(item["name"])
	if _items.size() > 1:
		_name_label.text += "   (%d / %d)" % [_index + 1, _items.size()]
	_prev_btn.disabled = _index == 0
	_next_btn.disabled = _index == _items.size() - 1

	_tex = load(item["path"]) as Texture2D
	if _tex == null:
		_name_label.text = "Could not load: " + str(item["path"])
		_pic.texture = null
		_pic.custom_minimum_size = Vector2.ZERO
		return

	_pic.texture = _tex
	_scroll.scroll_vertical = 0       # always start reading from the top
	_scroll.scroll_horizontal = 0
	_apply_zoom()


func _apply_zoom() -> void:
	if _tex == null:
		return
	var tex_size := _tex.get_size()
	if _fit != Fit.MANUAL:
		var avail := _scroll.size - Vector2(20, 4)     # leave room for the scrollbar
		if avail.x <= 0 or avail.y <= 0:
			return                                      # not laid out yet; resized will call us again
		var by_width := avail.x / tex_size.x
		var by_height := avail.y / tex_size.y
		_zoom = by_width if _fit == Fit.WIDTH else minf(by_width, by_height)
	_pic.custom_minimum_size = tex_size * _zoom
	_zoom_label.text = "%d%%" % roundi(_zoom * 100.0)


func _zoom_by(factor: float) -> void:
	_fit = Fit.MANUAL
	_zoom = clampf(_zoom * factor, 0.1, 8.0)
	_apply_zoom()


func _set_fit(mode: Fit) -> void:
	_fit = mode
	_apply_zoom()


func _on_prev() -> void:
	_show_item(_index - 1)


func _on_next() -> void:
	_show_item(_index + 1)
