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

const UpgradeDefinition = preload("res://scripts/upgrades/upgrade_definition.gd")

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
		_apply_extra_speed)
	_add("fire_rate", "Rapid Firing",
		"Weapons cycle faster: +20% fire rate.", Rarity.COMMON, Color(0.3, 0.9, 1.0),
		_apply_fire_rate)
	_add("extra_hp", "Reinforced Hull",
		"Hull integrity: +20 max HP.", Rarity.UNCOMMON, Color(1.0, 0.4, 0.4),
		_apply_extra_hp)
	_add("multi_shot", "Twin Cannons",
		"Fire a second bullet with slight spread.", Rarity.RARE, Color(1.0, 0.7, 0.0),
		_apply_multi_shot)
	_add("bullet_damage", "Heavy Rounds",
		"Bullets deal +1 damage.", Rarity.UNCOMMON, Color(0.8, 0.4, 1.0),
		_apply_bullet_damage)

# --- Apply hooks (one per placeholder upgrade) ---
func _apply_extra_speed(rs) -> void:
	rs.movement_speed *= 1.15

func _apply_fire_rate(rs) -> void:
	rs.fire_rate *= 0.8

func _apply_extra_hp(rs) -> void:
	rs.max_hp += 20
	rs.hp = min(rs.hp + 20, rs.max_hp)

func _apply_multi_shot(rs) -> void:
	# M1: extra bullet flag; player.gd reads this
	rs.acquired_upgrades.append("multi_shot")

func _apply_bullet_damage(rs) -> void:
	# M1: damage flag; player.gd reads this
	rs.acquired_upgrades.append("bullet_damage")

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

func pick_three() -> Array[UpgradeDefinition]:
	# Weighted candidate list: common 50%, uncommon 30%, rare 15%,
	# legendary 5%. Repeated references encode the weights without using
	# untyped dictionaries, which is safer in the Web export.
	var weighted: Array[UpgradeDefinition] = []
	for def in get_by_rarity(Rarity.COMMON):
		weighted.append(def)
		weighted.append(def)
		weighted.append(def)
		weighted.append(def)
		weighted.append(def)
	for def in get_by_rarity(Rarity.UNCOMMON):
		weighted.append(def)
		weighted.append(def)
		weighted.append(def)
	for def in get_by_rarity(Rarity.RARE):
		weighted.append(def)
		weighted.append(def)
	for def in get_by_rarity(Rarity.LEGENDARY):
		weighted.append(def)

	var result: Array[UpgradeDefinition] = []
	var attempts := 0
	while result.size() < 3 and not weighted.is_empty() and attempts < 30:
		attempts += 1
		var candidate: UpgradeDefinition = weighted.pick_random()
		if not result.has(candidate):
			result.append(candidate)
	return result
