class_name XPStyle
extends RefCounted
## Small helpers that give controls the Windows XP look.
## All functions are "static", so you call them like: XPStyle.box(...)


## A flat colored rectangle, optionally rounded and with a border.
static func box(bg: Color, radius: int = 0, border: Color = Color.TRANSPARENT, border_width: int = 0, padding: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_width)
	s.border_color = border
	s.set_content_margin_all(padding)
	return s


## A rectangle filled with a top-to-bottom 3-color gradient (title bar, taskbar).
static func gradient_box(top: Color, middle: Color, bottom: Color) -> StyleBoxTexture:
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	g.add_point(0.5, middle)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0.5, 0.0)
	t.fill_to = Vector2(0.5, 1.0)
	t.width = 8
	t.height = 64
	var s := StyleBoxTexture.new()
	s.texture = t
	return s


## Quick way to make a button and wire it to a function.
static func make_button(text: String, callback: Callable, min_width: float = 72.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 26)
	b.pressed.connect(callback)
	return b


## One theme for the whole desktop: every Label/Button/LineEdit inside inherits it.
static func make_theme() -> Theme:
	var t := Theme.new()

	# Labels: black text
	t.set_color("font_color", "Label", Color.BLACK)

	# Buttons: beige XP buttons with a dark blue border
	t.set_stylebox("normal", "Button", box(Color("f4f3ee"), 3, Color("003c74"), 1, 6))
	t.set_stylebox("hover", "Button", box(Color("fff4d2"), 3, Color("e59700"), 1, 6))
	t.set_stylebox("pressed", "Button", box(Color("d6d2c2"), 3, Color("003c74"), 1, 6))
	t.set_stylebox("disabled", "Button", box(Color("ece9d8"), 3, Color("aca899"), 1, 6))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(color_name, "Button", Color.BLACK)
	t.set_color("font_disabled_color", "Button", Color("808080"))

	# Text fields: white box, black text
	t.set_stylebox("normal", "LineEdit", box(Color.WHITE, 0, Color("7f9db9"), 1, 5))
	var focus := box(Color.WHITE, 0, Color("2a6fd6"), 1, 5)
	focus.draw_center = false
	t.set_stylebox("focus", "LineEdit", focus)
	t.set_color("font_color", "LineEdit", Color.BLACK)
	t.set_color("caret_color", "LineEdit", Color.BLACK)

	return t
