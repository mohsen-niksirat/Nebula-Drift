# Nebula Drift

**Nebula Drift** is a 2D space-shooter roguelite built in **Godot 4.x** with
GDScript only. Pilot the experimental scout *Kestrel-9* through nine
folding sectors of a rifted nebula, pick up salvage upgrades between
sectors, and reach the Beacon. Death is not the end: the Echo Drive
remembers each run and fuses fragments into permanent upgrades
(meta-progression, M4).

## The premise

The nebula was once the galaxy's busiest trade corridor. Two centuries
ago an event called the Drift tore it apart: space itself began folding,
spitting out rogue drones, derelict fleets, and things no one has a name
for. You carry the only engine that can hold a course through the folding.

**Tone:** lonely neon space, mystery — what is the Beacon?

## How to run

Requirements: **Godot 4.4 or newer** (GDScript only, no C#, no editor plugins).

1. Clone / download this repository.
2. Open `project.godot` in Godot.
3. Press **F5** or click **Scene > Run Current Scene** (`res://scenes/main/Main.tscn`).

### Controls (Phase 0 proof of architecture)

| Input          | Action                     |
|----------------|----------------------------|
| WASD / arrows  | Move the Kestrel-9         |
| Space / click  | Shoot toward the mouse     |

Phase 0 ships a minimal smoke test: one drifting enemy, pooled bullets,
HP, score, and a game-over + retry screen.

## Play in browser

After the CI workflow succeeds, the game is playable at:

**https://mohsen-niksirat.github.io/nebula-drift/**

### CI

Every push to `main` triggers [.github/workflows/deploy.yml](.github/workflows/deploy.yml):
it downloads Godot **4.4-stable** headless, installs the matching export
templates, runs `--import` then `--export-release "Web"`, and deploys
`build/web/` to GitHub Pages. If the export fails, the deploy is blocked.

**One-time manual step (not automated):** in the GitHub repo, set
**Settings → Pages → Source = "GitHub Actions"**. Until this is set,
deploys will not publish.

## Architecture (Phase 0)

- **GameManager** — top-level state machine: `MENU / SECTOR / UPGRADE_PICK / GAME_OVER`.
- **RunState** — single source of truth: HP, score, sector index, run seed, acquired upgrades.
- **EventBus** — decoupled global signal bus; systems never reference each other.
- **ObjectPool** — pooled bullet spawner; all bullets come from it.
- **Rng** — seeded RNG wrapper so runs are reproducible.
- **UpgradeRegistry** — holds upgrade definitions; ships with 3 placeholders (`extra_speed`, `fire_rate`, `extra_hp`).

Full system and signal-flow description: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Repository structure

```
nebula-drift/
├── project.godot
├── README.md
├── CHANGELOG.md
├── docs/
│   ├── STORY.md
│   └── ARCHITECTURE.md
├── scenes/
│   ├── main/Main.tscn        # entry: boots GameManager
│   ├── ship/Player.tscn
│   ├── enemies/Enemy.tscn
│   ├── bullets/Bullet.tscn
│   └── ui/HUD.tscn
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd
│   │   ├── run_state.gd
│   │   └── event_bus.gd
│   ├── systems/
│   │   ├── object_pool.gd
│   │   └── rng.gd
│   ├── upgrades/
│   │   ├── upgrade_definition.gd
│   │   └── upgrade_registry.gd
│   ├── entities/
│   │   ├── player.gd
│   │   ├── enemy_base.gd
│   │   └── bullet.gd
│   └── main/main.gd
└── assets/                   # .gitkeep (no binary assets in Phase 0)
```

## Phase status

| Phase | Description                                   | Status   |
|-------|-----------------------------------------------|----------|
| P0    | Base architecture + smoke test                | ✅ done (code-complete; editor verification pending) |
| P0.9  | Web export + GitHub Pages auto-deploy         | ✅ done (preset + workflow committed, YAML lint passed; live-site check pending user test) |
| M1    | Core movement / shooting / enemies            | ⬜ todo   |
| M2    | Upgrade picks between sectors                 | ⬜ todo   |
| M3    | Enemy variety + boss                          | ⬜ todo   |
| M4    | Meta-progression currency                     | ⬜ todo   |
| M5    | Polish (audio, particles, screen shake)       | ⬜ todo   |
| M6    | Synergies / shop / events                     | ⬜ todo   |

> **Verification note:** the Phase 0/0.5/0.75 code has been repaired and
> passes static inspection, but has **not** yet been run in the Godot
> editor by the maintainers. The manual test checklist below is the gate
> for marking P0 fully verified.

## Manual test checklist (after each phase)

- [ ] Open project in Godot 4.x: no errors/warnings in Output.
- [ ] Run: player moves, shoots, bullets pooled (no per-shot `instantiate`).
- [ ] Kill enemy: score up; touch enemy: HP down (0.6s invulnerability window); death → game-over screen.
- [ ] Restart works; run state resets (HP exactly 100/100 even after upgrades).
- [ ] Fixed seed → identical enemy spawn positions across two runs.

## License

© 2026 Nebula Drift project. (Add your license as desired.)
