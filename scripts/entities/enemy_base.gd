extends Area2D
## EnemyBase — extensible base class for future enemy types.
##
## Purpose: Phase 0 ships one placeholder enemy that drifts toward the
## player. All future enemy types extend this class (M3). Handles
## movement toward the player, HP, and the "dies to 3 hits" rule
## wired through EventBus.
##
## Signals:
##   died(enemy: Node) — emitted when this enemy's HP hits 0.
##
## Groups:
##   "enemy" — so bullets can detect enemies via group queries.

signal died(enemy: Node)

const GROUPS = ["enemy"]

@export var max_hp: int = 3
@export var drift_speed: float = 60.0

var _hp: int = 0
var _seed: int
var _rng: Rng

func _ready() -> void:
	add_to_group(GROUPS)
	_hp = max_hp
	# Seeded spawn behavior: drift toward a point computed from the
	# run seed so identical runs produce identical enemy spawn positions.
	_seed = RunState.seed
	_rng = Rng.new(_seed)
	_rng.randomize()
	_drift_target = _calc_drift_target()

func _calc_drift_target() -> Vector2:
	# One placeholder enemy drifts in toward the player from above.
	# Radius between 300 and 450 px, angle computed from seed.
	var angle = _rng.randf_range(0.0, TAU)
	var dist = _rng.randi_range(300, 450)
	var origin = Vector2(0, -dist)
	return origin.rotated(angle) + global_position

func _physics_process(delta: float) -> void:
	# Drift toward the player.
	var to_player = (global_position - get_global_mouse_position()).normalized()
	velocity = to_player * drift_speed
	move_and_slide()

func take_hit(damage: int) -> void:
	_hp -= damage
	EventBus.enemy_hit_by_bullet.emit(self)
	if _hp <= 0:
		_die()

func _die() -> void:
	died.emit(self)
	EventBus.enemy_died.emit(self)
	queue_free()

func get_current_hp() -> int:
	return _hp
