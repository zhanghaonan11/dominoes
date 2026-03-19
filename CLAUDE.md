# CLAUDE.md

This repository is a pure Web domino mini-game.

## Project Overview

The app is implemented with plain `HTML`, `CSS`, and `JavaScript`. Players place dominoes, trigger a chain reaction, and hear pronunciation through browser speech APIs. Native-app code and IDE project files are out of scope for this repository.

## Run

- Open `index.html` directly in a browser, or
- Serve the folder locally with:

```bash
python3 -m http.server 8000
```

## Main Files

- `index.html`: page entry
- `js/main.js`: overall game flow and UI coordination
- `js/domino.js`: domino model and behavior
- `js/physics.js`: physics logic
- `js/building.js`: target / building visuals
- `js/audio.js`: speech and sound handling
- `css/style.css`: layout and presentation

## Working Notes

- Keep the project lightweight and framework-free.
- Prefer small, incremental fixes over broad rewrites.
- Validate changes in a real browser after editing interaction, layout, or audio behavior.
