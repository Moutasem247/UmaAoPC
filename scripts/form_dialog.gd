class_name FormDialog
extends VBoxContainer
## A message + one or more text fields + OK/Cancel.
## It never checks answers itself, it just announces them with signals.

signal submitted(values: PackedStringArray)   # OK pressed or Enter hit
signal cancelled

var _fields: Array[LineEdit] = []
var _error_label: Label


func _init(message: String, labels: Array, secret: bool = false) -> void:
	add_theme_constant_override("separation", 10)

	var msg := Label.new()
	msg.text = message
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(msg)

	# One row per field: [label] [text box]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)

	for label_text in labels:
		var lbl := Label.new()
		lbl.text = label_text
		grid.add_child(lbl)

		var edit := LineEdit.new()
		edit.secret = secret                      # true = shows dots instead of letters
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.custom_minimum_size.x = 220
		edit.text_submitted.connect(_on_text_submitted)   # pressing Enter
		grid.add_child(edit)
		_fields.append(edit)

	_error_label = Label.new()
	_error_label.add_theme_color_override("font_color", Color("c00000"))
	add_child(_error_label)

	var spacer := Control.new()                   # pushes the buttons to the bottom
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 8)
	add_child(buttons)
	buttons.add_child(XPStyle.make_button("OK", _submit))
	buttons.add_child(XPStyle.make_button("Cancel", _on_cancel_pressed))


func _ready() -> void:
	_fields[0].grab_focus.call_deferred()    # put the cursor in the first box


## Called by desktop.gd when the answer is wrong.
func show_error(message: String) -> void:
	_error_label.text = message
	for edit in _fields:
		edit.clear()
	_fields[0].grab_focus()


func _submit() -> void:
	var values := PackedStringArray()
	for edit in _fields:
		values.append(edit.text)
	submitted.emit(values)


func _on_text_submitted(_text: String) -> void:
	_submit()


func _on_cancel_pressed() -> void:
	cancelled.emit()
