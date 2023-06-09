@tool
extends PanelContainer

# theme
var _theme = preload("res://addons/debugger/resources/debugger_theme.tres")

# Monitor Types
@onready var debugger_monitor_integer = preload("res://addons/debugger/components/monitor_integer/monitor_integer.tscn")
@onready var debugger_monitor_vector2 = preload("res://addons/debugger/components/monitor_vector2/monitor_vector2.tscn")
@onready var debugger_monitor_string = preload("res://addons/debugger/components/monitor_string/monitor_string.tscn")
@onready var debugger_monitor_float = preload("res://addons/debugger/components/monitor_float/monitor_float.tscn")

# Input Types
@onready var debugger_input_integer = preload("res://addons/debugger/components/input_integer/input_integer.tscn")

@onready var ui = preload("ui.tscn").instantiate()
@onready var list = ui.get_node("%ContentList")
@onready var scroll_bar : VScrollBar = ui.get_node("%ScrollContainer").get_v_scroll_bar()
@onready var content_margin = ui.get_node("%ContentMarginContainer")
@onready var drag_button = ui.get_node("%DragButton")
@onready var diagonal_resizer = ui.get_node("%DiagonalResizer")

@onready var monitors = []
@onready var inputs = []

@export_enum("touch:3", "normal:2", "compact:1") var _density: int = 3
@export var _size: Vector2 = Vector2(350, 350): get = get_width, set = set_width
@export var font_size: int = 14: get = get_font_size, set = set_font_size

var default_padding: int = 8
var drag_start: Vector2 = Vector2(0, 0)
var drag_pressed: bool = false
var density: float = default_padding

func set_width(val: Vector2) -> void:
	_size = val
	self.size = val

func get_width() -> Vector2:
	return _size

func set_font_size(val: int) -> void:
	font_size = clamp(val, 1, 100)
	
	# set the font size(s)
	var theme_types = _theme.get_font_type_list()
	
	for theme_type in theme_types:
		
		var font_list = _theme.get_font_list(theme_type)
		
		for font in font_list:
			var _font: Font = _theme.get_font(font, theme_type)
			#_font.size = font_size

func get_font_size() -> int:
	return font_size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# If the debugger is in editor mode
	if Engine.is_editor_hint():
		init()
		
		# Do stuff only in editor
		# ...
		print("Debugger in Editor")
		
		return
	
	# else start normal
	else:
		init()
	
func init() -> void:
	# remove background of the margin container surrounding the debugger
	self.set("theme_override_styles/panel", StyleBoxEmpty.new())
	
	# set the theme
	self.set("theme", _theme)
	
	ui.custom_minimum_size = Vector2(_size.x, _size.y)
	ui.size = Vector2(_size.x, _size.y)
	
	# Vertical drag button in the heading
	drag_button.gui_input.connect(on_drag_input.bind(false))
	
	# Diagonal drag button in the bottom right
	diagonal_resizer.gui_input.connect(on_drag_input.bind(true))
	
	# add scroll container v scroll hack to add margin
	scroll_bar.visibility_changed.connect(toggle_scrollbar_margin)
	
	# padding...
	# update rate...
	# theming...
	# etc.
	
	self.add_child(ui)
	
	density = set_density(_density)
	
	# set header margin
	set_header_margin()
	
	# set content margin
	set_content_margin()
	
	# after addding the ui call this once to set the margins correctly
	toggle_scrollbar_margin()

func update() -> void:
	for monitor in monitors:
		monitor.update()

func remove(_object: String) -> bool:
	printerr("REMOVE IS NOT IMPLEMENTED")
	return false

func add_monitor(obj: Object, property: String, identifier: String) -> void:
	
	# Choose the correct monitor type (integer, vector2, etc..)
	var new_monitor = get_monitor_of_type(obj, property)
	
	# Remove the debugger help message on the first add
	list.get_node("%HelpLabel").visible = false
	
	list.add_child(new_monitor)
	
	if new_monitor != null:
		new_monitor.init(obj, property, identifier)
		monitors.append(new_monitor)

# This returns a configured monitor instance for the given control
func get_monitor_of_type(obj, property) -> Control:
	
	var new_monitor = null
	
	match typeof(obj[property]):
		TYPE_VECTOR2:
			new_monitor = debugger_monitor_vector2.instantiate()
		TYPE_VECTOR3:
			new_monitor = debugger_monitor_vector2.instantiate()
		TYPE_STRING:
			new_monitor = debugger_monitor_string.instantiate()
		TYPE_INT:
			new_monitor = debugger_monitor_integer.instantiate()
		TYPE_FLOAT:
			new_monitor = debugger_monitor_float.instantiate()
		_:
			printerr("%s is not a supported type. " % typeof(obj[property]))
			
	return new_monitor

func add_input(obj: Object, property: String, identifier: String) -> void:
	
	# Choose the correct input type (integer, vector2, etc...)
	var new_input = get_input_of_type(obj, property)
	
	list.get_node("%HelpLabel").visible = false
	
	list.add_child(new_input)
	
	new_input.init(obj, property, identifier)
	inputs.append(new_input)

func get_input_of_type(obj, property) -> Control:
	
	var new_input
	
	match typeof(obj[property]):
		#TYPE_VECTOR2:
			#new_monitor = debugger_monitor_vector2.instance()
		#TYPE_STRING:
			#new_monitor = debugger_monitor_string.instance()
		TYPE_INT:
			new_input = debugger_input_integer.instantiate()
		#TYPE_REAL:
			#new_monitor = debugger_monitor_float.instance()
			
	return new_input

func on_drag_input(event: InputEvent, also_horizontal: bool):
	# On left button click pressed
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		drag_pressed = true
		drag_start = event.position
	
	# On left button click released
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		drag_pressed = false
		
	# On button drag
	if event is InputEventMouseMotion and drag_pressed:
		if drag_start:
			self.size.x += event.position.x
			if also_horizontal:
				self.size.y += event.position.y

# Toggle the margin between the scrollbar and the content
func toggle_scrollbar_margin() -> void:
	if scroll_bar.is_visible():
		content_margin.set("theme_override_constants/margin_right", default_padding * density)
	else:
		content_margin.set("theme_override_constants/margin_right", 0)

func set_header_margin() -> void:
	var heading1 = ui.get_node("%HeadingMarginContainer1")
	var heading2 = ui.get_node("%HeadingMarginContainer2")
	
	heading1.set("theme_override_constants/margin_left", default_padding * density)
	heading1.set("theme_override_constants/margin_top", default_padding * density)
	heading1.set("theme_override_constants/margin_bottom", default_padding * density)
	
	heading2.set("theme_override_constants/margin_top", default_padding * density)
	heading2.set("theme_override_constants/margin_bottom", default_padding * density)
	heading2.set("theme_override_constants/margin_right", default_padding * density)
	
	drag_button.custom_minimum_size = Vector2(default_padding * density * 1.4, 0)

func set_content_margin() -> void:
	var outer = ui.get_node("%OuterContentMarginContainer")
	outer.set("theme_override_constants/margin_left", default_padding * density)
	outer.set("theme_override_constants/margin_right", default_padding * density)
	outer.set("theme_override_constants/margin_top", default_padding * density)
	outer.set("theme_override_constants/margin_bottom", default_padding * density)
	
	#var styles = scroll_bar.get_theme_stylebox("scroll")
	#styles.
	#print(styles)
	
func set_density(dens) -> float:
	print(dens)
	var value := 1.0
	
	if dens == 3:
		value = 1.4
	elif dens == 2:
		value = 1.2
	else:
		value = 1.0
	
	print(value)
	return value
