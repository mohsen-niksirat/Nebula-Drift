extends Node
## UpgradeRegistry — autoload that loads and holds all UpgradeDefinition
## resources.
##
## Purpose: single source of truth for the upgrade pool, so the upgrade
## pick UI (M2) and any other system can ask "what upgrades exist" or
## "give me a random common upgrade". Ships with 3 placeholder upgrades
## (extra speed, fire rate, max HP) as required by Phase 0.
##
## Usage (autoload):
##     UpgradeRegistry.get_all()
##     UpgradeRegistry.pick(rng)
##     UpgradeRegistry.get_by_rarity(Rarity.COMMON)

enum Rarity {
	COMMON = 0,
	UNCOMMON = 1,
	RARE = 2,
	LEGENDARY = 3,
}

const DEF_DIR = "res://upgrades/"

var _registry: Dictionary = {}
var _by_rarity: Dictionary = {}

signal registry_loaded()

func _ready() -> void:
	_register_placeholders()
	for def in get_all():
		def.apply = _make_apply_wrapper(def)

func _register_placeholders() -> void:
	var defs = [
		_build_upgrade("extra_speed", "Overdrive Thrusters",
		               "Engine boost: +15% movement speed.", Rarity.COMMON, Color.GREEN),
		_build_upgrade("fire_rate", "Rapid Firing",
		               "Weapons cycle faster: +20% fire rate.", Rarity.COMMON, Color.CYAN),
		_build_upgrade("extra_hp", "Reinforced Hull",
		               "Hull integrity: +20 max HP.", Rarity.UNCOMMON, Color.RED),
	]
	for d in defs:
		_registry[d.id] = d
		_by_rarity[d.rarity].append(d)

func _build_upgrade(id: String, name: String, desc: String, rarity: int, color: Color) -> UpgradeDefinition:
	var d = UpgradeDefinition.new()
	d.id = id
	d.name = name
	d.description = desc
	d.rarity = rarity
	d.icon_color = color
	d.apply = func(run_state: RunState):
		match id:
			"extra_speed":
				run_state.movement_speed *= 1.15
			"fire_rate":
				run_state.fire_rate *= 1.20
			"extra_hp":
				run_state.max_hp += 20
				run_state.hp = min(run_state.hp + 20, run_state.max_hp)
	return d

func _make_apply_wrapper(def: UpgradeDefinition) -> Callable:
	# Already assigned in _ready() per definition; kept for safety.
	return def.apply

func get_all() -> Array[UpgradeDefinition]:
	return Array(_registry.values())

func get_by_rarity(rarity: int) -> Array[UpgradeDefinition]:
	return _by_rarity.get(rarity, [])

func get_random(rarity: int = -1) -> UpgradeDefinition:
	"""Pick a random upgrade from the registry (optionally filtered by rarity)."""
	var pool = get_all() if rarity < 0 else get_by_rarity(rarity)
	assert(pool.size() > 0, "UpgradeRegistry: no definitions available to pick.")
	return pool.pick(RunState.rng)
