Original prompt: 删除“开始玩”、”骨牌大小“、“提示”这三个

- 2026-03-19: 检查当前纯 Web 版入口，源码里仅直接存在“提示”卡片，没有找到字面为“开始玩”或“骨牌大小”的控件。
- 2026-03-19: 按最接近当前 UI 的最小实现，删除顶部主动作按钮和侧栏“提示”卡片，并把按钮绑定改成可选，避免 DOM 缺失时报错。
- 2026-03-19: 通过本地 `python3 -m http.server 8000` + Playwright 验证页面；顶部只剩“重置”，侧栏不再出现“提示”，点击骨牌与重置按钮正常。当前唯一控制台报错是缺失 `favicon.ico` 的 404，与本次改动无关。
- 2026-03-20: 用户反馈右上角“推倒”按钮不该被删除；已在 `index.html` 恢复 `<button id="pushBtn" class="btn btn-push">推倒!</button>`，保留 `js/main.js` 中对缺失按钮的空值保护。
- 2026-03-20: 通过本地 `python3 -m http.server 8765` + Playwright 再验页面，顶部重新同时出现“重置”和“推倒!”；点击“推倒!”后无新增控制台错误，仍仅有 `favicon.ico` 404。
- TODO: 如需连同键盘空格触发“推倒”逻辑一起去掉，再补一轮交互约束清理。
- 2026-04-24: 按用户“测试这个项目”请求做回归测试：`node --check js/*.js` 全部通过；启动 `python3 -m http.server 8000` 后用 develop-web-game Playwright client 生成 canvas 截图；另用 Playwright 覆盖页面加载、字母/数字/动物骨牌放置、建筑放置/右键删除、推倒连锁、音效/发音方法触发、重置路径，主流程通过且无 console error/pageerror。
- 2026-04-24: 测试发现一个轻微 UI 状态问题：点击“重置”会清空骨牌和建筑，但不会清除当前选中的建筑/骨牌按钮；重置后侧栏仍高亮，canvas 顶部仍显示“点击放置建筑 …”预览提示。复现状态：`selectedBuilding: "pisa"`, `selectedButtons: ["🗼比萨斜塔"]`, `previewWouldDraw: true`。
- TODO: 若要修复重置选择残留，在 `DominoGame.reset()` 内调用 `this.clearSelection()` 或等价清理，并补一轮重置后无选中态的浏览器回归。
- 2026-04-24: 已修复重置后选中态残留：在 `DominoGame.reset()` 中调用 `clearSelection()`，同步清掉 `selectedCharacter` / `selectedBuilding` / 动物选择状态与按钮 `.selected` 类。
- 2026-04-24: 回归验证通过：`node --check js/*.js` 全部通过；Playwright 覆盖“选中建筑→放置→重置”和“选中动物→放置→重置”，确认 `selectedBuilding: null`、`selectedCharacter: null`、`selectedButtons: []`、`previewWouldDraw: false`；同时放置 A/B 后点击“推倒!”确认连锁仍能完成，无 console error/pageerror。
- 2026-04-24: 开始优化并完成第一轮：补 `window.render_game_to_text()` 状态快照、`window.advanceTime(ms)` 固定步长测试接口；Canvas 改为按 `devicePixelRatio` 设置真实像素并保留 CSS 坐标绘制；统一管理主流程定时器，`reset()` 时取消旧回调并清理 `screen-shake`，避免重置后庆祝层/音频/爆炸旧状态回弹；音效改为复用单个 `AudioContext`；重置清选择时同步 blur 当前焦点。
- 2026-04-24: 优化回归通过：`node --check js/*.js` 全部通过；develop-web-game client 已生成 `state-*.json`，证明 `render_game_to_text` 生效；Playwright 在 `deviceScaleFactor=2` 下确认 canvas attribute 为 CSS 尺寸 2 倍，`advanceTime` 可推进 A/B 骨牌连锁和建筑爆炸；手动重置后等待 4.5s，确认骨牌 0、建筑 null、庆祝层未回弹、`pendingTimers` 为 0、无 console error/pageerror。
- 2026-07-26: 第二轮优化：骨牌倒下与建筑爆炸动画改为按 deltaTime 相对 60fps 基准缩放（修复高刷屏速度翻倍）；爆炸粒子/进度更新从 drawExplosion 拆到 Building.update() 由 updateFrame 驱动；startExplosion 加 explosionTriggered 幂等标志（修复埃菲尔铁塔每帧重播 celebrate 音效）；建筑配置合并为单一 BUILDING_CONFIGS、TYPES 派生（消除侧栏/画布名称不一致）；getTrackPoints 缓存、drawGrid 单路径、drawBallTrack 复用 Path2D；删除 physics 未用方法与 Domino.clone；placeDomino/placeBuilding 去掉被忽略的坐标参数；空格键不再与聚焦按钮双触发；audio initVoice 去掉 setTimeout 猜测。
- 2026-07-26: 回归通过：node --check 全部通过；Playwright 验证金字塔流程（连锁全倒→爆炸→庆祝→自动重置）与埃菲尔流程（explosionTriggered=true、isExploding=false、celebrate 音效仅播 1 次）；截图确认渲染正常，无 console error。
