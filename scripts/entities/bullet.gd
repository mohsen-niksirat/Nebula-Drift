extends Area2D
## Bullet — projectile spawned by the ObjectPool.
##
## Purpose: Phase 0 requires ALL bullets come from the pool. This node
## travels along its velocity, marks the shooter, and reports hits via
## EventBus instead of holding a direct reference to the enemy.
##
## Signals:
##   hit(enemy: Node) — fired when this bullet collides with an enemy.

signal hit(enemy: Node)

var velocity: Vector2
var damage: int = 1
var _lifetime: float = 3.0
var _timer: float = 0.0

func _ready() -> void:
	# Bullet instances are detached from the parent tree by ObjectPool;
	# we do not rely on parent _ready().
	pass

func _physics_process(delta: float) -> void:
	_timer += delta
	_move(delta)
	if _timer >= _lifetime:
		queue_free()

func _move(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		hit.emit(body)
		EventBus.bullet_hit.emit(body)
		if body.has_method("take_hit"):
			body.take_hit(damage)
		queue_free()
