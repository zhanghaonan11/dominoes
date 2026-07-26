/**
 * 多米诺骨牌游戏 - 主程序
 */

// 动物数据
const ANIMALS = [
    { emoji: '🐶', name: 'Dog', nameCn: '狗' },
    { emoji: '🐱', name: 'Cat', nameCn: '猫' },
    { emoji: '🐼', name: 'Panda', nameCn: '熊猫' },
    { emoji: '🦁', name: 'Lion', nameCn: '狮子' },
    { emoji: '🐘', name: 'Elephant', nameCn: '大象' },
    { emoji: '🐵', name: 'Monkey', nameCn: '猴子' },
    { emoji: '🐷', name: 'Pig', nameCn: '猪' },
    { emoji: '🐮', name: 'Cow', nameCn: '牛' },
    { emoji: '🐸', name: 'Frog', nameCn: '青蛙' },
    { emoji: '🐔', name: 'Chicken', nameCn: '鸡' },
    { emoji: '🦆', name: 'Duck', nameCn: '鸭子' },
    { emoji: '🐰', name: 'Rabbit', nameCn: '兔子' }
];

class DominoGame {
    constructor() {
        // 获取DOM元素
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.letterGrid = document.getElementById('letterGrid');
        this.numberGrid = document.getElementById('numberGrid');
        this.animalGrid = document.getElementById('animalGrid');
        this.buildingGrid = document.getElementById('buildingGrid');
        this.resetBtn = document.getElementById('resetBtn');
        this.pushBtn = document.getElementById('pushBtn');
        this.celebration = document.getElementById('celebration');

        // 游戏状态
        this.dominoes = [];
        this.building = null;  // 当前放置的建筑
        this.selectedCharacter = null;
        this.selectedIsNumber = false;
        this.selectedIsAnimal = false;
        this.selectedAnimalData = null;
        this.selectedBuilding = null;  // 选中的建筑类型
        this.isAnimating = false;
        this.pendingTimers = new Set();
        this.gameRunId = 0;
        this.canvasWidth = 0;
        this.canvasHeight = 0;
        this.canvasDpr = 1;
        this.lastFrameTime = performance.now();
        this.trackPointsCache = null;  // 轨道点缓存，骨牌增删或画布变化时失效

        // 小球状态
        this.ball = {
            x: 50,
            y: 50,
            radius: 30,  // 放大1倍 (15 * 2)
            isMoving: false,
            progress: 0,  // 0-1 表示沿轨道的进度
            path: []      // 路径点
        };

        // 初始化组件
        this.physics = new PhysicsEngine();
        this.audio = new AudioManager();

        // 设置回调
        this.physics.onDominoFall = (domino, index) => this.onDominoFall(domino, index);
        this.physics.onComplete = () => this.onAllFallen();

        // 初始化
        this.init();
    }

    /**
     * 初始化游戏
     */
    init() {
        this.setupCanvas();
        this.createDominoButtons();
        this.createAnimalButtons();
        this.createBuildingButtons();
        this.setupEventListeners();
        this.setupTestHooks();
        this.gameLoop();
    }

    /**
     * 设置Canvas尺寸
     */
    setupCanvas() {
        const container = this.canvas.parentElement;
        const resize = () => {
            const width = container.clientWidth;
            const height = container.clientHeight;
            const dpr = Math.max(1, window.devicePixelRatio || 1);

            this.canvasWidth = width;
            this.canvasHeight = height;
            this.canvasDpr = dpr;
            this.canvas.width = Math.round(width * dpr);
            this.canvas.height = Math.round(height * dpr);
            this.canvas.style.width = width + 'px';
            this.canvas.style.height = height + 'px';
            this.ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
            this.invalidateTrackCache();
            this.draw();
        };

        resize();
        window.addEventListener('resize', resize);
    }

    /**
     * 暴露轻量测试接口，方便浏览器自动化读取状态和推进时间
     */
    setupTestHooks() {
        window.render_game_to_text = () => this.renderGameToText();
        window.advanceTime = (ms) => this.advanceTime(ms);
    }

