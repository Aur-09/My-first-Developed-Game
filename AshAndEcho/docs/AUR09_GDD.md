# Aur09 — Game Design Document

## High concept

**Aur09** is a compact, full-3D arena-fighting story about former best friends Lurna and Nofia, now leaders of opposing crews. A reactor disaster forced each to choose a different way to protect the people who depended on them. Their friends Iona and Kest were drawn into the conflict, and the two leaders meet again across a changing battlefield.

## Player experience

The player controls Lurna, a green-accented fighter. Nofia and Kest carry the red identity; Iona fights beside Lurna. The tone is grounded, cinematic, and storybook-inspired: places, a journey, old promises, hard choices, and consequences. Lurna and Nofia are friends and rivals, never relatives.

The user-provided title-screen image is a moodboard reference only. It is not the canonical character roster, source for character names, or final character artwork. The game's character portraits, models, dialogue, and world presentation are separately authored.

## Playable flow

1. **Title and orientation:** Aur09 home screen, controls, short dialogue, and a four-step tutorial. Back, continue, skip, keyboard focus, and controller menu navigation are available.
2. **The Old Home:** A small explorable interior establishes the former friends' shared history. Move with WASD/arrows and press E at the north exit.
3. **Emberwood:** An open forest clearing with a stone route, creek, bridge, and persistent stylized fires. Reach the north path marker and press E.
4. **Ash Yard:** First team duel on the industrial reactor platform. Heavy attacks telegraph and destroy floor tiles; the connected-floor rule preserves routes, AI pathfinding steers around gaps, and fighters are moved to safety if a panel falls beneath them.
5. **Floodline:** Winning Ash Yard advances to the flooded waterfront for the final round. Results allow a replay or return to title.

## Core combat

- Move Lurna with **WASD** or the **arrow keys**.
- Use **J** or **Space** for a close-range strike; landed hits build energy.
- Use **Shift** or **K** to dash and briefly evade damage.
- Use **E** or **L** to spend energy on a pulse that damages nearby opponents and warns nearby floor panels.
- Escape opens the pause menu during a duel. Back-to-title controls remain available on result and exploration screens.
- Opponents approach, reposition, telegraph heavy attacks, and strike at readable ranges.

## Visual direction and implementation

The prototype uses authored Godot 3D scenes and original procedural meshes/materials: human-like fighters, distinct green/red crew palettes, authored environments, dynamic tile warnings, and short-lived impact effects. No third-party art or runtime dependency is required. The fire is a stylized animated shader-and-mesh treatment rather than a physical simulation.

The intended scenes are authored and visible in the editor. `scenes/main.tscn` is the entry point; arena and story-location scenes can also be opened directly. `scripts/main.gd` owns flow and combat orchestration, `scripts/game_ui.gd` owns screen construction/navigation, `scripts/arena.gd` owns tile connectivity and pathfinding, and `scripts/fighter.gd` owns fighter state.

## Scope and production note

Aur09 is a small solo/jam-scope vertical slice, not a competitive MOBA or a finished competition release. Current character geometry is a readable prototype blockout; a competition-quality art pass would require original rigged character assets, production animation, audio, accessibility options, and broader device testing.
