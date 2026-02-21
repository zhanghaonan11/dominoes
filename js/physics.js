/**
 * 物理引擎 - 处理多米诺骨牌的连锁倒下效果
 */
class PhysicsEngine {
    constructor() {
        this.dominoes = [];
        this.isRunning = false;
        this.lastTime = 0;
        this.onDominoFall = null;  // 回调函数：骨牌倒下时触发
        this.onComplete = null;    // 回调函数：所有骨牌倒下后触发
    }

    /**
     * 设置骨牌数组
     */
    setDominoes(dominoes) {
        this.dominoes = dominoes;
    }

    /**
     * 开始物理模拟
     */
    start() {
        if (this.dominoes.length === 0) return;

        this.isRunning = true;
        this.lastTime = performance.now();

        // 推倒第一个骨牌
        const firstDomino = this.dominoes[0];
        if (firstDomino) {
            firstDomino.startFalling(1);
            if (this.onDominoFall) {
                this.onDominoFall(firstDomino, 0);
            }
        }
    }

    /**
     * 停止物理模拟
     */
    stop() {
        this.isRunning = false;
    }

    /**
     * 重置所有骨牌
     */
    reset() {
        this.isRunning = false;
        this.dominoes.forEach(domino => domino.reset());
    }

    /**
     * 更新物理状态
     */
    update() {
        if (!this.isRunning) return;

        const currentTime = performance.now();
        const deltaTime = currentTime - this.lastTime;
        this.lastTime = currentTime;

        let allFallen = true;
        let anyFalling = false;

        // 更新每个骨牌的状态
        for (let i = 0; i < this.dominoes.length; i++) {
            const domino = this.dominoes[i];
            domino.update(deltaTime);

            if (!domino.hasFallen) {
                allFallen = false;
            }

            if (domino.isFalling) {
                anyFalling = true;

                // 检查是否碰撞到下一个骨牌
                if (i < this.dominoes.length - 1) {
                    const nextDomino = this.dominoes[i + 1];
                    if (domino.checkCollision(nextDomino)) {
                        // 确定倒下方向
                        const direction = nextDomino.x > domino.x ? 1 : -1;
                        nextDomino.startFalling(direction);

                        if (this.onDominoFall) {
                            this.onDominoFall(nextDomino, i + 1);
                        }
                    }
                }
            }
        }

        // 检查是否全部倒下
        if (allFallen && !anyFalling && this.dominoes.length > 0) {
            this.isRunning = false;
            if (this.onComplete) {
                this.onComplete();
            }
        }
    }

    /**
     * 按位置排序骨牌（从左到右）
     */
    sortDominoesByPosition() {
        this.dominoes.sort((a, b) => a.x - b.x);
    }

    /**
     * 计算两个骨牌之间是否能产生连锁反应
     */
    canChainReaction(domino1, domino2) {
        const distance = Math.abs(domino2.x - domino1.x);
        const maxReach = domino1.height * 0.9;  // 骨牌倒下能触及的最大距离
        return distance < maxReach;
    }

    /**
     * 验证骨牌排列是否能产生完整的多米诺效应
     */
    validateChain() {
        if (this.dominoes.length < 2) return true;

        this.sortDominoesByPosition();

        for (let i = 0; i < this.dominoes.length - 1; i++) {
            if (!this.canChainReaction(this.dominoes[i], this.dominoes[i + 1])) {
                return false;
            }
        }
        return true;
    }

    /**
     * 获取断链位置
     */
    getBreakPoints() {
        const breakPoints = [];
        if (this.dominoes.length < 2) return breakPoints;

        this.sortDominoesByPosition();

        for (let i = 0; i < this.dominoes.length - 1; i++) {
            if (!this.canChainReaction(this.dominoes[i], this.dominoes[i + 1])) {
                breakPoints.push({
                    index: i,
                    domino1: this.dominoes[i],
                    domino2: this.dominoes[i + 1],
                    distance: Math.abs(this.dominoes[i + 1].x - this.dominoes[i].x)
                });
            }
        }
        return breakPoints;
    }
}

// 导出类
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PhysicsEngine;
}