    /**
     * 用于自动化测试的文本状态快照
     */
    renderGameToText() {
        const payload = {
            coordinateSystem: 'origin: top-left; x increases right; y increases down; units: CSS pixels',
            canvas: {
                width: this.canvasWidth,
                height: this.canvasHeight,
                dpr: this.canvasDpr
            },
            state: {
                isAnimating: this.isAnimating,
                physicsRunning: this.physics.isRunning,
                celebrationVisible: !this.celebration.hidden
            },
            selection: {
                character: this.selectedCharacter,
                isNumber: this.selectedIsNumber,
                isAnimal: this.selectedIsAnimal,
                animalName: this.selectedAnimalData ? this.selectedAnimalData.name : null,
                building: this.selectedBuilding
            },
            ball: {
                x: Math.round(this.ball.x),
                y: Math.round(this.ball.y),
                radius: this.ball.radius,
                isMoving: this.ball.isMoving,
                progress: Number(this.ball.progress.toFixed(3))
            },
            dominoes: this.dominoes.map((domino) => ({
                character: domino.character,
                x: Math.round(domino.x),
                y: Math.round(domino.y),
                width: domino.width,
                height: domino.height,
                angle: Number(domino.angle.toFixed(3)),
                isNumber: domino.isNumber,
                isAnimal: domino.isAnimal,
                isFalling: domino.isFalling,
                hasFallen: domino.hasFallen
            })),
            building: this.building ? {
                type: this.building.type,
                x: Math.round(this.building.x),
                y: Math.round(this.building.y),
                width: this.building.width,
                height: this.building.height,
                isExploding: this.building.isExploding,
                explosionProgress: Number(this.building.explosionProgress.toFixed(3))
            } : null
        };

        return JSON.stringify(payload);
    }

    /**
     * 自动化测试使用的固定步长推进接口
     */
    advanceTime(ms) {
        const stepMs = 1000 / 60;
        const steps = Math.max(1, Math.round(ms / stepMs));

        for (let i = 0; i < steps; i++) {
            this.updateFrame(stepMs);
        }
        this.draw();
    }

    /**
     * 创建侧边栏的骨牌按钮
     */
    createDominoButtons() {
        // 创建字母按钮 A-Z
        for (let i = 0; i < 26; i++) {
            const letter = String.fromCharCode(65 + i);
            const btn = document.createElement('button');
            btn.className = 'domino-btn';
            btn.textContent = letter;
            btn.addEventListener('click', () => this.selectDomino(letter, false, btn));
            this.letterGrid.appendChild(btn);
        }

        // 创建数字按钮 0-9
        for (let i = 0; i <= 9; i++) {
            const btn = document.createElement('button');
            btn.className = 'domino-btn number';
            btn.textContent = i.toString();
            btn.addEventListener('click', () => this.selectDomino(i.toString(), true, btn));
            this.numberGrid.appendChild(btn);
        }
    }

    /**
     * 创建动物骨牌按钮
     */
    createAnimalButtons() {
        ANIMALS.forEach(animal => {
            const btn = document.createElement('button');
            btn.className = 'domino-btn animal';
            btn.textContent = animal.emoji;
            btn.title = animal.nameCn;
            btn.addEventListener('click', () => this.selectAnimal(animal, btn));
            this.animalGrid.appendChild(btn);
        });
    }

    /**
     * 创建建筑按钮
     */
    createBuildingButtons() {
        Building.TYPES.forEach(building => {
            const btn = document.createElement('button');
            btn.className = 'building-btn';

            // 使用安全的DOM方法创建内容
            const emojiSpan = document.createElement('span');
            emojiSpan.className = 'emoji';
            emojiSpan.textContent = building.emoji;

            const nameSpan = document.createElement('span');
            nameSpan.textContent = building.name;

            btn.appendChild(emojiSpan);
            btn.appendChild(nameSpan);

            btn.addEventListener('click', () => this.selectBuilding(building.id, btn));
            this.buildingGrid.appendChild(btn);
        });
    }

