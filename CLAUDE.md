# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A domino chain-reaction game for children (aimed at 4-year-olds) to learn English vocabulary. Players see dominoes with emoji icons from themed categories (animals, fruits, colors, etc.), tap to customize them, then trigger a ball-roll → domino-chain → landmark-explosion sequence. The game pronounces English words via AVSpeechSynthesizer when items are selected.

The project has two implementations: a **primary iOS SpriteKit app** (`dominoes/`) and a legacy **web prototype** (`js/`, `index.html`). Active development is on the iOS app.

## Build & Test

```bash
# Build (iOS Simulator)
xcodebuild -project dominoes.xcodeproj -scheme dominoes -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project dominoes.xcodeproj -scheme dominoes -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test class
xcodebuild -project dominoes.xcodeproj -scheme dominoes -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:dominoesTests/GameFlowStateMachineTests
```

No package manager (SPM/CocoaPods). No linting configured.

## iOS App Architecture (SpriteKit)

Entry: `AppDelegate` → `GameViewController` (presents `GameScene` via Main.storyboard's `SKView`).

### Core Classes

- **GameScene** (`GameScene.swift`, ~1900 lines) — The monolithic scene. Owns all game state, UI construction, touch handling, physics contact delegation, animation sequencing, particle explosions, and auto-reset countdown. Uses `SKPhysicsContactDelegate` for domino collision events. Layout adapts to wide vs. tall screens via the internal `Layout` struct.

- **DominoNode** (`DominoNode.swift`) — `SKNode` subclass for a single domino tile. Wraps an `SKSpriteNode` (texture-based for performance) with physics body anchored at bottom-right for natural rotation. Tracks `hasFallen` state. Generates a shared base texture via `createBaseTexture()`.

- **TowerNode** (`TowerNode.swift`) — Static factory that builds vector-art landmarks (10 total: Eiffel Tower, Big Ben, Pyramid, etc.) from `SKShapeNode` primitives. Caches rendered textures per landmark+width to avoid re-rasterizing. Each landmark has a `heightFactor` used for layout sizing.

- **StaircaseNode** (`StaircaseNode.swift`) — Builds the ball's descent path as a smooth Catmull-Rom-like curve. Exposes `rollPath: [StairPathPoint]` used by `GameScene` to animate the ball along the staircase before physics takes over.

- **GameFlowStateMachine** (`GameFlowStateMachine.swift`) — Pure value-type state machine: `idle → animating → firstImpact → autoResetCountdown(n) → idle`. Enforces valid transitions. Tested in `dominoesTests/`.

- **GameConstants** (`GameConstants.swift`) — All physics tuning (mass, friction, restitution, damping, stall detection), collision bitmasks, colors, and geometry constants.

### Game Flow

1. Scene builds static elements (background gradient, clouds, ground, title, buttons) once in `buildStaticSceneOnce()`
2. `resetInteractiveElements()` creates dominos, ball, staircase, and tower fresh each round
3. "开始模拟" button → `startAnimation()` → ball animates along staircase path → `scheduleDirectFirstImpact()` teleports ball to first domino and applies impulse
4. Chain watchdog (`checkChainProgressAndNudgeIfNeeded()`) runs every 0.6s, nudges stuck dominos for kid-friendly reliability
5. After all dominos fall → tower topples → `explodeScene()` particle effects → auto-reset countdown

### Physics

- SpriteKit's built-in physics engine (not custom). Gravity: `(0, -9.2)`.
- Collision categories: `domino (1)`, `ball (2)`, `ground (4)`, `tower (8)`
- Ball physics disabled during staircase animation, enabled at first impact
- Fallen detection: domino angle exceeds 38° threshold
- Anti-stall: max 1 nudge per chain run, applies angular + linear impulse to next standing domino

### Learning Content

12 themed categories (colors, transportation, fruits, animals, plants, space, body, family, food, shapes, weather, sports) with 8-10 items each. Each item has emoji icon, English name, Chinese name, and associated color. Tapping a domino opens a `UIAlertController` picker to change its learning item.

## Web Version (Legacy)

Vanilla JS, no build system. Open `index.html` in a browser. Uses custom physics in `js/physics.js`, Web Speech API for pronunciation. Classes: `DominoGame` (main.js), `Domino` (domino.js), `PhysicsEngine` (physics.js), `Building` (building.js), `AudioManager` (audio.js).

## Key Conventions

- All UI text is in Chinese; English is only for speech pronunciation
- Sound effects: `click.wav`, `hit.wav`, `roll.wav`, `explode.wav` in `dominoes/Sounds/`
- Particle system adapts budget based on device memory and low-power mode
- TowerNode textures are cached in a static dictionary keyed by landmark+pixelWidth
