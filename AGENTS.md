# Repository Guidelines

## Project Structure & Module Organization
- `index.html`: Web 游戏入口。
- `js/`: 核心前端逻辑，包括主流程、骨牌、物理、建筑和音频。
- `css/`: 页面与游戏界面样式。
- `readme.md`: 项目简介与使用方式。
- `make_sounds.py`: 可选的声音资源辅助脚本。
- `CLAUDE.md`: 仓库协作说明。

## Build, Test, and Development Commands
- 本项目没有构建流程，也没有包管理器。
- 直接在浏览器中打开 `index.html` 进行开发验证。
- 需要本地静态服务时，可使用：
  ```bash
  python3 -m http.server 8000
  ```

## Coding Style & Naming Conventions
- 语言以原生 `HTML`、`CSS`、`JavaScript` 为主。
- 保持现有 4 空格缩进风格，不要混入无关框架或构建工具。
- 类型和类名使用 `UpperCamelCase`，函数、变量使用 `lowerCamelCase`。
- UI 文案以中文为主，学习内容与发音相关文本可保留英文。

## Testing Guidelines
- 以浏览器手动验证为主。
- 修改交互、布局、动画或音频后，至少确认：
  - 页面能正常加载。
  - 骨牌摆放、推倒和连锁逻辑没有明显回归。
  - 发音与基础音效仍可触发。
  - 桌面端常见视口下布局没有明显错位。

## Commit & Pull Request Guidelines
- 提交信息可以使用简短中文，或清晰的 Conventional Commit 风格。
- 一次提交尽量只解决一个问题。
- 涉及 UI 或交互改动时，PR 应附上截图或录屏，并说明手动验证结果。
