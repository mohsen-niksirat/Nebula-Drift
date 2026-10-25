extends CanvasLayer
## HUD — display layer for HP, score, sector, and the game-over screen.
##
## Purpose: Phase 0 HUD shows HP + score labels only, plus a restart
## button that resets the run via RunState.reset() and returns to
## the SECTOR state. No gameplay logic lives here.

@onready var _hp_label = $VP/HBox/VBox/Info/HBox2/HPLabel
@onready var _score_label = $VP/HBox/VBox/Info/HBox2/ScoreLabel
@onready var _game_over_panel = $VP/HBox/VBox/GameOver
@onready var _final_score_label = $VP/HBox/VBox/GameOver/VBox2/FinalScore
@onready var _restart_button = $VP/HBox/VBox/GameOver/VBox2/RestartButton

func _ready() -> void:
	_game_over_panel.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_died.connect(_on_enemy_died)
	_update_stats()

func _on_restart_pressed() -> void:
	# Reset the run and re-enter SECTOR (game over -> restart).
	_game_over_panel.visible = false
	GameManager.enter_state(GameManager.State.SECTOR)

func _on_player_damaged(amount: int, hp: int) -> void:
	_update_stats()

func _on_enemy_died(enemy: Node) -> void:
	_update_stats()

func _update_stats() -> void:
	_hp_label.text = "HULL: %d/%d" % [RunState.hp, RunState.max_hp]
	_score_label.text = "SCORE: %d" % RunState.score

func show_game_over() -> void:
	_final_score_label.text = "SCORE: %d" % RunState.score
	_game_over_panel.visible = true
