extends CanvasLayer
## HUD — display layer for HP, score, and the game-over screen.
##
## Purpose: shows HP + score labels, plus a restart button that starts
## a fresh run via GameManager.start_run(). Registered in the "hud"
## group so main.gd can find it without hard-coding the scene path.
## No gameplay logic lives here.

@onready var _hp_label: Label = $Root/Info/HBox2/HPLabel
@onready var _score_label: Label = $Root/Info/HBox2/ScoreLabel
@onready var _game_over_panel: Control = $Root/GameOver
@onready var _final_score_label: Label = $Root/GameOver/VBox2/FinalScore
@onready var _restart_button: Button = $Root/GameOver/VBox2/RestartButton

func _ready() -> void:
	add_to_group("hud")
	_game_over_panel.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_died.connect(_on_enemy_died)
	_update_stats()

func _on_restart_pressed() -> void:
	_game_over_panel.visible = false
	GameManager.start_run()

func _on_player_damaged(_amount: int, _hp: int) -> void:
	_update_stats()

func _on_enemy_died(_enemy: Node) -> void:
	_update_stats()

func _update_stats() -> void:
	_hp_label.text = "HULL: %d/%d" % [RunState.hp, RunState.max_hp]
	_score_label.text = "SCORE: %d" % RunState.score

func show_game_over() -> void:
	_final_score_label.text = "SCORE: %d" % RunState.score
	_game_over_panel.visible = true
