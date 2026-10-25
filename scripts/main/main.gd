extends Node2D
## Main — entry point that boots the GameManager and wires Phase 0 systems.
##
## Purpose: create the player/enemy nodes, set up the pooled bullet
## spawner, connect EventBus signals, and drive the state machine.

var _player: CharacterBody2D
var _enemy: Area2D

func _ready() -> void:
	# Start in MENU, then flow to SECTOR on the restart button.
	GameManager.enter_state(GameManager.State.MENU)

func _on_state_changed(new_state: GameManager.State, old_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.MENU:
			_setup_test_scene()
		GameManager.State.SECTOR:
			_enter_sector()
		GameManager.State.UPGRADE_PICK:
			pass
		GameManager.State.GAME_OVER:
			_show_game_over()

func _enter_sector() -> void:
	_setup_test_scene()
	_player.global_position = Vector2(800, 360)
	_spawn_enemy()
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_died.connect(_on_enemy_died)

func _setup_test_scene() -> void:
	# Clear existing test actors.
	for child in get_children():
		if child.name != "GameManager" and child.name != "HUD":
			child.queue_free()
	# Reuse existing instances if created.
	if not _player or not is_instance_valid(_player):
		var p = load("res://scenes/ship/Player.tscn").instantiate()
		add_child.call_deferred(p)
		_player = p
	if not _enemy or not is_instance_valid(_enemy):
		var e = load("res://scenes/enemies/Enemy.tscn").instantiate()
		add_child.call_deferred(e)
		_enemy = e
	_enemy.visible = true

func _spawn_enemy() -> void:
	_enemy.visible = true
	_enemy.global_position = _enemy._calc_drift_target()
	EventBus.enemy_spawned.emit(_enemy)

func _show_game_over() -> void:
	HUD.show_game_over()

func _on_enemy_spawned(enemy: Node) -> void:
	print("[Main] enemy spawned")

func _on_enemy_died(enemy: Node) -> void:
	print("[Main] enemy died")
	# Respawn for the smoke test.
	await get_tree().create_timer(1.0).timeout
	_spawn_enemy()

func _on_player_died() -> void:
	print("[Main] player died")
	GameManager.enter_state(GameManager.State.GAME_OVER)

func _on_upgrade_picked(definition: UpgradeDefinition) -> void:
	# M2 hook — placeholder, not wired in Phase 0.
	print("[Main] upgrade picked:", definition.name)
