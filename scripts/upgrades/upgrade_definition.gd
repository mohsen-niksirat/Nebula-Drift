extends Resource
## UpgradeDefinition — a single upgrade pick definition.
##
## Purpose: declare an upgrade's identity and give a hook that applies
## its effect to the current run (RunState). Upgrades are loaded from
## UpgradeRegistry.autoload rather than instantiated directly.
##
## Fields:
##   id          — unique key, e.g. "extra_speed"
##   name        — display name
##   description — shown in the upgrade pick UI (future phases)
##   rarity      — 0 = common, 1 = uncommon, 2 = rare, 3 = legendary
##   icon_color  — neon accent color used in placeholder art
##   apply(run_state) — the effect hook

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var rarity: int = 0
@export var icon_color: Color = Color.WHITE
@export var icon_path: String = ""

func apply(run_state: RunState) -> void:
	"""Override to grant the upgrade effect."""
	pass
