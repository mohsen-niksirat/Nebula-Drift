extends Node
## RunState — autoload holding current run data.
##
## Purpose: a single source of truth for the running player's stats
## (HP, score, sector index, acquired upgrades) plus the run seed.
## Because it is an autoload, any system (player, enemy, HUD) can read
## or modify it, and GameManager resets it only on run START / restart.

const Rng = preload("res://scripts/systems/rng.gd")

var rng: Rng
var run_seed: int = 1337
var hp: int = 100
var max_hp: int = 100
var score: int = 0
var sector_index: int = 0
var acquired_upgrades: Array[String] = []

const BASE_MAX_HP := 100
const BASE_MOVE_SPEED := 200.0
const BASE_FIRE_RATE := 0.5

# Player runtime stats that upgrades modify (mirrors player.gd):
var movement_speed: float = 200.0
var fire_rate: float = 0.5

# M1: XP / level progression
var level: int = 1
var xp: int = 0
var xp_to_next: int = 100
const XP_BASE := 100
const XP_GROWTH := 1.35

func _ready() -> void:
	rng = Rng.new(run_seed)
	print("[RunState] run seed =", run_seed)

# --- Run lifecycle ---
func reset() -> void:
	# Restore base stats BEFORE applying them to hp, so upgrades
	# acquired in a previous run never leak into a fresh run.
	max_hp = BASE_MAX_HP
	movement_speed = BASE_MOVE_SPEED
	fire_rate = BASE_FIRE_RATE
	hp = max_hp
	score = 0
	sector_index = 0
	acquired_upgrades.clear()
	# M1: reset XP/level
	level = 1
	xp = 0
	xp_to_next = XP_BASE
	rng = Rng.new(run_seed)

func take_damage(amount: int) -> void:
	hp = clamp(hp - amount, 0, max_hp)
	EventBus.player_damaged.emit(amount, hp)
	if hp <= 0:
		EventBus.player_died.emit()

# --- M1: XP / level progression ---
func gain_xp(amount: int) -> void:
	xp += amount
	EventBus.xp_gained.emit(amount)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(XP_BASE * pow(XP_GROWTH, level - 1))
		EventBus.level_up.emit(level)
