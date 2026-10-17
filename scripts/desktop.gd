extends Control
## The whole fake Windows XP desktop lives in this script.

# ======================================================================
#  1. SETTINGS YOU MAY WANT TO EDIT
# ======================================================================
const DOC_NAME := "Ao"                  # Documents login -> name
const DOC_ID := "685183658090"          # Documents login -> ID
const WAKABA_PASSWORD := "M4W6"         # password of the "Mill Wakaba" folder
const CASE_FILE_PAGES := 8              # number of page_N.png files from the PDF
const OPEN_WITH_DOUBLE_CLICK := true    # false = one click opens things
const TASKBAR_HEIGHT := 36.0

# ======================================================================
#  2. YOUR FILES (paths must match the FileSystem dock exactly)
# ======================================================================
const ICON_RECYCLE: Texture2D = preload("res://assets/icons/recycle_bin.png")
const ICON_FOLDER: Texture2D = preload("res://assets/icons/documents.png")
const ICON_IMAGE: Texture2D = preload("res://assets/icons/image.png")

# "name" = text shown to the user, "path" = where the file really is
const RECYCLE_FILES := [
	{"name": "Scratched.png", "path": "res://assets/recycle/scratched.png"},
]
const GALLERY := [
	{"name": "OfficialContract.png", "path": "res://assets/gallery/official_contract.png"},
	{"name": "RedactedRecords.png", "path": "res://assets/gallery/redacted_records.png"},
]
const CHATLOGS := [
	{"name": "[1] Suspension.png", "path": "res://assets/chatlogs/chatlog_1_suspension.png"},
	{"name": "[2] After Kikuka Sho Date.png", "path": "res://assets/chatlogs/chatlog_2_after_kikuka_sho_date.png"},
	{"name": "[3] Before Yasuda Kinen Fresh Start.png", "path": "res://assets/chatlogs/chatlog_3_before_yasuda_kinen_fresh_start.png"},
]

# ======================================================================
#  3. NODES FROM THE SCENE (names must match the Scene dock)
# ======================================================================
@onready var background: TextureRect = $Background
@onready var icon_column: VBoxContainer = $IconColumn
@onready var window_layer: Control = $WindowLayer

var _task_area: HBoxContainer
var _clock_label: Label


func _ready() -> void:
	theme = XPStyle.make_theme()      # gives every child the XP look

	# These layers are "see-through" for the mouse
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# The three desktop icons
	icon_column.position = Vector2(16, 16)
	icon_column.add_theme_constant_override("separation", 16)
	icon_column.add_child(_make_icon(ICON_RECYCLE, "Recycle Bin", true, _open_recycle_bin))
	icon_column.add_child(_make_icon(ICON_FOLDER, "Documents", true, _open_documents_login))
	icon_column.add_child(_make_icon(ICON_IMAGE, "Images", true, _open_images))

	_build_taskbar()


# Clicking empty desktop un-highlights the icons
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed:
		for icon in icon_column.get_children():
			(icon as DesktopIcon).deselect()


# ======================================================================
#  4. WINDOW + ICON HELPERS
# ======================================================================
func _make_icon(tex: Texture2D, caption: String, on_desktop: bool, action: Callable) -> DesktopIcon:
	var icon := DesktopIcon.new(tex, caption, on_desktop)
	icon.double_click_to_open = OPEN_WITH_DOUBLE_CLICK
	icon.activated.connect(action)
	return icon


## Opens a window with `content` inside it, centered (with a small cascade).
func open_window(title: String, content: Control, win_size: Vector2) -> XPWindow:
	var win := XPWindow.new(title, win_size)
	win.set_content(content)
	window_layer.add_child(win)

	var screen := get_viewport_rect().size
	var cascade := Vector2(24, 24) * (window_layer.get_child_count() % 4)
	var pos := (screen - win_size) / 2.0 + cascade - Vector2(48, 48)
	pos.x = clampf(pos.x, 0.0, maxf(0.0, screen.x - win_size.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, screen.y - TASKBAR_HEIGHT - win_size.y))
	win.position = pos

	_add_task_button(win)
	return win


## Builds the inside of a folder window: a white area with icons.
## `items` look like: {"name": "...", "icon": Texture2D, "action": Callable}
func _make_folder_view(items: Array) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", XPStyle.box(Color.WHITE, 0, Color("7f9db9"), 1, 10))
	var flow := HFlowContainer.new()      # lines icons up and wraps them
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 14)
	panel.add_child(flow)
	for item in items:
		flow.add_child(_make_icon(item["icon"], item["name"], false, item["action"]))
	return panel


## Generic "open these images in a viewer window".
func _view_images(title: String, files: Array, fit: ImageViewer.Fit, win_size: Vector2) -> void:
	open_window(title, ImageViewer.new(files, fit), win_size)


# ======================================================================
#  5. RECYCLE BIN
# ======================================================================
func _open_recycle_bin() -> void:
	var items: Array = [
		{
			"name": "Scratched.png",
			"icon": ICON_IMAGE,
			"action": _view_images.bind("Scratched.png", RECYCLE_FILES, ImageViewer.Fit.WINDOW, Vector2(720, 560)),
		},
	]
	open_window("Recycle Bin", _make_folder_view(items), Vector2(520, 320))


# ======================================================================
#  6. IMAGES
# ======================================================================
func _open_images() -> void:
	open_window("Images", ImageViewer.new(GALLERY, ImageViewer.Fit.WINDOW), Vector2(780, 560))


