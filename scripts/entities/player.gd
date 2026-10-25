extends CharacterBody2D
## Player — the player ship controller.
##
## Purpose: handle WASD/arrow movement and Space/mouse-click shooting.
## Shoots toward the mouse cursor; bullets are spawned via ObjectPool.
## Registers in the "player" group so enemies can find it, and takes
## contact damage via RunState.
## M1: reads multi_shot and bullet_damage upgrades from RunState.

const CONTACT_INVULN_TIME = 0.6

var _speed: float = 200.0
var _fire_rate: float = 0.5
var _cooldown: float = 0.0
var _invuln: float = 0.0
var _has_multi_shot: bool = false
var _bullet_damage: int = 1

func _ready() -> void:
	add_to_group("player")
	_speed = RunState.movement_speed
	_fire_rate = RunState.fire_rate
	# M1: cache upgrade flags so we don't check the array every shot
	_has_multi_shot = RunState.acquired_upgrades.has("multi_shot")
	_bullet_damage = 2 if RunState.acquired_upgrades.has("bullet_damage") else 1

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_shooting(delta)
	# Keep the player inside the visible 1280x720 arena.
	global_position.x = clampf(global_position.x, 24.0, 1256.0)
	global_position.y = clampf(global_position.y, 24.0, 696.0)
	if _invuln > 0.0:
		_invuln -= delta

func _handle_movement(_delta: float) -> void:
	# Use the project input map so keyboard controls work consistently in
	# native builds and browser exports (WASD + arrow keys).
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * _speed
	move_and_slide()

func _handle_shooting(delta: float) -> void:
	_cooldown -= delta
	if _cooldown <= 0.0 and _is_shooting():
		_fire()

func _is_shooting() -> bool:
	return Input.is_action_pressed("shoot")

func _fire() -> void:
	# Aim toward mouse cursor.
	var mouse := get_global_mouse_position()
	var dir := (mouse - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var spawn_pos := global_position + dir * 28.0

	# M1: multi_shot fires 2 bullets with slight spread
	var directions := [dir]
	if _has_multi_shot:
		var spread := 0.15  # ~8.6 degrees
		directions = [dir.rotated(-spread), dir.rotated(spread)]

	for shot_dir in directions:
		var bullet = ObjectPool.spawn_bullet(spawn_pos, shot_dir)
		# M1: apply damage upgrade via method (safer than property access)
		if bullet.has_method("set_damage"):
			bullet.set_damage(_bullet_damage)

	EventBus.player_shoot.emit(spawn_pos, dir)
	_cooldown = _fire_rate

func take_damage(amount: int) -> void:
	# Brief invulnerability window so one contact doesn't drain HP instantly.
	if _invuln > 0.0:
		return
	_invuln = CONTACT_INVULN_TIME
	RunState.take_damage(amount)
