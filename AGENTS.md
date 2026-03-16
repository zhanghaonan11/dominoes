# Repository Guidelines

## Project Structure & Module Organization
- `dominoes/`: primary iOS SpriteKit app source (gameplay, scene logic, assets, storyboards, sounds).
- `dominoesTests/`: XCTest target, currently focused on game-flow logic (`GameFlowStateMachineTests.swift`).
- `dominoes.xcodeproj/`: Xcode project, targets, and scheme configuration.
- `index.html`, `js/`, `css/`: legacy web prototype (no active build pipeline).
- Utility/experiments: `make_sounds.py`, `sim*.swift`, and workflow notes in `CLAUDE.md`.

## Build, Test, and Development Commands
- Build app (Simulator):
  ```bash
  xcodebuild -project dominoes.xcodeproj -scheme dominoes -destination 'platform=iOS Simulator,name=iPhone 16' build
  ```
- Run all tests:
  ```bash
  xcodebuild -project dominoes.xcodeproj -scheme dominoes -destination 'platform=iOS Simulator,name=iPhone 16' test
  ```
- Run one test class:
  ```bash
  xcodebuild -project dominoes.xcodeproj -scheme dominoes -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:dominoesTests/GameFlowStateMachineTests
  ```
- Legacy web prototype: open `index.html` directly in a browser for quick checks.

## Coding Style & Naming Conventions
- Language: Swift (SpriteKit/UIKit), 4-space indentation, no tabs.
- Types use `UpperCamelCase`; methods/properties use `lowerCamelCase`; constants prefer `static let`.
- Organize constants by domain (see `GameConstants.Physics`, `GameConstants.Colors`, `GameConstants.Geometry`).
- Keep UI text in Chinese where applicable; English labels are mainly for pronunciation/learning content.
- No `SwiftLint`/`SwiftFormat` is configured; keep style consistent with existing files.

## Testing Guidelines
- Framework: XCTest (`dominoesTests` target).
- Prefer deterministic unit tests for state transitions and pure logic before scene-level behavior.
- Test names should describe behavior, e.g. `testStartFirstImpactThenCountdownResetsToIdle`.
- Add or update tests when changing game flow, timers, physics thresholds, or learning-content selection logic.

## Commit & Pull Request Guidelines
- Existing history mixes Conventional-style commits (`feat: ...`) and concise Chinese summaries; both are acceptable if clear.
- Keep commits focused to one change area (logic, UI, assets, or tests).
- PRs should include:
  - what changed and why,
  - test evidence (commands run + results),
  - screenshots/video for visual SpriteKit or UI updates,
  - notes on asset changes (sounds/images) if relevant.