# ======================================================================
#  7. DOCUMENTS (login -> two folders)
# ======================================================================
func _open_documents_login() -> void:
	var dlg := FormDialog.new("Please enter your name and ID to open Documents.", ["Name:", "ID:"])
	var win := open_window("Documents - Login", dlg, Vector2(420, 250))
	# .bind(...) adds extra arguments after the ones the signal sends
	dlg.submitted.connect(_on_documents_login.bind(win, dlg))
	dlg.cancelled.connect(win.close)


func _on_documents_login(values: PackedStringArray, win: XPWindow, dlg: FormDialog) -> void:
	var name_ok := values[0].strip_edges().to_lower() == DOC_NAME.to_lower()   # ignores capitals
	var id_ok := values[1].replace(" ", "") == DOC_ID                          # ignores spaces
	if name_ok and id_ok:
		win.close()
		_open_documents_folder()
	else:
		dlg.show_error("Incorrect name or ID. Please try again.")


func _open_documents_folder() -> void:
	var items: Array = [
		{"name": "CASE FILE", "icon": ICON_FOLDER, "action": _open_case_file_folder},
		{"name": "Mill Wakaba", "icon": ICON_FOLDER, "action": _open_wakaba_login},
	]
	open_window("Documents", _make_folder_view(items), Vector2(560, 340))


# ---- Folder 1: CASE FILE ----
func _open_case_file_folder() -> void:
	var items: Array = [
		{"name": "CASE FILE #1999-0902-AO.pdf", "icon": ICON_IMAGE, "action": _open_case_file_pdf},
	]
	open_window("CASE FILE", _make_folder_view(items), Vector2(520, 320))


func _open_case_file_pdf() -> void:
	# Builds the page list: page_1.png ... page_8.png
	var pages: Array = []
	for i in range(1, CASE_FILE_PAGES + 1):
		pages.append({
			"name": "Page %d of %d" % [i, CASE_FILE_PAGES],
			"path": "res://assets/case_file/page_%d.png" % i,
		})
	open_window("CASE FILE #1999-0902-AO.pdf", ImageViewer.new(pages, ImageViewer.Fit.WIDTH), Vector2(820, 620))


# ---- Folder 2: Mill Wakaba (password) ----
func _open_wakaba_login() -> void:
	var dlg := FormDialog.new("This folder is protected. Please type the password.", ["Password:"], true)
	var win := open_window("Mill Wakaba - Password", dlg, Vector2(420, 220))
	dlg.submitted.connect(_on_wakaba_password.bind(win, dlg))
	dlg.cancelled.connect(win.close)


func _on_wakaba_password(values: PackedStringArray, win: XPWindow, dlg: FormDialog) -> void:
	if values[0] == WAKABA_PASSWORD:       # exact match, capitals matter
		win.close()
		_open_wakaba_folder()
	else:
		dlg.show_error("Incorrect password.")


func _open_wakaba_folder() -> void:
	var items: Array = []
	for entry in CHATLOGS:
		items.append({
			"name": entry["name"],
			"icon": ICON_IMAGE,
			# each chat log opens alone, fitted to the window width so you scroll down to read
			"action": _view_images.bind(entry["name"], [entry], ImageViewer.Fit.WIDTH, Vector2(640, 650)),
		})
	open_window("Mill Wakaba", _make_folder_view(items), Vector2(640, 340))


# ======================================================================
#  8. TASKBAR (start button, window buttons, clock)
# ======================================================================
func _build_taskbar() -> void:
	var bar := PanelContainer.new()
	# Stick to the bottom edge, full width
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = 0.0
	bar.offset_right = 0.0
	bar.offset_top = -TASKBAR_HEIGHT
	bar.offset_bottom = 0.0
	bar.add_theme_stylebox_override("panel", XPStyle.gradient_box(Color("3a7cf0"), Color("245edb"), Color("1941a5")))
	add_child(bar)         # added last = drawn above the windows

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	bar.add_child(row)

	var start := Button.new()
	start.text = "start"
	start.add_theme_font_size_override("font_size", 18)
	for state in ["normal", "hover", "pressed"]:
		start.add_theme_stylebox_override(state, XPStyle.box(Color("3c9b3c"), 10, Color("2a7a2a"), 1, 8))
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		start.add_theme_color_override(c, Color.WHITE)
	row.add_child(start)   # decorative for now

	_task_area = HBoxContainer.new()
	_task_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_task_area.add_theme_constant_override("separation", 4)
	row.add_child(_task_area)

	_clock_label = Label.new()
	_clock_label.custom_minimum_size.x = 84
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_clock_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(_clock_label)

	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_update_clock)
	add_child(timer)
	_update_clock()


func _update_clock() -> void:
	var t := Time.get_datetime_dict_from_system()
	var hour: int = t["hour"]
	var minute: int = t["minute"]
	var hour12 := hour % 12
	if hour12 == 0:
		hour12 = 12
	var suffix := "AM" if hour < 12 else "PM"
	_clock_label.text = "%d:%02d %s" % [hour12, minute, suffix]


func _add_task_button(win: XPWindow) -> void:
	var b := Button.new()
	b.text = win.title_text
	b.clip_text = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(160, 0)
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, XPStyle.box(Color("3c81f3"), 3, Color("1b4fb8"), 1, 6))
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.pressed.connect(_on_task_button_pressed.bind(win))
	win.tree_exiting.connect(b.queue_free)     # window closed -> its taskbar button disappears
	_task_area.add_child(b)


func _on_task_button_pressed(win: XPWindow) -> void:
	if not is_instance_valid(win):
		return
	var on_top := win.get_index() == win.get_parent().get_child_count() - 1
	if win.visible and on_top:
		win.hide()                                   # minimize
	else:
		win.show()                                   # restore / bring to front
		win.get_parent().move_child(win, -1)
