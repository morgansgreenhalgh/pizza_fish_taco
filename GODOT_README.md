# Pizza Fish Taco Defends the Planet - Godot Phase 1

This is the new Godot version of the Phase 1 vertical slice. The earlier Phaser/Vite prototype is still in the repo as a reference, but the Godot project starts at `project.godot`.

## Run

1. Open Godot 4.3 or newer.
2. Import/open this folder: `C:\dev\pizza_fish_taco`.
3. Run the project. The main scene is `res://scenes/Main.tscn`.

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

## Current Slice

- Menu
- Snack City Streets test level
- Pizza Fish Taco movement, jump, light combo, heavy, Sauce Spin
- Burger Grunt, Fry Goblin, and Big Bad Burger mini-boss
- Hitboxes, damage, knockback, health, lives, score, special meter
- HUD and boss bar
- Wave gates and boss arena flow
- Enemy health bars, damage numbers, hit sparks, crumb bursts, hit pause, and camera shake
- Smarter enemy spacing, cooldown retreat, interruptible windups, and multiple boss attacks
- Imported Pizza Fish Taco animation frames with procedural fallback and strike-frame hitbox timing
- Imported Burger Grunt, Fry Goblin, and Big Bad Burger animation frames
- Illustrated Snack City Streets background plates
- Health, sauce, and score pickups
- Polished arcade-style HUD, ability bar, menu, and game-over screens
- Pause menu and level-clear scoring panel
- Generated placeholder pickup art, ready to be replaced by authored sprites later

## Validation

```powershell
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --quit-after 3
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' 'res://scenes/Level.tscn' --quit-after 4
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/ui_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/background_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/player_art_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/enemy_art_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/combat_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/boss_smoke_test.gd'
& 'C:\Tools\Godot\godot.exe' --headless --path 'C:\dev\pizza_fish_taco' --script 'res://tools/pickup_smoke_test.gd'
```

## Suggested Next Godot Pass

Build out imported sprite sheets:
- `Player.tscn`: tune offsets, hit poses, and timing for the imported Pizza Fish Taco frames
- `Enemy.tscn`: tune Burger Grunt and Fry Goblin frames
- `Boss.tscn`: tune Big Bad Burger attack poses, scale, and impact timing
- `Level.tscn`: split background plates into true parallax layers and foreground prop sprites
