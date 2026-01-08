/**
 * 多米诺骨牌游戏 - 主程序
 */
class DominoGame {
    constructor() {
        // 获取DOM元素
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.letterGrid = document.getElementById('letterGrid');
        this.numberGrid = document.getElementById('numberGrid');
        this.buildingGrid = document.getElementById('buildingGrid');
        this.resetBtn = document.getElementById('resetBtn');
        this.pushBtn = document.getElementById('pushBtn');
        this.celebration = document.getElementById('celebration');

        // 游戏状态
        this.dominoes = [];
        this.building = null;  // 当前放置的建筑
        this.selectedCharacter = null;
        this.selectedIsNumber = false;
        this.selectedBuilding = null;  // 选中的建筑类型
        this.currentSize = 'medium';
        this.isAnimating = false;

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
        this.createBuildingButtons();
        this.setupEventListeners();
        this.gameLoop();
    }

    /**
     * 设置Canvas尺寸
     */
    setupCanvas() {
        const container = this.canvas.parentElement;
        const resize = () => {
            this.canvas.width = container.clientWidth;
            this.canvas.height = container.clientHeight;
            this.draw();
        };

        resize();
        window.addEventListener('resize', resize);
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
        this.resetBtn.addEventListener('click', () => this.reset());

        // 推倒按钮
        this.pushBtn.addEventListener('click', () => this.startDominoEffect());

        // 大小选择
        document.querySelectorAll('input[name="size"]').forEach(radio => {
            radio.addEventListener('change', (e) => {
                this.currentSize = e.target.value;
            });
        });

        // 点击庆祝界面关闭
        this.celebration.addEventListener('click', () => {
            this.celebration.hidden = true;
        });

        // 键盘快捷键
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.clearSelection();
            } else if (e.key === ' ' && !this.isAnimating) {
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
        this.clearAllSelections();
    }

