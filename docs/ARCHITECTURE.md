# Nebula Drift — Architecture

## Overview

Nebula Drift is a 2D space-shooter roguelite built in Godot 4.x with
GDScript only. The core design goal is a **stateless, data-driven
architecture**: gameplay systems never hold direct references to one
another, all global state flows through autoload singletons, and every
run is driven by a single RNG seed so that runs are fully
reproducible.

This document describes each system, how data flows, and the signals
that connect everything.

## High-level data flow

```
+---------------------+
|   GameManager       |  <- top-level state machine: MENU / SECTOR /
|   (State Machine)   |      UPGRADE_PICK / GAME_OVER
+---------------------+
         | state_changed
         v
+---------------------+     signals      +--------------------+
|    RunState         | <------------->  |   EventBus         |  <-
|   (run data)        |   all global     |   (signal bus)     |     every cross-system event
+---------------------+                  +--------------------+
         ^                                    ^     |
         |                                    |     +--> player_died, enemy_died,
         |                                    |        bullet_hit, ...
seed --  |        +-------------------+        |
         +------->|      Rng          |        |
                  |   (seeded RNG)    |        |
                  +-------------------+        |
                       |                       |
                       +-----------------------+
```

Run data (`RunState`) is the single source of truth for the current run.
`EventBus` is the decoupling layer. `Rng` is seeded from the run seed so
enemy spawn positions and salvage offers are deterministic.

## Autoloads

### GameManager

The top-level state machine. It owns `current_state` and emits
`state_changed(new_state, old_state)` whenever the run transitions.

States:

| State        | Meaning                                                  |
|--------------|----------------------------------------------------------|
| `MENU`       | Title / main menu. No run in progress.                   |
| `SECTOR`     | Active gameplay: player fights through one sector.       |
| `UPGRADE_PICK` | Salvage offers between sectors (M2).                   |
| `GAME_OVER`  | Run ended; score shown; restart button resets the run.   |

On entering `SECTOR`, `GameManager` resets `RunState`. On entering
`GAME_OVER`, it shows the game-over screen; the restart button calls
`RunState.reset()` and returns to `SECTOR`.

### RunState

Holds all per-run data:

- `seed` — the run RNG seed (fixed at `1337` by default; changing it
  produces a different but still reproducible run).
- `hp` / `max_hp` — current and maximum health.
- `score` — score this run.
- `sector_index` — which of the nine sectors (0-based).
- `acquired_upgrades` — list of upgrade IDs taken since the last sector.
- `movement_speed` / `fire_rate` — base runtime stats, modified by
  upgrades (and reset on run start).

`reset()` restores everything to base values and re-seeds `rng`.

### EventBus

The global signal bus. Nothing references anything else directly; all
cross-system events go through here:

| Signal                    | Emits when                                      |
|---------------------------|-------------------------------------------------|
| `enemy_spawned(enemy)`    | A new enemy enters the sector.                  |
| `enemy_died(enemy)`       | An enemy's HP reaches 0; also fires `score_inc`.|
| `bullet_hit(enemy)`       | A bullet struck an enemy.                       |
| `player_damaged(amount)`  | Player took damage.                             |
| `player_died()`           | Player HP hit 0.                                |
| `enemy_hit_by_bullet(b)`  | Enemy registered a bullet hit (for FX).         |
| `player_shoot(pos, dir)`  | Player fired.                                   |
| `sector_cleared()`        | All enemies defeated in the sector.             |
| `upgrade_picked(def)`     | An upgrade was chosen (M2).                     |

## Scripts

### core/

- `game_manager.gd` — state machine (above).
- `run_state.gd` — run data + RNG (above).
- `event_bus.gd` — signal definitions (above).

### systems/

- `object_pool.gd` — generic pooled spawner. All bullets come from it.

  ```gdscript
  ObjectPool.instance.setup_bullets(bullet_scene)
  var b = ObjectPool.instance.spawn_bullet(pos, dir)
  b.free()  # returns to the pool
  ```

- `rng.gd` — wrapped `RandomNumberGenerator` with a constructor seed,
  `reset()`, and helper methods (`randi_range`, `pick`, `shuffle`).

### upgrades/

- `upgrade_definition.gd` — a `Resource` holding `id`, `name`,
  `description`, `rarity`, `icon_color` and the `apply(run_state)` hook.
- `upgrade_registry.gd` — autoload that loads/holds all upgrade
  definitions and ships with 3 placeholder upgrades:

  | ID            | Name              | Effect                        | Rarity    |
  |---------------|-------------------|-------------------------------|-----------|
  | `extra_speed` | Overdrive Thrusters | `movement_speed *= 1.15`    | COMMON    |
  | `fire_rate`   | Rapid Firing      | `fire_rate *= 1.20`           | COMMON    |
  | `extra_hp`    | Reinforced Hull   | `max_hp += 20; hp += 20`      | UNCOMMON  |

  M2 will wire `UpgradeRegistry.pick(rng)` into the upgrade screen.

### entities/

- `player.gd` — WASD / arrow movement + Space / left-click shooting
  toward the mouse. Bullets go through `ObjectPool`.
- `enemy_base.gd` — extensible base class. Placeholder enemy drifts
  toward the player; HP = 3; dies on 3 hits and emits
  `EventBus.enemy_died`.
- `bullet.gd` — travels along `velocity`, times out after 3 s, reports
  collisions via `EventBus.bullet_hit`.

### scenes/

| Scene                     | Purpose                                  |
|---------------------------|------------------------------------------|
| `main/Main.tscn`          | Entry point; boots `GameManager`, holds the player and one placeholder enemy. |
| `ship/Player.tscn`        | Player node (moves, shoots).             |
| `enemies/Enemy.tscn`      | Placeholder enemy (drifts to player).    |
| `bullets/Bullet.tscn`     | Bullet node (pooled).                    |
| `ui/HUD.tscn`             | HP + score labels + game-over + restart button. |

## Phase 0 smoke test (playable proof of architecture)

1. `Player` moves with WASD / arrows.
2. Space / left-click fires a bullet — the bullet is created by
   `ObjectPool` (check `_active_count` / `_available_count` in the
   debugger).
3. The single placeholder `Enemy` drifts toward the player from a seeded
   position.
4. 3 bullets kill the enemy → `score` increments and
   `EventBus.enemy_died` fires.
5. Touching the enemy drops `RunState.hp` → `player_damaged` fires; on
   0 HP → `player_died` → `GAME_OVER` state.
6. The game-over screen's restart button calls
   `RunState.reset()` → HP and score return to base, state goes back to
   `SECTOR`, and the enemy respawns.
7. Seeded RNG: set a fixed `RunState.seed` and the enemy's spawn
   position is identical across two runs (verify in the debugger).
8. `UpgradeRegistry.get_all()` and `UpgradeRegistry.pick(rng)` prove the
   upgrade system loads its definitions.

## Deviations from the original Phase 0 spec

- The `UpgradePick` preset (`scripts/upgrades/upgrade_preset.tscn`) and
  `UpgradePick` script were added as scaffolding for M2; Phase 0 does not
  wire upgrade picking into the gameplay loop.
- The `main.gd` scene includes an auto-respawning enemy timer so the
  smoke test is replayable; the original prompt asked only for one
  drifting placeholder enemy.
- Godot 4.4-specific input map entries are present; if you open the
  project in 4.3 or 4.5 the input map will need a re-save.
