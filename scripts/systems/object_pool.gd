extends Node
## ObjectPool — generic pooled-spawner for reusable instances.
##
## Purpose: avoid per-shot instantiation overhead and keep the scene
## stable across long runs. ALL bullet spawning must go through this
## pool (Phase 0 requirement): bullets are acquired via spawn_bullet()
## and released back via release_bullet() — never queue_free()'d.
##
## NOTE: bullets are created programmatically in code (not via a PackedScene)
## to avoid a Godot 4.4 savepack crash on .tscn files with SubResources.

const BULLET_SPEED := 420.0

var _bullet_script: Script
var _available: Array[Node2D] = []
var _active: Array[Node2D] = []
var _bullet_container: Node = null

signal spawned(instance: Node)
signal returned(instance: Node)

func _ready() -> void:
	_bullet_script = load("res://scripts/entities/bullet.gd")
	_bullet_container = Node2D.new()
	_bullet_container.name = "BulletPool"
	add_child(_bullet_container)

func _create_bullet() -> Node2D:
	var bullet := Area2D.new()
	bullet.set_script(_bullet_script)
	bullet.collision_layer = 1
	bullet.collision_mask = 4
	bullet.name = "Bullet"

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 12)
	shape.shape = rect
	bullet.add_child(shape)

	var sprite := ColorRect.new()
	sprite.color = Color(0.973, 0.906, 0.2)
	sprite.offset_left = -4.0
	sprite.offset_top = -4.0
	sprite.offset_right = 4.0
	sprite.offset_bottom = 4.0
	bullet.add_child(sprite)

	return bullet

func spawn_bullet(pos: Vector2, dir: Vector2, speed: float = BULLET_SPEED) -> Node2D:
	var bullet: Node2D
	if _available.size() > 0:
		bullet = _available.pop_back()
		bullet.visible = true
		bullet.set_physics_process(true)
		bullet.set_deferred("monitoring", true)
	else:
		bullet = _create_bullet()
		_bullet_container.add_child(bullet)
	bullet.global_position = pos
	if bullet.has_method("launch"):
		bullet.launch(dir, speed)
	_active.append(bullet)
	spawned.emit(bullet)
	return bullet

func release_bullet(bullet: Node2D) -> void:
	if bullet == null or not is_instance_valid(bullet):
		return
	if _active.has(bullet):
		_active.erase(bullet)
		bullet.visible = false
		bullet.set_physics_process(false)
		# Stop overlap detection while parked, otherwise an invisible
		# bullet could still "hit" enemies that walk into it.
		bullet.set_deferred("monitoring", false)
		_available.append(bullet)
		returned.emit(bullet)

func release_all() -> void:
	for b in _active.duplicate():
		release_bullet(b)

func get_active_count() -> int:
	return _active.size()

func get_available_count() -> int:
	return _available.size()
