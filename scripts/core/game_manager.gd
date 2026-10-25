extends Node
## GameManager — autoload top-level state machine for the run.
##
## Purpose: owns the global game state and transitions between the
## four run states required by the architecture:
##   MENU            — title / main menu
##   SECTOR          — active gameplay
##   UPGRADE_PICK    — salvage offers between sectors (M2)
##   GAME_OVER       — run finished; show score + restart button
##
## Signals:
##   state_changed(new_state, old_state)

enum State { MENU, SECTOR, UPGRADE_PICK, GAME_OVER }

signal state_changed(new_state: State, old_state: State)

var current_state: State = State.MENU:
	set(value):
		if value != current_state:
			var old = current_state
			current_state = value
			state_changed.emit(current_state, old)

func _ready() -> void:
	state_changed.connect(_on_state_changed)

func enter_state(new_state: State) -> void:
	current_state = new_state

func start_run() -> void:
	# Explicit run-start entry point: resets the run, enters SECTOR.
	RunState.reset()
	enter_state(State.SECTOR)

func _on_sector() -> void:
	print("[GameManager] entering SECTOR")

func _on_upgrade_pick() -> void:
	print("[GameManager] entering UPGRADE_PICK")

func _on_game_over() -> void:
	print("[GameManager] entering GAME_OVER — run ended, score =", RunState.score)

func _on_state_changed(new_state: State, _old_state: State) -> void:
	match new_state:
		State.SECTOR:
			_on_sector()
		State.UPGRADE_PICK:
			_on_upgrade_pick()
		State.GAME_OVER:
			_on_game_over()
