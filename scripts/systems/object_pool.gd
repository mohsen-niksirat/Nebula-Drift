extends Node
## ObjectPool — generic pooled-spawner for reusable instances.
##
## Purpose: avoid per-shot instantiation overhead and keep the scene
## stable across long runs. ALL bullet spawning must go through this
## pool (Phase 0 requirement): bullets are acquired via spawn_bullet()
## and released back via release_bullet() — never queue_free()'d.
##
## Usage:
##     var b = ObjectPool.spawn_bullet(pos, dir)
##     # bullet returns itself via release_bullet() on hit / timeout

const BULLET_SCENE := preload("res://scenes/bullets/Bullet.tscn")

var _available: Array[Node2D] = []
var _active: Array[Node2D] = []
var _bullet_container: Node = null

signal spawned(instance: Node)
signal returned(instance: Node)

func _ready() -> void:
	_bullet_container = Node2D.new()
	_bullet_container.name = "BulletPool"
	add_child(_bullet_container)

func spawn_bullet(pos: Vector2, dir: Vector2, speed: float = 420.0) -> Node2D:
	var bullet: Node2D
	if _available.size() > 0:
		bullet = _available.pop_back()
		bullet.visible = true
		bullet.set_physics_process(true)
	else:
		bullet = BULLET_SCENE.instantiate()
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
		_available.append(bullet)
		returned.emit(bullet)

func release_all() -> void:
	for b in _active.duplicate():
		release_bullet(b)

func get_active_count() -> int:
	return _active.size()

func get_available_count() -> int:
	return _available.size()
