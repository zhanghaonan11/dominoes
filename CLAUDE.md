# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A domino puzzle game for children (aimed at 4-year-olds) to learn English letters and numbers. Players place dominoes showing letters (A-Z) and numbers (0-9), then push the first domino to trigger a chain reaction. The game includes famous landmarks that explode with particle effects when hit by the last domino.

## Development

This is a vanilla JavaScript browser game with no build system or package manager.

**To run:** Open `index.html` directly in a browser, or use any static file server.

**No tests or linting configured.**

## Architecture

The game uses four main classes that work together:

- **DominoGame** (`js/main.js`) - Main game controller. Manages the game loop, handles user input (domino/building selection, canvas clicks), coordinates between physics and rendering. Entry point initialized on DOMContentLoaded.

- **Domino** (`js/domino.js`) - Individual domino pieces with physics properties (angle, angular velocity, fall direction). Handles its own rendering and collision detection via `containsPoint()` and `checkCollision()`.

- **PhysicsEngine** (`js/physics.js`) - Manages the chain reaction simulation. Uses callbacks (`onDominoFall`, `onComplete`) to notify the game controller when dominoes fall. Key method is `update()` which processes collision between consecutive dominoes.

- **Building** (`js/building.js`) - Famous landmarks (Eiffel Tower, Pyramid, etc.) that can be placed at the end of a domino chain. Contains explosion particle system for celebration effect.

- **AudioManager** (`js/audio.js`) - Uses Web Speech API to pronounce letters/numbers in English and Web Audio API for sound effects. Maintains a queue for speech synthesis.

## Key Mechanics

- Dominoes are auto-positioned left-to-right with progressive size increase (8% larger per domino)
- Ground line is at canvas vertical center (`canvas.height / 2`)
- Physics uses simple angular acceleration; collision triggers when domino angle exceeds PI/6 and top position overlaps next domino
- All text and UI is in Chinese; letter/number pronunciation is in English
