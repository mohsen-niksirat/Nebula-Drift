extends CanvasLayer
## HUD — display layer for HP, score, XP, and the game-over screen.
##
## Purpose: shows HP + score + XP/level labels, plus a restart button
## that starts a fresh run via GameManager.start_run(). Registered in
## the "hud" group so main.gd can find it without hard-coding paths.
## No gameplay logic lives here.

@onready var _hp_label: Label = $Root/Info/HPLabel
@onready var _score_label: Label = $Root/Info/ScoreLabel
@onready var _xp_label: Label = $Root/Info/XPLabel
@onready var _game_over_panel: Control = $Root/GameOver
@onready var _final_score_label: Label = $Root/GameOver/Panel/VBox2/FinalScore
@onready var _restart_button: Button = $Root/GameOver/Panel/VBox2/RestartButton

func _ready() -> void:
	add_to_group("hud")
	_game_over_panel.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.level_up.connect(_on_level_up)
	_update_stats()

func _on_restart_pressed() -> void:
	_game_over_panel.visible = false
	GameManager.start_run()

func _on_player_damaged(_amount: int, _hp: int) -> void:
	_update_stats()

func _on_enemy_died(_enemy: Node) -> void:
	_update_stats()

func _on_xp_gained(_amount: int) -> void:
	_update_stats()

func _on_level_up(_level: int) -> void:
	_update_stats()

func _update_stats() -> void:
	_hp_label.text = "HULL: %d/%d" % [RunState.hp, RunState.max_hp]
	_score_label.text = "SCORE: %d" % RunState.score
	if _xp_label != null:
		_xp_label.text = "LV %d | XP %d/%d" % [RunState.level, RunState.xp, RunState.xp_to_next]

func show_game_over() -> void:
	_final_score_label.text = "SCORE: %d | LEVEL %d" % [RunState.score, RunState.level]
	_game_over_panel.visible = true
