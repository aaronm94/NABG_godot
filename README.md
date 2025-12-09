# Not Another Backroooms Game (NABG)

_A 3D Survival Horror Prototype built in Godot 4.5.1_

## Overview

**Not Another Backrooms Game (NABG)** is a first-person survival horror prototype developed for **COMP 4555 - Game Development** at Mount Royal University.
Built in Godot 4.5.1 (GDScript), the game focuses on procedural exploration, liminal-space atmosphere, and simple but tense survival mechanics.
The project draws inspiration from Backrooms media and indie experiments with uncanny architectural spaces

This repository contains the full source for the prototype, including procedural level generation, a modular player controller, interactive objects, enemy AI, and all UI systems.

## Core Premise

Players awaken in an endless maze of fluorescent-lit, low-ceiling offices - **“The Backrooms.”**
Their goal is simple: navigate procedural rooms, survive hazards, avoid the chaser enemy, and reach the exit.
Every run changes the layout, encouraging repeat attempts and environmental awareness.

## Features

### Gameplay

- First-person controller with:
  - Acceleration, deceleration, jumping, sprinting
  - Stamina system with exhaustion and recovery
  - Free-fly debug mode
  - Interaction system via RayCast3D
- Procedural dungeon generation using the SimpleDungeons addon.
- Hazard system including:
  - Pitfall kill volumes
  - AI chaser enemy (idle → chase → kill)
  - Custom death reasons and state handling
- Dynamic spawn-point system with checkpoint updates.
- Key pickup → teleport sequence → exit progression.

### Audio

- Full music system with:
  - Mode-based track switching (menu, gameplay, death, complete)
  - Persistent volume settings via `AudioSettings`
- SFX system supporting:
  - Randomized footstep playback
  - Spatial attack and chase sounds
  - Enemy idle/chase loops and capture cues
- Licensed tracks and sound effects per project documentation

### UI

- Main Menu
- Options Menu with live-preview audio sliders
- Controls page
- Pause Menu
- Death Menu with delayed reveal + fade-in death message
- Level Complete screen
- HUD (health, stamina, interact label)

### Procedural Level System

- SimpleDungeons integration
- Multiple room variations (corridor, exit room, key room, trap room, stairs, etc.)
- Modular room parts (doors, ceilings, floors, lights)
- Automatic player spawn once generation completes
- Backrooms PBR textures for aesthetic consistency

### Project Structure

```
res://
├── addons/
│   ├── backrooms_textures/
│   └── SimpleDungeons/          # Procedural generation addon
│
├── autoload/
│   ├── audio_manager.gd         # Central BGM + SFX system
│   ├── audio_settings.gd        # Volume storage + bus control
│   ├── game_actions.gd          # Global gameplay helpers (teleport)
│   └── game_state.gd            # Core game logic + modes
│
├── docs/                        # HCD, dev logs, design notes
│
├── scenes/
│   ├── gameplay/
│   │   ├── player/
│   │   │   ├── proto_controller.tscn/.gd
│   │   │   └── interact_ray, head, collider
│   │   ├── interactables/
│   │   │   ├── interactable.gd
│   │   │   ├── key.tscn/.gd
│   │   │   └── exit_door.tscn/.gd
│   │   ├── enemies/
│   │   │   └── chaser.tscn/.gd
│   │   ├── props/
│   │   │   ├── kill_volume_pit.tscn/.gd
│   │   │   └── player_spawn_hook.gd
│   │   └── utilities/
│   │       ├── start_spawn_point.tscn
│   │       ├── exit_spawn_point.tscn
│   │       └── enemy_spawn_point.tscn
│   │
│   ├── world/
│   │   ├── rooms/               # corridor, key_room, exit_room, traps
│   │   ├── room_parts/          # floors, ceilings, trims, lights
│   │   ├── levels/              # level_one.tscn, level_test.tscn
│   │   └── sounds/              # music/ + sfx/
│   │
│   ├── ui/
│   │   ├── main_menu/
│   │   │   ├── mainmenu.tscn/.gd
│   │   │   ├── controls.tscn/.gd
│   │   │   └── options.tscn/.gd
│   │   ├── game_menu/           # pause, death, complete
│   │   │   └── game_menu.tscn/.gd
│   │   ├── hud/
│   │   │   └── hud.tscn/.gd
│   │   └── shaders/             # VHS effects, overlays
│
├── textures/
│   ├── corridor_walls.tres
│   └── floor.tres
│
├── default_bus_layout.tres
├── export_presets.cfg
├── icon.svg
└── README.md

```

## How to Play

### Controls

- `WASD` — Move
- `Space` — Jump
- `Shift` — Sprint
- `E` — Interact
- `Esc` — Pause
- `F` — Free-fly (debug mode)

### Goal

Find the key, survive harzards, avoid the chaser, and reach the exit.

## Installation & running

1. Install **Godot 4.5.1**
2. Clone the repository
3. Open the project and launch (`NABG_godot/NABG.exe`)
4. Enjoy

## Team

| Member              | Role                                    | Responsibilities                    |
| ------------------- | --------------------------------------- | ----------------------------------- |
| **Justin Nunez**    | Communications Lead, Developer          | Map layout, environment assembly    |
| **Anthony Tran**    | QA Lead, Developer                      | Player controller, menus, testing   |
| **Aaron Matviyets** | Creative Director, Developer            | UI, aesthetic consistency           |
| **Justin Serrano**  | Team Coach, Technical Writer, Developer | Architecture, integration, dev logs |

## Sources & Credits

### Textures

- Backrooms PBR Texture Pack - OpenGameArt.org (https://opengameart.org/content/backrooms-pbr-texture-pack)

### Music

Licensed under CC BY-SA 4.0 - Full credits in documentation

### Sound Effects

Pixabay & SFXEngine - detailed credits in documentation

### Procedural Generation

SimpleDungeons (majikayogames) Github addon
(https://github.com/majikayogames/SimpleDungeons/wiki)

### Acknowledgements

This project was developed with the assistance of **ChatGPT (OpenAI)** for documentation, code refactoring, best-practice guidance, and optimization support.

## Future Extensions

- More room variants
- Multi-floor Backrooms
- Improved AI (hearing, cone-of-vision, patrol loops)
- Collectibles / challenges
- Full narrative progression
- VHS shader refinements

## License

This project is for **educational use** under MRU’s COMP 4555 course requirements.
Assets maintain their original licenses (CC BY-SA, CC BY, MIT, etc.) as noted.
