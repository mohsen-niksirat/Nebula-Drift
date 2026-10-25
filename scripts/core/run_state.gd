extends Node
## RunState — autoload holding current run data.
##
## Purpose: a single source of truth for the running player's stats
## (HP, score, sector index, acquired upgrades) plus the run seed.
## Because it is an autoload, any system (player, enemy, HUD) can read
## or modify it, and GameManager resets it when the run ends.
##
## Run seed: a fixed seed passed in _ready() yields identical enemy
## spawn positions across runs — verified by the Phase 0 test in the
## editor: run twice with the same seed and compare spawn positions.

var rng: Rng
var seed: int = 1337
var hp: int = 100
var max_hp: int = 100
var score: int = 0
var sector_index: int = 0
var acquired_upgrades: Array[String] = []

# Player runtime stats that upgrades modify (mirrors player.gd):
var movement_speed: float = 200.0
var fire_rate: float = 0.5

func _ready() -> void:
	rng = Rng.new(seed)
	print("[RunState] run started, seed =", seed)

# --- Run lifecycle ---
func reset() -> void:
	hp = max_hp
	score = 0
	sector_index = 0
	acquired_upgrades.clear()
	rng = Rng.new(seed)
	# Apply base rates after reset so M2 upgrades can still scale them.
	movement_speed = 200.0
	fire_rate = 0.5

func take_damage(amount: int) -> void:
	hp = clamp(hp - amount, 0, max_hp)
	EventBus.instance.player_damaged.emit(amount, hp)
	if hp <= 0:
		EventBus.instance.player_died.emit()
