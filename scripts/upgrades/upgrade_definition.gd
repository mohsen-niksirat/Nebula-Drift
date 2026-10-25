extends Resource
## UpgradeDefinition — a single upgrade pick definition.
##
## Purpose: declare an upgrade's identity and give a hook that applies
## its effect to the current run (RunState). Upgrades are loaded from
## UpgradeRegistry rather than instantiated directly.
##
## Fields:
##   id          — unique key, e.g. "extra_speed"
##   name        — display name
##   description — shown in the upgrade pick UI (future phases)
##   rarity      — 0 = common, 1 = uncommon, 2 = rare, 3 = legendary
##   icon_color  — neon accent color used in placeholder art
##   apply       — Callable(run_state) that applies the effect

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var rarity: int = 0
@export var icon_color: Color = Color.WHITE

# Stored as a Callable so the registry can assign behavior per-instance.
var apply: Callable = Callable()

func apply_to(run_state: RunState) -> void:
	"""Invoke the stored apply callable (safe no-op if unset)."""
	if apply.is_valid():
		apply.call(run_state)
