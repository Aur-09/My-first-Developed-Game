# Aur09

An original Godot 4.7.2 full-3D arena-fighting vertical slice. Former best friends Lurna and Nofia are now leaders on opposing crews; Iona and Kest have been pulled into the conflict. The cast and environments are original and use no imported art or external dependencies. The title screen's user-provided concept image is presented only as a moodboard; its depicted figures do not define the canonical names or story.

## Run

Open this folder in **Godot 4.7.2 .NET** and press **F6** with `scenes/main.tscn` open, or use **F5** to run the configured project. Godot .NET can run GDScript and C#; this prototype uses GDScript only.

## Play flow and controls

The game opens on the Aur09 title screen. Choose **BEGIN** or **HOW TO PLAY**, review the controls and short Lurna/Nofia exchange, then step through the tutorial with **BACK**, **CONTINUE**, or **SKIP TUTORIAL**. The story introduction leads to a small explorable home, then an open forest clearing before the industrial Ash Yard duel. Walk to each north exit and press **E** to continue. A win in Ash Yard advances to Floodline, a flooded waterfront and river-district arena, for the final round. Each exploration screen and match screen has a persistent **BACK TO TITLE** control; **Escape** returns from exploration or opens the combat pause menu.

| Input | Action |
| --- | --- |
| Mouse click | Activate visible menu buttons |
| Up/down, W/S, Tab | Move menu focus |
| Enter or Space | Activate the focused menu button |
| Gamepad D-pad / left stick | Move menu focus |
| Gamepad A | Activate the focused menu button |
| Escape | Go back from instructions/tutorial |
| WASD or arrow keys | Move Lurna |
| E near an exit | Continue from the house or forest |
| Escape while exploring | Return to title |
| J or Space | Close-range strike |
| Shift or K | Dash and briefly evade damage |
| E or L | Spend 45 energy on the pulse |

Strike hits refill pulse energy. Nofia's crew telegraphs heavy attacks on the floor; move off red-warning tiles before they collapse. Lurna's pulse and heavy impacts can also endanger floor tiles. A fighter caught above a collapsing tile takes damage and is moved to safety.

The house and Emberwood are story/exploration stages rather than additional combat rounds. Emberwood has three large, persistent stylized fire props with animated flame meshes, smoke, and light; their hazard areas are marked by the world composition and are blocked in exploration movement. The flame is a handcrafted real-time shader/mesh effect, not a physically simulated fire system.

## Scene structure

- `scenes/main.tscn` is the authored 3D entry scene. It contains the camera, lights, environment, four named fighter instances, and both arena instances. Ash Yard is visible initially; Floodline is present but hidden until round two.
- `scenes/characters/fighter.tscn` separates reusable fighter state from the instanced `character_model.tscn`.
- `scenes/characters/character_model.tscn` contains visible mesh nodes for faces, eyes, hair, clothing, limbs, boots, and gauntlets. `character_model.gd` applies the team palette and variant hairstyles, then animates simple poses.
- `scenes/arenas/ash_yard.tscn` is an industrial reactor platform. `floodline.tscn` changes the setting to a flooded riverfront, with a broad animated water plane, raised quay walls, a bridge and piers, warehouses, dock walks and mooring posts. It carries a different procedural evening sky and fog environment as well as its own floor palette and lights.
- `scenes/arenas/tile_grid.tscn` contains the 40 authored floor-tile instances, so the intact arena floor is visible in the editor. `arena.gd` owns warning timers, per-tile damage states, and collapse/reset behavior.
- `scenes/locations/old_home.tscn` and `emberwood.tscn` are separate authored, visible editor scenes. The main scene instances them as hidden runtime alternatives; their own scenes can be opened directly for a complete preview. Emberwood instances the reusable `fire_source.tscn` and `pine_tree.tscn` assets.
- `scripts/main.gd` coordinates the staged state flow, bounded story movement/exit interactions, combat, AI, and stage progression. Fire sources animate only while their location is active; `scripts/game_ui.gd` builds real Godot `Button` controls and routes their signals, keyboard focus, and controller menu navigation.
- `scripts/effects.gd` creates short-lived impact and pulse effects at runtime.
- `tests/smoke_flow.gd` exercises menu Button signals, keyboard navigation, all tutorial/story/back routes, story-location traversal and fire/environment visibility, character identity/portraits, tile connectivity/reset, AI recovery in a shared tile, attack range/hits, pause, and round progression.

### Inspecting the authored scene in Godot

Open `scenes/main.tscn` and frame the selected root/arena in the 3D viewport if needed. Expand `Arena` to inspect Ash Yard and its authored `TileGrid/Tile_*` nodes; expand `Lurna` or `Nofia` to inspect the character meshes. `ArenaTwo` is hidden in the initial match view; open `scenes/arenas/floodline.tscn` directly to inspect its complete waterfront composition and sky, or toggle its **Visible** property in the main scene. In play, the controller switches the active WorldEnvironment to the selected arena's authored environment. Dynamic warnings, defeated fighters, and temporary effects are runtime state; the stable fighter meshes, both floor grids, and each stage landscape are authored scene content.

## Learning and extending

Make one small change at a time and validate it before moving to another system:

1. Run the smoke test below and open `scenes/main.tscn` to inspect the authored scene.
2. For a menu-flow change, work in `game_ui.gd` and keep combat rules in `main.gd`.
3. For a new arena, duplicate an arena scene, change its environment meshes/materials/lights, and keep the floor grid naming and 8-by-5 dimensions so `arena.gd` can manage its tiles.
4. For a story location, create a separate authored scene with its own preview environment and connect its exit to a state transition in `main.gd`. Keep movement bounds and hazard checks together in `_story_position_is_open`.
5. For a character change, edit the mesh nodes in `character_model.tscn` or palette/pose logic in `character_model.gd`. Keep health, team, and attack state in `fighter.gd`.
6. Run the test and project after each bounded change; check Godot's Output and Debugger panels for the first error before continuing.

The people are now built from authored, low-poly Godot primitives with visible human face, hair, clothing, and glove shapes rather than runtime-created robot armor. This is a readable prototype blockout, not final competition character art: it has no production rig, bespoke sculpt, detailed facial animation, or hand-authored locomotion set. For a competition art pass, replace the model scene with original rigged GLB assets and animation while preserving the `TeamFighter` state/combat interface. No third-party or copyrighted art is bundled.

The story uses broad, original storybook-style framing—place, journey, choice, and consequence—rather than borrowing text, characters, or art from the linked devlog/game. The Playable Workshop channel page did not expose individual video lessons or transcripts during the earlier lookup, so no channel-specific techniques are attributed here. Specific video URLs, captions, or transcripts can ground a future lesson-by-lesson workflow.

## Godot validation

From the project folder in PowerShell, using the supplied Godot 4.7.2 .NET installation:

```powershell
& 'C:\Users\Noluthando\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path . --editor --quit
& 'C:\Users\Noluthando\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path . --script res://tests/smoke_flow.gd
& 'C:\Users\Noluthando\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path . --quit-after 30
```

The automated test fires the real `Button.pressed` signals and feeds synthetic key/controller events through the menu's input handler. Its mouse-related button check validates signal wiring, not Windows-level pointer hit testing; test an actual mouse click in the running window as part of a visual play pass.
