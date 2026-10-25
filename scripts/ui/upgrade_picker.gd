extends CanvasLayer
## UpgradePicker — shown when the player levels up.
##
## Purpose: pauses gameplay (GameManager.UPGRADE_PICK) and presents
## 3 upgrade cards. Selecting one applies it to RunState and resumes
## the SECTOR state. Registered in the "upgrade_picker" group.

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
	if _options.is_empty():
		# No upgrades left — resume immediately
		return
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
	# Make the overlay visible before pausing physics so the browser
	# receives the input and can render the cards immediately.
	_panel.visible = true
	GameManager.enter_state(GameManager.State.UPGRADE_PICK)

func _create_card(def, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 120)
	btn.text = "%s\n%s" % [def.name, def.description]
	# Color the button by rarity
	var style := StyleBoxFlat.new()
	style.bg_color = def.icon_color * 0.3
	style.border_color = def.icon_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	btn.add_theme_stylebox_override("normal", style)
	# Hover effect
	var hover := StyleBoxFlat.new()
	hover.bg_color = def.icon_color * 0.5
	hover.border_color = def.icon_color
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", hover)
	btn.pressed.connect(_on_card_pressed.bind(index))
	return btn

func _on_card_pressed(index: int) -> void:
	if index >= _options.size():
		return
	var def = _options[index]
	def.apply_to(RunState)
	EventBus.upgrade_picked.emit(def)
	_panel.visible = false
	_options.clear()
	GameManager.enter_state(GameManager.State.SECTOR)