    /**
     * Canvas点击事件处理
     */
    onCanvasClick(e) {
        if (this.isAnimating) return;

        const rect = this.canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;

        if (this.selectedBuilding !== null) {
            // 放置建筑
            this.placeBuilding(x, y);
        } else if (this.selectedCharacter !== null) {
            // 放置新骨牌
            this.placeDomino(x, y);
        }
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
                this.draw();
                break;
            }
        }
    }

    /**
     * 放置骨牌
     */
    placeDomino(x, y) {
        // 基础尺寸配置
        const baseSizes = {
            small: { width: 20, height: 50 },
            medium: { width: 30, height: 75 },
            large: { width: 40, height: 100 }
        };

        // 根据已放置骨牌数量计算递增尺寸
        const count = this.dominoes.length;
        const baseSize = baseSizes[this.currentSize];
        const growthFactor = 1 + count * 0.08;  // 每个骨牌增大8%

        const customDimensions = {
            width: Math.round(baseSize.width * growthFactor),
            height: Math.round(baseSize.height * growthFactor)
        };

        // 骨牌底部自动对齐到画布中间
        y = this.canvas.height / 2;

        // 水平位置：根据已有骨牌动态计算，保持合适间距
        const startX = 80;
        const baseSpacing = 15;  // 骨牌之间的基础间隙

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
            this.currentSize,
            this.selectedIsNumber,
            customDimensions
        );

        this.dominoes.push(domino);
        this.audio.playSound('click');
        this.draw();
    }

    /**
     * 放置建筑
     */
    placeBuilding(x, y) {
        // 建筑放在最后一个骨牌的右边
        y = this.canvas.height / 2;

        if (this.dominoes.length > 0) {
            const lastDomino = this.dominoes[this.dominoes.length - 1];
            x = lastDomino.x + lastDomino.width / 2 + 60;
        } else {
            x = this.canvas.width - 150;
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

        // 设置物理引擎
        this.physics.setDominoes(this.dominoes);
        this.physics.start();
    }

    /**
     * 骨牌倒下时的回调
     */
    onDominoFall(domino, index) {
        // 播放倒下音效
        this.audio.playSound('fall');

        // 延迟朗读字符
        setTimeout(() => {
            this.audio.speakDomino(domino);
        }, 100);

        // 检查最后一个骨牌是否碰到建筑
        if (index === this.dominoes.length - 1 && this.building) {
            // 延迟触发建筑爆炸
            setTimeout(() => {
                this.triggerBuildingExplosion();
            }, 500);
        }
    }

    /**
     * 触发建筑爆炸
     */
    triggerBuildingExplosion() {
        if (this.building && !this.building.isExploding) {
            this.building.startExplosion();
            this.audio.playSound('celebrate');
        }
    }

    /**
     * 所有骨牌倒下后的回调
     */
    onAllFallen() {
        // 如果有建筑且正在爆炸，等爆炸结束
        if (this.building && this.building.isExploding) {
            // 等待爆炸动画
            const checkExplosion = () => {
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
            setTimeout(() => this.showCelebration(), 1500);
        } else {
            this.showCelebration();
        }
    }

    /**
     * 显示庆祝界面
     */
    showCelebration() {
        this.isAnimating = false;

        setTimeout(() => {
            this.celebration.hidden = false;
            this.audio.playSound('celebrate');

            setTimeout(() => {
                this.audio.speakCelebration();
            }, 500);
        }, 300);
    }

    /**
     * 重置游戏
     */
    reset() {
        this.isAnimating = false;
        this.physics.reset();
        this.dominoes = [];
        this.building = null;
        this.celebration.hidden = true;
        this.audio.clear();
        this.draw();
    }

    /**
     * 游戏主循环
     */
    gameLoop() {
        // 更新物理
        if (this.isAnimating) {
            this.physics.update();

            // 检查最后一个骨牌是否碰到建筑
            if (this.building && this.dominoes.length > 0) {
                const lastDomino = this.dominoes[this.dominoes.length - 1];
                if (lastDomino.hasFallen && this.building.checkCollision(lastDomino)) {
                    this.triggerBuildingExplosion();
                }
            }
        }

        // 绘制
        this.draw();

        // 继续循环
        requestAnimationFrame(() => this.gameLoop());
    }

    /**
     * 绘制游戏画面
     */
    draw() {
        // 清空画布
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

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

        // 如果有选中的骨牌或建筑，显示预览
        if ((this.selectedCharacter !== null || this.selectedBuilding !== null) && !this.isAnimating) {
            this.drawPreviewHint();
        }
    }

    /**
     * 绘制背景网格
     */
    drawGrid() {
        this.ctx.strokeStyle = 'rgba(100, 100, 100, 0.1)';
        this.ctx.lineWidth = 1;

        const gridSize = 50;

        for (let x = 0; x < this.canvas.width; x += gridSize) {
            this.ctx.beginPath();
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, this.canvas.height);
            this.ctx.stroke();
        }

        for (let y = 0; y < this.canvas.height; y += gridSize) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, y);
            this.ctx.lineTo(this.canvas.width, y);
            this.ctx.stroke();
        }
    }

    /**
     * 绘制地面
     */
    drawGround() {
        const groundY = this.canvas.height / 2;

        this.ctx.strokeStyle = '#8b4513';
        this.ctx.lineWidth = 3;
        this.ctx.setLineDash([10, 5]);
        this.ctx.beginPath();
        this.ctx.moveTo(0, groundY);
        this.ctx.lineTo(this.canvas.width, groundY);
        this.ctx.stroke();
        this.ctx.setLineDash([]);
    }

    /**
     * 绘制放置提示
     */
    drawPreviewHint() {
        this.ctx.fillStyle = 'rgba(90, 79, 207, 0.5)';
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

        this.ctx.fillText(hint, this.canvas.width / 2, 30);
    }
}

// 页面加载后初始化游戏
document.addEventListener('DOMContentLoaded', () => {
    window.game = new DominoGame();
});
