extends CanvasLayer
## UpgradePicker — shown when the player levels up.
##
## Purpose: presents 3 upgrade cards when the player levels up.
## Selecting one applies it to RunState and resumes the SECTOR state.
## The game does NOT pause — enemies stop via state guards instead.
## Registered in the "upgrade_picker" group.

signal picked(definition)

@onready var _panel: Control = $Panel
@onready var _cards_container: Container = $Panel/VBox/Cards
@onready var _title_label: Label = $Panel/VBox/Title
@onready var _level_label: Label = $Panel/VBox/Level

var _options: Array = []
var _current_level: int = 1

func _ready() -> void:
	add_to_group("upgrade_picker")
	_panel.visible = false
	EventBus.level_up.connect(_on_level_up)

func _on_level_up(level: int) -> void:
	_current_level = level
	_options = UpgradeRegistry.pick_three()
	print("[UpgradePicker] level %d: showing %d options" % [level, _options.size()])
	_level_label.text = "LEVEL %d" % level
	_show_options()

func _show_options() -> void:
	# Clear old cards
	for child in _cards_container.get_children():
		child.queue_free()
	# Build 3 cards
	for i in _options.size():
		var def = _options[i]
		var card = _create_card(def, i)
		_cards_container.add_child(card)
	# Failsafe: add SKIP button if options are somehow empty
	if _options.is_empty():
		var skip_btn := Button.new()
		skip_btn.text = "SKIP"
		skip_btn.pressed.connect(_on_skip_pressed)
		_cards_container.add_child(skip_btn)
		print("[UpgradePicker] WARNING: no options, added SKIP button")
	# Make the overlay visible — game does NOT pause; enemies guard their own movement.
	_panel.visible = true
	print("[UpgradePicker] panel visible: %s at position %s" % [_panel.visible, _panel.position])
	GameManager.enter_state(GameManager.State.UPGRADE_PICK)
	print("[UpgradePicker] state: %s (no pause)" % GameManager.State.keys()[GameManager.current_state])

func _create_card(def, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 140)
	btn.text = "%s\n\n%s" % [def.name, def.description]
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	# Color the button by rarity
	var style := StyleBoxFlat.new()
	style.bg_color = Color(def.icon_color.r * 0.25, def.icon_color.g * 0.25, def.icon_color.b * 0.25, 0.9)
	style.border_color = def.icon_color
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	btn.add_theme_stylebox_override("normal", style)
	# Hover effect
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(def.icon_color.r * 0.45, def.icon_color.g * 0.45, def.icon_color.b * 0.45, 0.95)
	hover.border_color = def.icon_color
	hover.border_width_left = 3
	hover.border_width_top = 3
	hover.border_width_right = 3
	hover.border_width_bottom = 3
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_right = 8
	hover.corner_radius_bottom_left = 8
	btn.add_theme_stylebox_override("hover", hover)
	# Pressed effect
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = def.icon_color
	pressed.border_color = Color.WHITE
	pressed.border_width_left = 4
	pressed.border_width_top = 4
	pressed.border_width_right = 4
	pressed.border_width_bottom = 4
	pressed.corner_radius_top_left = 8
	pressed.corner_radius_top_right = 8
	pressed.corner_radius_bottom_right = 8
	pressed.corner_radius_bottom_left = 8
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.pressed.connect(_on_card_pressed.bind(index))
	return btn

func _on_card_pressed(index: int) -> void:
	if index >= _options.size():
		return
	var def = _options[index]
	print("[UpgradePicker] picked: %s" % def.name)
	def.apply_to(RunState)
	EventBus.upgrade_picked.emit(def)
	_panel.visible = false
	_options.clear()
	GameManager.enter_state(GameManager.State.SECTOR)
	print("[UpgradePicker] resumed: state=%s" % GameManager.State.keys()[GameManager.current_state])

func _on_skip_pressed() -> void:
	# Failsafe: dismiss picker without applying any upgrade
	print("[UpgradePicker] skipped")
	_panel.visible = false
	_options.clear()
	GameManager.enter_state(GameManager.State.SECTOR)
