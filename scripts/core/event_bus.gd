extends Node
## EventBus — autoload global signal bus.
##
## Purpose: decouple systems so nothing holds hard references to one
## another. Every cross-system event flows through here.
##
## Signals:
##   enemy_spawned(enemy: Node)          — a new enemy entered the sector
##   enemy_died(enemy: Node)             — enemy destroyed
##   bullet_hit(enemy: Node)             — bullet struck an enemy
##   player_damaged(amount: int, hp: int) — player took damage
##   player_died()                       — player HP hit 0
##   enemy_hit_by_bullet(bullet: Node)   — enemy registered a bullet hit
##   player_shoot(position: Vector2, dir: Vector2) — player fired
##   sector_cleared()                    — all enemies defeated in sector
##   xp_gained(amount: int)              — player picked up XP
##   level_up(level: int)                — player leveled up; shows upgrade UI
##   upgrade_picked(definition)          — an upgrade was chosen (M2)
##     (definition is an UpgradeDefinition resource; left untyped to
##      keep the parse-time dependency graph acyclic)

signal enemy_spawned(enemy: Node)
signal enemy_died(enemy: Node)
signal bullet_hit(enemy: Node)
signal player_damaged(amount: int, hp: int)
signal player_died()
signal enemy_hit_by_bullet(bullet: Node)
signal player_shoot(position: Vector2, dir: Vector2)
signal sector_cleared()
signal xp_gained(amount: int)
signal level_up(level: int)
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal upgrade_picked(definition)
