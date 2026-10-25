extends Node2D
## UpgradePick — a single upgrade pick card for the M2 upgrade screen.
##
## Purpose: Phase 0 wires up the registry only; this preset is ready for
## M2 upgrade pick UI. Each instance holds one UpgradeDefinition.

var upgrade_def: UpgradeDefinition

func _ready() -> void:
	if upgrade_def:
		$"Label".text = upgrade_def.name
		$"Description".text = upgrade_def.description
