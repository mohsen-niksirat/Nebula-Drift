extends CharacterBody2D
## Player — the player ship controller.
##
## Purpose: handle WASD/arrow movement and Space/mouse-click shooting.
## Shoots toward the mouse cursor; bullets are spawned via the pooled
## object (ObjectPool) required by Phase 0.

var _speed: float = 200.0
var _fire_rate: float = 0.5
var _cooldown: float = 0.0

func _ready() -> void:
	_speed = RunState.movement_speed
	_fire_rate = RunState.fire_rate

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_shooting(delta)

func _handle_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1
	input_dir = input_dir.normalized()
	velocity = input_dir * _speed
	move_and_slide()

func _handle_shooting(delta: float) -> void:
	_cooldown -= delta
	if _cooldown <= 0.0 and _is_shooting():
		_fire()

func _is_shooting() -> bool:
	return Input.is_mouse_button_pressed(BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)

func _fire() -> void:
	# Aim toward mouse cursor.
	var mouse := get_global_mouse_position()
	var dir := (mouse - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	# Spawn offset slightly ahead of the ship.
	var spawn_pos := global_position + dir * 28.0
	ObjectPool.spawn_bullet(spawn_pos, dir)
	EventBus.player_shoot.emit(spawn_pos, dir)
	_cooldown = _fire_rate
