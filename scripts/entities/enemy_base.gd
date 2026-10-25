extends CharacterBody2D
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

const GROUP_NAME = "enemy"
const Rng = preload("res://scripts/systems/rng.gd")

@export var max_hp: int = 3
@export var drift_speed: float = 60.0
@export var contact_damage: int = 10
@export var xp_value: int = 25  # M1: XP dropped on death

var _hp: int = 0
var _player: Node2D = null
var _spawned_via_factory := false

func _ready() -> void:
	add_to_group(GROUP_NAME)
	_hp = max_hp
	# M1: only connect Hitbox if the child exists (factory-created enemies
	# get their hitbox added by the enemy spawner before _ready)
	if has_node("Hitbox"):
		$Hitbox.body_entered.connect(_on_body_entered)
	# Main assigns wave positions. Keep the seeded fallback for enemies
	# created by other systems.
	if global_position == Vector2.ZERO:
		global_position = _calc_spawn_position()

func _calc_spawn_position() -> Vector2:
	# Spawn on a circle around the arena center (radius 300-450 px).
	# Angle + radius derive purely from the run seed -> deterministic.
	var rng = Rng.new(RunState.run_seed)
	var angle = rng.randf_range(0.0, TAU)
	var dist = rng.randi_range(300, 450)
	return Vector2(640, 360) + Vector2(0, -dist).rotated(angle)

func _physics_process(delta: float) -> void:
	# Drift toward the player (not the mouse).
	_player = _find_player()
	if _player != null and is_instance_valid(_player):
		var dir = (_player.global_position - global_position).normalized()
		velocity = dir * drift_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _find_player() -> Node2D:
	var nodes = get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null

func take_hit(damage: int) -> void:
	_hp -= damage
	EventBus.enemy_hit_by_bullet.emit(self)
	if _hp <= 0:
		_die()

func _die() -> void:
	died.emit(self)
	EventBus.enemy_died.emit(self)
	# M1: grant XP on kill
	RunState.gain_xp(xp_value)
	queue_free()

func get_current_hp() -> int:
	return _hp

func _on_body_entered(body: Node) -> void:
	# Contact damage: player touching the enemy loses HP.
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
