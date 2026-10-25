# Changelog

All notable changes to Nebula Drift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.3] — 2026-10-25

### Added

- **Phase 0.9: Web export + GitHub Pages auto-deploy**
  - `export_presets.cfg`: single "Web" preset (Godot 4.3), export path
    `build/web/index.html`, adaptive canvas resize, thread support OFF
    (GitHub Pages cannot send the COOP/COEP headers SharedArrayBuffer
    requires), no debug export.
  - `.github/workflows/deploy.yml`: on every push to `main` (plus manual
    `workflow_dispatch`), downloads Godot **4.3-stable** headless from
    godotengine/godot-builds, installs the matching export templates
    (tpz unpacked into `~/.local/share/godot/export_templates/4.3.stable/`),
    runs `godot --headless --import` (generates the `.godot/` import
    cache), then `godot --headless --export-release "Web"`, uploads the
    Pages artifact and deploys via `actions/upload-pages-artifact@v3` +
    `actions/deploy-pages@v4` (permissions: `pages: write`,
    `id-token: write`; concurrency group `pages`). Any export error
    fails the job and blocks deploy.
  - README: "Play in browser" section, CI note, updated phase table,
    and the documented one-time manual step (Settings → Pages → Source
    = GitHub Actions).
  - `.gitignore`: removed `export_presets.cfg` (the preset must be
    committed) and the `*.import` rule (Godot 4 sidecar files are
    project metadata); added `build/` so export artifacts are never
    committed.

### Notes

- Honest status: the workflow YAML was linted locally (Python
  `yaml.safe_load`) and the preset structure was sanity-parsed, but the
  live site has NOT been verified — the first real run happens on the
  next push, and the user must enable Pages (Source = GitHub Actions)
  and check https://mohsen-niksirat.github.io/nebula-drift/.

## [0.1.2] — 2026-10-25

### Fixed

- **Phase 0.75 micro-fix pass** (3 verified defects):
  - Enemy contact damage never fired: `body_entered` is an Area2D signal
    but the enemy is a CharacterBody2D. Added a `Hitbox` Area2D child
    (radius 26, larger than the 20px body) to `Enemy.tscn` with
    `collision_layer = 4` / `collision_mask = 2` (player layer), and
    connected its `body_entered` to the existing handler in `_ready()`.
  - `max_hp` leaked across runs: acquiring "Reinforced Hull" inflated
    every future run (accidental meta-progression). `RunState.reset()`
    now restores `max_hp = BASE_MAX_HP` (and base speed/fire-rate
    constants) BEFORE setting `hp = max_hp`.
  - Honesty pass on docs: this changelog now records the actual repair
    history; README no longer implies editor verification that has not
    been performed.

## [0.1.1] — 2026-10-25

### Fixed

- **Phase 0.5 repair pass** — the Phase 0 skeleton could not run:
  - Created `project.godot` (config_version=5, all 5 required autoloads,
    main scene, 1280x720 window, WASD/arrows/Space/click input map).
  - `rng.gd`: removed invalid generic syntax (`pick<T>`/`shuffle<T>`),
    stored the constructor seed and restored it in `reset()`, removed
    `randomize()` after seeding (determinism preserved).
  - `enemy_base.gd`: extends `CharacterBody2D` (`move_and_slide`/`velocity`
    now valid), chases the player via group lookup instead of the mouse,
    spawn position derives purely from `RunState.seed`, removed dead
    `_drift_target` code and post-seed `randomize()`.
  - `object_pool.gd`: fixed `spawn()` reuse path (node fetched from the
    pooled instance), full-array safe iteration, added `spawn_bullet()`/
    `release_bullet()`; bullets are released back to the pool instead of
    `queue_free()`.
  - `bullet.gd`: despawn releases to the pool; `body_entered` connected
    in `_ready()`; `Bullet.tscn` collision wired (bullets=1, enemies=3).
  - `upgrade_definition.gd`: `apply` is now a `Callable` var with an
    `apply_to()` helper (no illegal method-name assignment); registry
    builds 3 placeholder upgrades with lambdas; `pick_random()` uses
    `Array.pick()`.
  - `main.gd`: HUD found via the `hud` group (not an autoload),
    `state_changed` connected in `_ready()`, full
    MENU -> SECTOR -> GAME_OVER -> SECTOR loop via `start_run()`.
  - `game_manager.gd`: `RunState.reset()` only on run start/restart,
    not on every SECTOR entry.
  - `player.gd`: registers in the `player` group, `take_damage()` with
    a brief contact invulnerability window.
  - Removed the scratch prompt file from the repo; `.gitignore` now
    excludes `nebula-drift-phase*.txt`.
  - Scenes rewritten as clean Godot 4 text scenes (ColorRect placeholder
    art, correct collision layers: bullets=1, player=2, enemies=3).

## [0.1.0] — 2026-10-25

### Added

- **Phase 0: base architecture**
  - Project skeleton and directory structure per Phase 0 spec.
  - `GameManager` state machine (`MENU / SECTOR / UPGRADE_PICK / GAME_OVER`).
  - `RunState` run data (HP, score, sector index, seed, acquired upgrades).
  - `EventBus` global signal bus (decoupled cross-system events).
  - `ObjectPool` generic pooled spawner (all bullets come from it).
  - `Rng` seeded RNG wrapper; run seed drives reproducible enemy spawns.
  - `UpgradeRegistry` holding 3 placeholder upgrades (`extra_speed`, `fire_rate`, `extra_hp`).
  - Player entity (WASD/arrow move, Space/click shoot toward mouse).
  - Placeholder enemy (drifts toward player, 3 HP, dies on 3 hits).
  - HUD with HP + score and a game-over + restart screen.
  - `docs/STORY.md` (scenario) and `docs/ARCHITECTURE.md` (system + signal flow).
  - `README.md` with pitch, controls, and phase status table.
