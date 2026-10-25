# Changelog

All notable changes to Nebula Drift will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Fixed

- None yet.
