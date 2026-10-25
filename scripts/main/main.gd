extends Node2D
## Main — entry point that boots the GameManager and wires Phase 0 systems.
## All scenes are created programmatically via SceneFactory to bypass
## Godot 4.4 savepack crashes on .tscn files with SubResources.

const SceneFactory = preload("res://scripts/systems/scene_factory.gd")

var _player: CharacterBody2D
var _enemies: Array[CharacterBody2D] = []
var _hud: CanvasLayer
var _picker: CanvasLayer
var _wave_transitioning := false

func _ready() -> void:
	# Build all scenes in code — no .tscn files are loaded at all.
	_build_scenes()
	# M1: pause physics while in UPGRADE_PICK
	get_tree().paused = false
	# Connect state transitions BEFORE entering the first state.
	GameManager.state_changed.connect(_on_state_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_died.connect(_on_enemy_died)
	# Boot flow: MENU -> auto-start SECTOR (no title screen in Phase 0).
	GameManager.start_run()

func _build_scenes() -> void:
	_hud = SceneFactory.Hud.create()
	add_child(_hud)
	# M1: upgrade picker for level-up rewards
	_picker = SceneFactory.UpgradePicker.create()
	add_child(_picker)
	# UI is always processed so keyboard input remains available while the
	# game tree is paused during upgrade selection.

func _on_state_changed(new_state: GameManager.State, _old_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.SECTOR:
			_enter_sector()
		GameManager.State.UPGRADE_PICK:
			# No pause — UI stays interactive, enemies stop via state guard
			pass
		GameManager.State.GAME_OVER:
			_show_game_over()

func _enter_sector() -> void:
	_clear_actors()
	_spawn_player()
	if RunState.wave_index <= 0:
		_start_wave(1)
	else:
		_spawn_wave_enemies()

func _clear_actors() -> void:
	if _player != null and is_instance_valid(_player):
		_player.queue_free()
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_player = null
	_enemies.clear()
	ObjectPool.release_all()

func _start_wave(wave: int) -> void:
	_wave_transitioning = false
	RunState.start_wave(wave)
	_spawn_wave_enemies()

func _spawn_wave_enemies() -> void:
	_enemies.clear()
	var count := RunState.get_wave_enemy_count()
	for i in count:
		_spawn_enemy(i, count)
	print("[Wave] Started wave %d with %d enemies" % [RunState.wave_index, count])

func _spawn_player() -> void:
	_player = SceneFactory.Player.create()
	_player.position = Vector2(640, 360)
	add_child(_player)

func _spawn_enemy(index: int = 0, wave_count: int = 1) -> void:
	var enemy := SceneFactory.Enemy.create()
	enemy.max_hp = RunState.get_wave_enemy_hp()
	enemy.xp_value = RunState.get_wave_enemy_xp()
	# Spread the wave evenly around the player, with a seed-based offset.
	# Do not rely on _enemies.size() while spawning: each new enemy would
	# change the angle and make the apparent spawn direction deterministic.
	var angle_offset := fmod(float(RunState.run_seed) * 0.017, TAU)
	var angle := angle_offset + TAU * float(index) / float(maxi(wave_count, 1))
	enemy.position = Vector2(640, 360) + Vector2(0, -360).rotated(angle)
	add_child(enemy)
	_enemies.append(enemy)
	EventBus.enemy_spawned.emit(enemy)

func _show_game_over() -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		huds[0].show_game_over()

func _on_enemy_died(dead_enemy: Node) -> void:
	RunState.score += 10
	if _enemies.has(dead_enemy):
		_enemies.erase(dead_enemy)
	if _wave_transitioning or GameManager.current_state != GameManager.State.SECTOR:
		return
	if _enemies.is_empty():
		_wave_transitioning = true
		EventBus.wave_cleared.emit(RunState.wave_index)
		# Short breathing room between waves; next wave scales up.
		await get_tree().create_timer(1.5).timeout
		if GameManager.current_state == GameManager.State.SECTOR:
			_start_wave(RunState.wave_index + 1)

func _on_player_died() -> void:
	GameManager.enter_state(GameManager.State.GAME_OVER)