    /**
     * 设置事件监听
     */
    setupEventListeners() {
        // Canvas点击放置骨牌或建筑
        this.canvas.addEventListener('click', (e) => this.onCanvasClick(e));

        // 右键删除骨牌或建筑
        this.canvas.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            this.onCanvasRightClick(e);
        });

        // 重置按钮
        if (this.resetBtn) {
            this.resetBtn.addEventListener('click', () => this.reset());
        }

        // 推倒按钮
        if (this.pushBtn) {
            this.pushBtn.addEventListener('click', () => this.startDominoEffect());
        }

        // 点击庆祝界面关闭
        this.celebration.addEventListener('click', () => {
            this.celebration.hidden = true;
        });

        // 键盘快捷键
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.clearSelection();
            } else if (e.key === ' ' && !this.isAnimating) {
                // 焦点在按钮上时空格会触发按钮点击，避免快捷键重复触发
                if (e.target instanceof HTMLButtonElement) return;
                e.preventDefault();
                this.startDominoEffect();
            } else if (e.key === 'r' || e.key === 'R') {
                this.reset();
            }
        });
    }

    /**
     * 选择要放置的骨牌
     */
    selectDomino(character, isNumber, btnElement) {
        // 清除之前的选中状态
        this.clearAllSelections();

        // 设置新选中
        this.selectedCharacter = character;
        this.selectedIsNumber = isNumber;
        this.selectedIsAnimal = false;
        this.selectedAnimalData = null;
        this.selectedBuilding = null;
        btnElement.classList.add('selected');

        // 播放点击音效
        this.audio.playSound('click');

        // 朗读选中的字符
        if (isNumber) {
            this.audio.speakNumber(character);
        } else {
            this.audio.speakLetter(character);
        }
    }

    /**
     * 选择动物骨牌
     */
    selectAnimal(animalData, btnElement) {
        // 清除之前的选中状态
        this.clearAllSelections();

        // 设置新选中
        this.selectedCharacter = animalData.emoji;
        this.selectedIsNumber = false;
        this.selectedIsAnimal = true;
        this.selectedAnimalData = animalData;
        this.selectedBuilding = null;
        btnElement.classList.add('selected');

        // 播放点击音效
        this.audio.playSound('click');

        // 朗读动物英文名
        this.audio.speakAnimal(animalData);
    }

    /**
     * 选择建筑
     */
    selectBuilding(buildingType, btnElement) {
        // 清除之前的选中状态
        this.clearAllSelections();

        // 设置新选中
        this.selectedBuilding = buildingType;
        this.selectedCharacter = null;
        btnElement.classList.add('selected');

        // 播放点击音效
        this.audio.playSound('click');
    }

    /**
     * 清除所有选择
     */
    clearAllSelections() {
        document.querySelectorAll('.domino-btn, .building-btn').forEach(btn => {
            btn.classList.remove('selected');
        });
    }

    /**
     * 清除选择
     */
    clearSelection() {
        this.selectedCharacter = null;
        this.selectedBuilding = null;
        this.selectedIsAnimal = false;
        this.selectedAnimalData = null;
        this.clearAllSelections();

        if (document.activeElement instanceof HTMLElement) {
            document.activeElement.blur();
        }
    }

    /**
     * Canvas点击事件处理
     */
    onCanvasClick(e) {
        if (this.isAnimating) return;

        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;

        // 检查是否点击了小球
        if (this.isClickOnBall(x, y)) {
            this.startDominoEffect();
            return;
        }

        if (this.selectedBuilding !== null) {
            // 放置建筑
            this.placeBuilding();
        } else if (this.selectedCharacter !== null) {
            // 放置新骨牌
            this.placeDomino();
        }
    }

    /**
     * 检查是否点击了小球
     */
    isClickOnBall(x, y) {
        const dx = x - this.ball.x;
        const dy = y - this.ball.y;
        const distance = Math.sqrt(dx * dx + dy * dy);
        return distance <= this.ball.radius;
    }

    /**
     * Canvas右键点击（删除骨牌或建筑）
     */
    onCanvasRightClick(e) {
        if (this.isAnimating) return;

        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;

        // 检查是否点击了建筑
        if (this.building) {
            const bLeft = this.building.x - this.building.width / 2;
            const bRight = this.building.x + this.building.width / 2;
            const bTop = this.building.y - this.building.height;
            const bBottom = this.building.y;

            if (x >= bLeft && x <= bRight && y >= bTop && y <= bBottom) {
                this.building = null;
                this.draw();
                return;
            }
        }

        // 找到并删除点击位置的骨牌
        for (let i = this.dominoes.length - 1; i >= 0; i--) {
            if (this.dominoes[i].containsPoint(x, y)) {
                this.dominoes.splice(i, 1);
                this.invalidateTrackCache();
                this.draw();
                break;
            }
        }
    }

    /**
     * 放置骨牌（位置自动排列：底部贴地、从左到右依次排开，与点击坐标无关）
     */
    placeDomino() {
        // 根据已放置骨牌数量计算递增尺寸
        const count = this.dominoes.length;
        const growthFactor = 1 + count * 0.08;  // 每个骨牌增大8%

        const customDimensions = {
            width: Math.round(DOMINO_BASE_DIMENSIONS.width * growthFactor),
            height: Math.round(DOMINO_BASE_DIMENSIONS.height * growthFactor)
        };

        // 骨牌底部自动对齐到画布底部
        const y = this.canvasHeight - 80;

        // 水平位置：根据已有骨牌动态计算，保持合适间距
        const startX = 80;
        const baseSpacing = 15;  // 骨牌之间的基础间隙

        let x;
        if (count === 0) {
            x = startX;
        } else {
            // 计算前面所有骨牌占用的宽度
            let totalWidth = startX;
            for (let i = 0; i < count; i++) {
                totalWidth += this.dominoes[i].width + baseSpacing;
            }
            x = totalWidth + customDimensions.width / 2;
        }

        const domino = new Domino(
            x,
            y,
            this.selectedCharacter,
            this.selectedIsNumber,
            customDimensions,
            this.selectedIsAnimal,
            this.selectedAnimalData
        );

        this.dominoes.push(domino);
        this.invalidateTrackCache();
        this.audio.playSound('click');
        this.draw();
    }

    /**
     * 放置建筑（自动放在最后一个骨牌右边，与点击坐标无关）
     */
    placeBuilding() {
        const y = this.canvasHeight - 80;
        let x;

        if (this.dominoes.length > 0) {
            const lastDomino = this.dominoes[this.dominoes.length - 1];
            x = lastDomino.x + lastDomino.width / 2 + 60;
        } else {
            x = this.canvasWidth - 150;
        }

        this.building = new Building(x, y, this.selectedBuilding);
        this.audio.playSound('click');
        this.draw();
    }

    /**
     * 开始多米诺效应
     */
    startDominoEffect() {
        if (this.isAnimating || this.dominoes.length === 0) return;

        this.isAnimating = true;
        this.celebration.hidden = true;

        // 按位置排序骨牌
        this.dominoes.sort((a, b) => a.x - b.x);
        this.invalidateTrackCache();

        // 先让小球开始移动
        this.ball.isMoving = true;
        this.ball.progress = 0;

        // 设置物理引擎（但还不启动）
        this.physics.setDominoes(this.dominoes);
    }

    /**
     * 安排可在重置时统一取消的定时任务
     */
    scheduleTimer(callback, delay) {
        const runId = this.gameRunId;
        const timerId = setTimeout(() => {
            this.pendingTimers.delete(timerId);
            if (runId !== this.gameRunId) return;
            callback();
        }, delay);

        this.pendingTimers.add(timerId);
        return timerId;
    }

    /**
     * 清理所有未执行的定时任务，并让旧回调失效
     */
    clearScheduledTimers() {
        this.gameRunId += 1;
        this.pendingTimers.forEach((timerId) => clearTimeout(timerId));
        this.pendingTimers.clear();
    }

    /**
     * 骨牌倒下时的回调
     */
    onDominoFall(domino, index) {
        // 播放倒下音效
        this.audio.playSound('fall');

        // 延迟朗读字符
        this.scheduleTimer(() => {
            this.audio.speakDomino(domino);
        }, 100);

        // 检查是否是最后一个骨牌
        if (index === this.dominoes.length - 1) {
            // 触发屏幕晃动效果
            this.triggerScreenShake();

            // 如果有建筑，延迟触发建筑爆炸
            if (this.building) {
                this.scheduleTimer(() => {
                    this.triggerBuildingExplosion();
                }, 500);
            }
        }
    }

    /**
     * 触发屏幕晃动效果
     */
    triggerScreenShake() {
        const container = this.canvas.parentElement;
        container.classList.add('screen-shake');

        // 动画结束后移除类
        this.scheduleTimer(() => {
            container.classList.remove('screen-shake');
        }, 600);
    }

    /**
     * 触发建筑爆炸（幂等：埃菲尔铁塔不爆炸也只触发一次，避免每帧重复播音效）
     */
    triggerBuildingExplosion() {
        if (this.building && !this.building.explosionTriggered) {
            this.building.startExplosion();
            if (this.building.isExploding) {
                this.audio.playSound('celebrate');
            }
        }
    }

    /**
     * 所有骨牌倒下后的回调
     */
    onAllFallen() {
        // 如果有建筑且正在爆炸，等爆炸结束
        if (this.building && this.building.isExploding) {
            // 等待爆炸动画
            const runId = this.gameRunId;
            const checkExplosion = () => {
                if (runId !== this.gameRunId || !this.building) return;

                if (this.building.isExplosionComplete()) {
                    this.showCelebration();
                } else {
                    requestAnimationFrame(checkExplosion);
                }
            };
            checkExplosion();
        } else if (this.building) {
            // 触发爆炸
            this.triggerBuildingExplosion();
            this.scheduleTimer(() => this.showCelebration(), 1500);
        } else {
            this.showCelebration();
        }
    }

    /**
     * 显示庆祝界面
     */
    showCelebration() {
        this.isAnimating = false;

        this.scheduleTimer(() => {
            this.celebration.hidden = false;
            this.audio.playSound('celebrate');

            this.scheduleTimer(() => {
                this.audio.speakCelebration();
            }, 500);

            // 3秒后自动重置游戏
            this.scheduleTimer(() => {
                this.reset();
            }, 3000);
        }, 300);
    }

    /**
     * 重置游戏
     */
    reset() {
        this.clearScheduledTimers();
        this.isAnimating = false;
        this.physics.reset();
        this.dominoes = [];
        this.building = null;
        this.invalidateTrackCache();
        this.clearSelection();
        this.celebration.hidden = true;
        this.canvas.parentElement.classList.remove('screen-shake');
        this.audio.clear();
        this.resetBall();
        this.draw();
    }

    /**
     * 游戏主循环
     */
    gameLoop(currentTime = performance.now()) {
        const deltaTime = Math.min(1000 / 30, Math.max(0, currentTime - this.lastFrameTime));
        this.lastFrameTime = currentTime;

        this.updateFrame(deltaTime || 1000 / 60);
        this.draw();

        // 继续循环
        requestAnimationFrame((time) => this.gameLoop(time));
    }

    /**
     * 推进一帧游戏状态
     */
    updateFrame(deltaTime = 1000 / 60) {
        // 更新小球
        if (this.ball.isMoving) {
            const ballReached = this.updateBall(deltaTime);
            if (ballReached) {
                // 小球到达第一个骨牌，开始推倒
                this.physics.start();
                this.audio.playSound('fall');
            }
        }

        // 更新物理
        if (this.isAnimating) {
            this.physics.update(deltaTime);

            // 检查最后一个骨牌是否碰到建筑
            if (this.building && this.dominoes.length > 0) {
                const lastDomino = this.dominoes[this.dominoes.length - 1];
                if (lastDomino.hasFallen && this.building.checkCollision(lastDomino)) {
                    this.triggerBuildingExplosion();
                }
            }
        }

        // 推进建筑爆炸动画（状态更新与绘制解耦）
        if (this.building) {
            this.building.update(deltaTime);
        }
    }

    /**
     * 绘制游戏画面
     */
    draw() {
        // 清空画布
        this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

        // 绘制背景网格
        this.drawGrid();

        // 绘制地面线
        this.drawGround();

        // 绘制所有骨牌
        this.dominoes.forEach(domino => {
            domino.draw(this.ctx);
        });

        // 绘制建筑
        if (this.building) {
            this.building.draw(this.ctx);
        }

        // 绘制小球轨道和小球
        this.drawBallTrack();
        this.drawBall();

        // 如果有选中的骨牌或建筑，显示预览
        if ((this.selectedCharacter !== null || this.selectedBuilding !== null) && !this.isAnimating) {
            this.drawPreviewHint();
        }
    }

    /**
     * 绘制背景网格
     */
    drawGrid() {
        this.ctx.strokeStyle = 'rgba(255, 255, 255, 0.08)';
        this.ctx.lineWidth = 1;

        const gridSize = 50;

        // 所有网格线合并为一条路径，一次 stroke
        this.ctx.beginPath();
        for (let x = 0; x < this.canvasWidth; x += gridSize) {
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, this.canvasHeight);
        }
        for (let y = 0; y < this.canvasHeight; y += gridSize) {
            this.ctx.moveTo(0, y);
            this.ctx.lineTo(this.canvasWidth, y);
        }
        this.ctx.stroke();
    }

    /**
     * 绘制地面
     */
    drawGround() {
        const groundY = this.canvasHeight - 80;

        this.ctx.strokeStyle = '#c9a227';
        this.ctx.lineWidth = 3;
        this.ctx.setLineDash([10, 5]);
        this.ctx.beginPath();
        this.ctx.moveTo(0, groundY);
        this.ctx.lineTo(this.canvasWidth, groundY);
        this.ctx.stroke();
        this.ctx.setLineDash([]);
    }

    /**
     * 绘制放置提示
     */
    drawPreviewHint() {
        this.ctx.fillStyle = 'rgba(125, 211, 252, 0.8)';
        this.ctx.font = 'bold 16px Comic Sans MS';
        this.ctx.textAlign = 'center';

        let hint = '';
        if (this.selectedCharacter !== null) {
            hint = '点击放置骨牌 "' + this.selectedCharacter + '"';
        } else if (this.selectedBuilding !== null) {
            const buildingInfo = Building.TYPES.find(b => b.id === this.selectedBuilding);
            const buildingName = buildingInfo ? buildingInfo.name : this.selectedBuilding;
            hint = '点击放置建筑 "' + buildingName + '"';
        }

        this.ctx.fillText(hint, this.canvasWidth / 2, 30);
    }

    /**
     * 绘制小球
     */
    drawBall() {
        this.ctx.save();

        // 绘制发光效果
        const gradient = this.ctx.createRadialGradient(
            this.ball.x, this.ball.y, 0,
            this.ball.x, this.ball.y, this.ball.radius * 1.5
        );
        gradient.addColorStop(0, 'rgba(255, 200, 100, 0.3)');
        gradient.addColorStop(1, 'rgba(255, 200, 100, 0)');
        this.ctx.fillStyle = gradient;
        this.ctx.beginPath();
        this.ctx.arc(this.ball.x, this.ball.y, this.ball.radius * 1.5, 0, Math.PI * 2);
        this.ctx.fill();

        // 绘制金色小球
        const ballGradient = this.ctx.createRadialGradient(
            this.ball.x - 5, this.ball.y - 5, 0,
            this.ball.x, this.ball.y, this.ball.radius
        );
        ballGradient.addColorStop(0, '#ffd700');
        ballGradient.addColorStop(0.5, '#daa520');
        ballGradient.addColorStop(1, '#b8860b');

        this.ctx.beginPath();
        this.ctx.arc(this.ball.x, this.ball.y, this.ball.radius, 0, Math.PI * 2);
        this.ctx.fillStyle = ballGradient;
        this.ctx.fill();

        // 添加高光效果
        this.ctx.beginPath();
        this.ctx.arc(this.ball.x - 6, this.ball.y - 6, this.ball.radius * 0.35, 0, Math.PI * 2);
        this.ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
        this.ctx.fill();

        this.ctx.restore();
    }

    /**
     * 绘制小球轨道 - 过山车螺旋下降样式
     */
    drawBallTrack() {
        // 获取轨道路径点
        const trackPoints = this.getTrackPoints();
        if (trackPoints.length === 0) return;

        // 同一条折线要按三种样式描边，构建一次 Path2D 复用
        const trackPath = new Path2D();
        trackPath.moveTo(trackPoints[0].x, trackPoints[0].y);
        for (let i = 1; i < trackPoints.length; i++) {
            trackPath.lineTo(trackPoints[i].x, trackPoints[i].y);
        }

        this.ctx.save();
        this.ctx.lineCap = 'round';
        this.ctx.lineJoin = 'round';

        // 绘制轨道主线
        this.ctx.strokeStyle = 'rgba(255, 200, 100, 0.3)';
        this.ctx.lineWidth = 6;
        this.ctx.stroke(trackPath);

        // 绘制轨道边框（模拟过山车轨道）
        this.ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)';
        this.ctx.lineWidth = 10;
        this.ctx.stroke(trackPath);

        // 重新绘制中心线
        this.ctx.strokeStyle = '#daa520';
        this.ctx.lineWidth = 4;
        this.ctx.stroke(trackPath);

        // 绘制轨道支撑点
        this.ctx.fillStyle = '#b8860b';
        for (let i = 0; i < trackPoints.length; i += 10) {
            this.ctx.beginPath();
            this.ctx.arc(trackPoints[i].x, trackPoints[i].y, 3, 0, Math.PI * 2);
            this.ctx.fill();
        }

        this.ctx.restore();
    }

    /**
     * 使轨道点缓存失效（骨牌增删、排序或画布尺寸变化时调用）
     */
    invalidateTrackCache() {
        this.trackPointsCache = null;
    }

    /**
     * 生成之字形轨道路径点 - 左右来回倾斜下降（结果缓存，避免每帧重算）
     */
    getTrackPoints() {
        if (this.dominoes.length === 0) return [];
        if (this.trackPointsCache) return this.trackPointsCache;

        const points = [];
        const startX = 50;
        const startY = 50;
        const groundY = this.canvasHeight - 80;
        const firstDomino = this.dominoes[0];
        const endX = firstDomino.x;
        const endY = groundY - 10;

        // 屏幕边界
        const leftBound = 30;
        const rightBound = this.canvasWidth - 30;

        // 之字形参数：2次弯折
        const zigzags = 2;
        const totalSegments = zigzags * 2;  // 每次来回有2段
        const segmentHeight = (endY - startY) / (totalSegments + 0.5);  // 留一点给最后到骨牌的路径

        // 生成之字形路径的关键点
        const keyPoints = [{ x: startX, y: startY }];

        for (let i = 0; i < zigzags; i++) {
            // 向右倾斜到右边界
            keyPoints.push({
                x: rightBound,
                y: startY + segmentHeight * (i * 2 + 1)
            });
            // 向左倾斜到左边界
            keyPoints.push({
                x: leftBound,
                y: startY + segmentHeight * (i * 2 + 2)
            });
        }

        // 最后一段：从左边界到第一个骨牌
        keyPoints.push({ x: endX, y: endY });

        // 在关键点之间插值生成平滑路径
        const pointsPerSegment = 30;
        for (let seg = 0; seg < keyPoints.length - 1; seg++) {
            const p1 = keyPoints[seg];
            const p2 = keyPoints[seg + 1];

            for (let i = 0; i < pointsPerSegment; i++) {
                const t = i / pointsPerSegment;
                points.push({
                    x: p1.x + (p2.x - p1.x) * t,
                    y: p1.y + (p2.y - p1.y) * t
                });
            }
        }
        // 添加最后一个点
        points.push(keyPoints[keyPoints.length - 1]);

        this.trackPointsCache = points;
        return points;
    }

    /**
     * 更新小球位置 - 沿过山车轨道移动
     */
    updateBall(deltaTime = 1000 / 60) {
        if (!this.ball.isMoving || this.dominoes.length === 0) return false;

        const trackPoints = this.getTrackPoints();
        if (trackPoints.length === 0) return false;

        this.ball.progress += 0.002 * (deltaTime / (1000 / 60));  // 速度再减慢2倍

        if (this.ball.progress >= 1) {
            this.ball.progress = 1;
            this.ball.isMoving = false;
            // 设置小球到终点位置
            const lastPoint = trackPoints[trackPoints.length - 1];
            this.ball.x = lastPoint.x;
            this.ball.y = lastPoint.y;
            return true;  // 小球到达终点
        }

        // 根据进度获取轨道上的位置
        const index = Math.floor(this.ball.progress * (trackPoints.length - 1));
        const nextIndex = Math.min(index + 1, trackPoints.length - 1);
        const localT = (this.ball.progress * (trackPoints.length - 1)) - index;

        // 线性插值
        this.ball.x = trackPoints[index].x + (trackPoints[nextIndex].x - trackPoints[index].x) * localT;
        this.ball.y = trackPoints[index].y + (trackPoints[nextIndex].y - trackPoints[index].y) * localT;

        return false;
    }

    /**
     * 重置小球位置
     */
    resetBall() {
        this.ball.x = 50;
        this.ball.y = 50;
        this.ball.radius = 30;
        this.ball.isMoving = false;
        this.ball.progress = 0;
    }
}

// 页面加载后初始化游戏
document.addEventListener('DOMContentLoaded', () => {
    window.game = new DominoGame();
});
