extends Area2D
## Bullet — pooled projectile.
##
## Purpose: travels along its velocity, reports hits via EventBus, and
## is RELEASED back to the ObjectPool on despawn (never queue_free'd).
##
## Signals:
##   hit(enemy: Node) — fired when this bullet collides with an enemy.

signal hit(enemy: Node)

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1
var _lifetime: float = 3.0
var _timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func launch(dir: Vector2, speed: float) -> void:
	velocity = dir.normalized() * speed
	_timer = 0.0
	visible = true
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_timer += delta
	position += velocity * delta
	if _timer >= _lifetime:
		_despawn()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		hit.emit(body)
		EventBus.bullet_hit.emit(body)
		if body.has_method("take_hit"):
			body.take_hit(damage)
		_despawn()

func _despawn() -> void:
	# Return to the pool instead of freeing the node.
	ObjectPool.release_bullet(self)
