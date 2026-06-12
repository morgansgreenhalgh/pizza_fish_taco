# Pizza Fish Taco Defends the Planet

Phase 1 vertical slice for an original arcade beat-em-up about Pizza Fish Taco fighting through Snack City Streets.

The project has moved to **Godot** for stronger 2D animation, controller support, and future desktop/mobile packaging. The earlier Phaser/Vite prototype is still present as reference code, but the playable project starts from `project.godot`.

## Current Status

Godot Phase 1 slice:

- Menu and game-over flow
- Level 1: Snack City Streets
- Pizza Fish Taco player character
- Keyboard and controller input
- Movement, jump, coyote-time jump forgiveness, and input buffering
- Three-hit light combo
- Heavy attack
- Sauce Spin special
- Health, lives, score, special meter
- Burger Grunt and Fry Goblin enemies
- Big Bad Burger mini-boss
- Wave gates and boss arena gate
- Enemy health bars, damage numbers, hit sparks, crumb bursts, hit pause, camera shake
- Boss intro and multiple boss attack patterns
- Imported Pizza Fish Taco animation frames with procedural fallback
- Imported Burger Grunt, Fry Goblin, and Big Bad Burger animation frames
- Health, sauce, and score pickups
- Pause menu with resume, restart, return-to-menu, and controls
- Level-clear panel with score and lives bonus
- Placeholder pickup and level art ready to be replaced by authored sprites

## Run In Godot

```powershell
cd C:\dev\pizza_fish_taco
& 'C:\Tools\Godot\godot.exe' --path 'C:\dev\pizza_fish_taco'
```

Run the main scene directly:

```powershell
cd C:\dev\pizza_fish_taco
& 'C:\Tools\Godot\godot.exe' --path 'C:\dev\pizza_fish_taco' --scene 'res://scenes/Main.tscn'
```

## Controls

Keyboard:

- Move: `A/D` or arrow keys
- Jump: `Space`, `W`, or up arrow
- Combo: `J`
- Heavy: `K`
- Sauce Spin: `L`
- Start/Menu: `Enter`

Controller:

- Move: left stick or D-pad
- Jump: `A`
- Combo: `X`
- Heavy: `B`
- Sauce Spin: `Y` or right shoulder
- Start/Menu: `Start`

## Validation

```powershell
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --quit-after 3
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' 'res://scenes/Level.tscn' --quit-after 4
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/player_art_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/enemy_art_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/combat_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/boss_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/pickup_smoke_test.gd'
```

## Next Phase 1 Work

- Tune enemy AI spacing and boss attacks after hands-on play
- Tune Pizza Fish Taco sprite animation offsets and timing after hands-on play
- Tune imported enemy and boss sprite offsets, scale, and attack pose timing
- Add richer pickup drop tuning and pickup-specific art
- Add controller navigation for pause menu choices

## Repository Notes

- `scenes/` and `scripts/` are the Godot game.
- `assets/` is the destination for authored art and sprite sheets.
- `tools/` contains headless smoke tests and art-processing helpers.
- `src/`, `package.json`, and Vite files are the earlier Phaser prototype.
- `node_modules/`, `dist/`, and Godot cache folders are ignored.
