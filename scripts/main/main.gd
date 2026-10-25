extends Node2D
## Main — entry point that boots the GameManager and wires Phase 0 systems.
## Scene loads are deferred until all autoload scripts are initialized
## to prevent a cold-start circular dependency crash (see CHANGELOG).

const PLAYER_SCENE_PATH := "res://scenes/ship/Player.tscn"
const ENEMY_SCENE_PATH := "res://scenes/enemies/Enemy.tscn"
const HUD_SCENE_PATH := "res://scenes/ui/HUD.tscn"

var _player_scene: PackedScene
var _enemy_scene: PackedScene
var _hud_scene: PackedScene
var _player: CharacterBody2D
var _enemy: CharacterBody2D
var _hud: CanvasLayer

func _ready() -> void:
	# Load scenes lazily to avoid circular dependencies during autoload parse.
	_load_scenes()
	# Connect state transitions BEFORE entering the first state.
	GameManager.state_changed.connect(_on_state_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_died.connect(_on_enemy_died)
	# Boot flow: MENU -> auto-start SECTOR (no title screen in Phase 0).
	GameManager.start_run()

func _load_scenes() -> void:
	_player_scene = load(PLAYER_SCENE_PATH)
	_enemy_scene = load(ENEMY_SCENE_PATH)
	_hud_scene = load(HUD_SCENE_PATH)
	if _hud_scene != null:
		_hud = _hud_scene.instantiate()
		add_child(_hud)
	else:
		push_error("Failed to load HUD scene")

func _on_state_changed(new_state: GameManager.State, _old_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.SECTOR:
			_enter_sector()
		GameManager.State.UPGRADE_PICK:
			pass
		GameManager.State.GAME_OVER:
			_show_game_over()

func _enter_sector() -> void:
	_clear_actors()
	_spawn_player()
	_spawn_enemy()

func _clear_actors() -> void:
	for node in [_player, _enemy]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_player = null
	_enemy = null
	ObjectPool.release_all()

func _spawn_player() -> void:
	_player = _player_scene.instantiate()
	_player.position = Vector2(640, 360)
	add_child(_player)

func _spawn_enemy() -> void:
	# Spawn position is derived from RunState.run_seed inside enemy_base.gd.
	_enemy = _enemy_scene.instantiate()
	add_child(_enemy)

func _show_game_over() -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		huds[0].show_game_over()

func _on_enemy_died(_enemy: Node) -> void:
	RunState.score += 10
	# Respawn after a short delay so the smoke test is replayable.
	await get_tree().create_timer(1.0).timeout
	if GameManager.current_state == GameManager.State.SECTOR:
		_spawn_enemy()

func _on_player_died() -> void:
	GameManager.enter_state(GameManager.State.GAME_OVER)
