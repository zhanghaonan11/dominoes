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

        // 检查是否点击了小球
        if (this.isClickOnBall(x, y)) {
            this.startDominoEffect();
            return;
        }

        if (this.selectedBuilding !== null) {
            // 放置建筑
            this.placeBuilding(x, y);
        } else if (this.selectedCharacter !== null) {
            // 放置新骨牌
            this.placeDomino(x, y);
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

        // 骨牌底部自动对齐到画布底部
        y = this.canvas.height - 80;

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
        y = this.canvas.height - 80;

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

        // 先让小球开始移动
        this.ball.isMoving = true;
        this.ball.progress = 0;

        // 设置物理引擎（但还不启动）
        this.physics.setDominoes(this.dominoes);
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

            // 3秒后自动重置游戏
            setTimeout(() => {
                this.reset();
            }, 3000);
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
        this.resetBall();
        this.draw();
    }

    /**
     * 游戏主循环
     */
    gameLoop() {
        // 更新小球
        if (this.ball.isMoving) {
            const ballReached = this.updateBall();
            if (ballReached) {
                // 小球到达第一个骨牌，开始推倒
                this.physics.start();
                this.audio.playSound('fall');
            }
        }

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
        const groundY = this.canvas.height - 80;

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

    /**
     * 绘制小球
     */
    drawBall() {
        this.ctx.save();

        // 绘制黑色实心小球
        this.ctx.beginPath();
        this.ctx.arc(this.ball.x, this.ball.y, this.ball.radius, 0, Math.PI * 2);
        this.ctx.fillStyle = '#000000';
        this.ctx.fill();

        // 添加高光效果
        this.ctx.beginPath();
        this.ctx.arc(this.ball.x - 4, this.ball.y - 4, this.ball.radius * 0.3, 0, Math.PI * 2);
        this.ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
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

        // 绘制轨道
        this.ctx.save();
        this.ctx.strokeStyle = 'rgba(139, 69, 19, 0.6)';
        this.ctx.lineWidth = 6;
        this.ctx.lineCap = 'round';
        this.ctx.lineJoin = 'round';

        // 绘制轨道主线
        this.ctx.beginPath();
        this.ctx.moveTo(trackPoints[0].x, trackPoints[0].y);
        for (let i = 1; i < trackPoints.length; i++) {
            this.ctx.lineTo(trackPoints[i].x, trackPoints[i].y);
        }
        this.ctx.stroke();

        // 绘制轨道边框（模拟过山车轨道）
        this.ctx.strokeStyle = 'rgba(100, 100, 100, 0.4)';
        this.ctx.lineWidth = 10;
        this.ctx.beginPath();
        this.ctx.moveTo(trackPoints[0].x, trackPoints[0].y);
        for (let i = 1; i < trackPoints.length; i++) {
            this.ctx.lineTo(trackPoints[i].x, trackPoints[i].y);
        }
        this.ctx.stroke();

        // 重新绘制中心线
        this.ctx.strokeStyle = '#8B4513';
        this.ctx.lineWidth = 4;
        this.ctx.beginPath();
        this.ctx.moveTo(trackPoints[0].x, trackPoints[0].y);
        for (let i = 1; i < trackPoints.length; i++) {
            this.ctx.lineTo(trackPoints[i].x, trackPoints[i].y);
        }
        this.ctx.stroke();

        // 绘制轨道支撑点
        this.ctx.fillStyle = '#654321';
        for (let i = 0; i < trackPoints.length; i += 10) {
            this.ctx.beginPath();
            this.ctx.arc(trackPoints[i].x, trackPoints[i].y, 3, 0, Math.PI * 2);
            this.ctx.fill();
        }

        this.ctx.restore();
    }

    /**
     * 生成之字形轨道路径点 - 左右来回倾斜下降
     */
    getTrackPoints() {
        if (this.dominoes.length === 0) return [];

        const points = [];
        const startX = 50;
        const startY = 50;
        const groundY = this.canvas.height - 80;
        const firstDomino = this.dominoes[0];
        const endX = firstDomino.x;
        const endY = groundY - 10;

        // 屏幕边界
        const leftBound = 30;
        const rightBound = this.canvas.width - 30;

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

        return points;
    }

    /**
     * 更新小球位置 - 沿过山车轨道移动
     */
    updateBall() {
        if (!this.ball.isMoving || this.dominoes.length === 0) return false;

        const trackPoints = this.getTrackPoints();
        if (trackPoints.length === 0) return false;

        this.ball.progress += 0.002;  // 速度再减慢2倍

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
