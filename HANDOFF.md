# Pizza Fish Taco Handoff

Last updated: 2026-06-13

## Project State

The playable build is the Godot version at `project.godot`. The older Phaser/Vite prototype remains in the repo as reference code, but current development should happen in `scenes/`, `scripts/`, `assets/`, and `tools/`.

Current Phase 1 slice includes:

- Main menu, pause menu, game-over flow, and level-clear panel
- Level 1: Snack City Streets
- Pizza Fish Taco movement, jump, light combo, heavy attack, Sauce Spin, health, lives, score, and special meter
- Controller and keyboard input
- Burger Grunt, Fry Goblin, and Big Bad Burger mini-boss
- Enemy health bars, damage numbers, hit sparks, crumb bursts, hit pause, and camera shake
- Wave gates, boss arena gate, boss intro, and multiple boss attack patterns
- Imported player, enemy, and boss sprite frames with procedural fallback
- Illustrated Snack City Streets background plates
- Health, sauce, and score pickups
- Polished arcade-style HUD and ability bar

## Run Locally

```powershell
cd C:\dev\pizza_fish_taco
& 'C:\Tools\Godot\godot.exe' --path 'C:\dev\pizza_fish_taco' --scene 'res://scenes/Main.tscn'
```

## Validation

Run the full smoke-test set after behavior, scene, or asset changes:

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

## Next Best Work

1. Tune illustrated background readability in motion.
2. Split Snack City into real parallax layers and foreground prop sprites.
3. Tune player, enemy, and boss sprite offsets so feet, hit poses, and attack arcs feel locked in.
4. Tune enemy spacing and boss attack pacing from hands-on play.
5. Add controller navigation for pause/menu choices.
6. Replace placeholder pickup art with authored sprites.

## Notes For The Next Session

- `scripts/Level.gd` chooses the illustrated background plates and falls back to the procedural background if assets are missing.
- Gameplay collision is code-native, so visual plate changes should not alter combat or movement unless scene constants are changed.
- `scripts/PlayerArt.gd` owns player frame loading and procedural fallback.
- `scripts/Enemy.gd` owns Burger Grunt, Fry Goblin, and Big Bad Burger sprite frame loading.
- Keep generated or temporary edge-check files out of git; `.gitignore` already covers known artifacts.
- The art style target is colorful, crunchy, highly illustrated arcade food chaos. Preserve readability around the fight lane even when the background gets richer.
