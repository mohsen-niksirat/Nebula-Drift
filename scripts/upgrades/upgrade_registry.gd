extends Node
## UpgradeRegistry — autoload that loads and holds all UpgradeDefinition
## resources.
##
## Purpose: single source of truth for the upgrade pool, so the upgrade
## pick UI (M2) and any other system can ask "what upgrades exist" or
## "give me a random upgrade". Ships with 3 placeholder upgrades
## (extra speed, fire rate, max HP) as required by Phase 0.
##
## Usage (autoload):
##     UpgradeRegistry.get_all()
##     UpgradeRegistry.pick_random()
##     UpgradeRegistry.get_by_rarity(UpgradeRegistry.Rarity.COMMON)

enum Rarity { COMMON = 0, UNCOMMON = 1, RARE = 2, LEGENDARY = 3 }

var _registry: Dictionary = {}
var _by_rarity: Dictionary = {
	Rarity.COMMON: [],
	Rarity.UNCOMMON: [],
	Rarity.RARE: [],
	Rarity.LEGENDARY: [],
}

signal registry_loaded()

func _ready() -> void:
	_register_placeholders()
	registry_loaded.emit()

func _register_placeholders() -> void:
	_add("extra_speed", "Overdrive Thrusters",
		"Engine boost: +15% movement speed.", Rarity.COMMON, Color(0.3, 1.0, 0.5),
		func(rs): rs.movement_speed *= 1.15)
	_add("fire_rate", "Rapid Firing",
		"Weapons cycle faster: +20% fire rate.", Rarity.COMMON, Color(0.3, 0.9, 1.0),
		func(rs): rs.fire_rate *= 0.8)
	_add("extra_hp", "Reinforced Hull",
		"Hull integrity: +20 max HP.", Rarity.UNCOMMON, Color(1.0, 0.4, 0.4),
		func(rs):
			rs.max_hp += 20
			rs.hp = min(rs.hp + 20, rs.max_hp))

func _add(id: String, def_name: String, desc: String, rarity: int, color: Color, fn: Callable) -> void:
	var d = UpgradeDefinition.new()
	d.id = id
	d.name = def_name
	d.description = desc
	d.rarity = rarity
	d.icon_color = color
	d.apply = fn
	_registry[id] = d
	_by_rarity[rarity].append(d)

func get_all() -> Array:
	return _registry.values()

func get_by_rarity(rarity: int) -> Array:
	return _by_rarity.get(rarity, [])

func get_by_id(id: String) -> UpgradeDefinition:
	return _registry.get(id, null)

func pick_random(rarity: int = -1) -> UpgradeDefinition:
	var pool = get_all() if rarity < 0 else get_by_rarity(rarity)
	assert(pool.size() > 0, "UpgradeRegistry: no definitions available to pick.")
	return pool.pick_random()
