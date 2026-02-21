/**
 * 多米诺骨牌类
 */
class Domino {
    constructor(x, y, character, size = 'medium', isNumber = false, customDimensions = null, isAnimal = false, animalData = null) {
        this.x = x;
        this.y = y;
        this.character = character;
        this.isNumber = isNumber;
        this.isAnimal = isAnimal;
        this.animalData = animalData;  // { emoji, name, nameCn }

        // 根据大小设置尺寸
        const sizes = {
            small: { width: 20, height: 50 },
            medium: { width: 30, height: 75 },
            large: { width: 40, height: 100 }
        };

        this.size = size;

        // 支持自定义尺寸
        if (customDimensions) {
            this.width = customDimensions.width;
            this.height = customDimensions.height;
        } else {
            this.width = sizes[size].width;
            this.height = sizes[size].height;
        }

        // 物理属性
        this.angle = 0;          // 当前角度（弧度）
        this.angularVelocity = 0;
        this.isFalling = false;
        this.hasFallen = false;
        this.fallDirection = 1;  // 1: 向右倒, -1: 向左倒

        // 颜色配置
        if (isAnimal) {
            this.colors = {
                primary: '#a8e6cf',
                secondary: '#56ab91',
                text: '#2d5a45',
                border: '#3d8b6e'
            };
        } else if (isNumber) {
            this.colors = {
                primary: '#56ccf2',
                secondary: '#2d98da',
                text: '#1a5276',
                border: '#3498db'
            };
        } else {
            this.colors = {
                primary: '#fcb69f',
                secondary: '#e07c4f',
                text: '#8b4513',
                border: '#d35400'
            };
        }
    }

    /**
     * 在Canvas上绘制骨牌
     */
    draw(ctx) {
        ctx.save();

        // 移动到骨牌底部中心点作为旋转中心
        ctx.translate(this.x, this.y);
        ctx.rotate(this.angle);

        // 绘制骨牌主体
        const gradient = ctx.createLinearGradient(-this.width/2, -this.height, this.width/2, 0);
        gradient.addColorStop(0, this.colors.primary);
        gradient.addColorStop(1, this.colors.secondary);

        ctx.fillStyle = gradient;
        ctx.strokeStyle = this.colors.border;
        ctx.lineWidth = 3;

        // 圆角矩形
        this.roundRect(ctx, -this.width/2, -this.height, this.width, this.height, 5);
        ctx.fill();
        ctx.stroke();

        // 绘制装饰线
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.5)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(-this.width/2 + 5, -this.height/2);
        ctx.lineTo(this.width/2 - 5, -this.height/2);
        ctx.stroke();

        // 绘制字符
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillStyle = this.colors.text;
        if (this.isAnimal && this.animalData) {
            // 动物使用更大的 emoji
            ctx.font = `${this.height * 0.5}px Arial`;
            ctx.fillText(this.animalData.emoji, 0, -this.height/2);
        } else {
            ctx.font = `bold ${this.height * 0.4}px Comic Sans MS, cursive`;
            ctx.fillText(this.character, 0, -this.height/2);
        }

        // 添加高光效果
        ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
        this.roundRect(ctx, -this.width/2 + 3, -this.height + 3, this.width - 6, this.height/3, 3);
        ctx.fill();

        ctx.restore();
    }

    /**
     * 绘制圆角矩形
     */
    roundRect(ctx, x, y, width, height, radius) {
        ctx.beginPath();
        ctx.moveTo(x + radius, y);
        ctx.lineTo(x + width - radius, y);
        ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
        ctx.lineTo(x + width, y + height - radius);
        ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
        ctx.lineTo(x + radius, y + height);
        ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
        ctx.lineTo(x, y + radius);
        ctx.quadraticCurveTo(x, y, x + radius, y);
        ctx.closePath();
    }

    /**
     * 开始倒下动画
     */
    startFalling(direction = 1) {
        if (!this.isFalling && !this.hasFallen) {
            this.isFalling = true;
            this.fallDirection = direction;
            this.angularVelocity = 0.02 * direction;
        }
    }

    /**
     * 更新物理状态
     */
    update(deltaTime) {
        if (this.isFalling && !this.hasFallen) {
            // 增加角速度（重力加速效果）
            this.angularVelocity += 0.003 * this.fallDirection;
            this.angle += this.angularVelocity;

            // 检查是否倒下完成（约90度）
            const maxAngle = Math.PI / 2 * 0.95;
            if (Math.abs(this.angle) >= maxAngle) {
                this.angle = maxAngle * this.fallDirection;
                this.isFalling = false;
                this.hasFallen = true;
                this.angularVelocity = 0;
            }
        }
    }

    /**
     * 获取骨牌顶部位置（用于碰撞检测）
     */
    getTopPosition() {
        const topX = this.x + Math.sin(this.angle) * this.height;
        const topY = this.y - Math.cos(this.angle) * this.height;
        return { x: topX, y: topY };
    }

    /**
     * 检查是否碰撞到另一个骨牌
     */
    checkCollision(other) {
        if (this.hasFallen || !this.isFalling) return false;
        if (other.isFalling || other.hasFallen) return false;

        const top = this.getTopPosition();
        const distance = Math.abs(top.x - other.x);
        const threshold = other.width / 2 + 10;

        // 检查是否接触到下一个骨牌
        if (distance < threshold && Math.abs(this.angle) > Math.PI / 6) {
            return true;
        }
        return false;
    }

    /**
     * 检查点是否在骨牌内
     */
    containsPoint(px, py) {
        // 简化检测：使用未旋转的边界框
        const left = this.x - this.width / 2;
        const right = this.x + this.width / 2;
        const top = this.y - this.height;
        const bottom = this.y;

        return px >= left && px <= right && py >= top && py <= bottom;
    }

    /**
     * 重置骨牌状态
     */
    reset() {
        this.angle = 0;
        this.angularVelocity = 0;
        this.isFalling = false;
        this.hasFallen = false;
    }

    /**
     * 创建骨牌副本
     */
    clone() {
        return new Domino(this.x, this.y, this.character, this.size, this.isNumber);
    }
}

// 导出类（用于模块系统）
if (typeof module !== 'undefined' && module.exports) {
    module.exports = Domino;
}
