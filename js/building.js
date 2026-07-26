/**
 * 建筑类 - 知名建筑物
 */

// 建筑配置（唯一数据源，按钮列表和实例都从这里取）
const BUILDING_SCALE = 1.5;
const BUILDING_CONFIGS = {
    pisa: { name: '比萨斜塔', emoji: '🗼', width: 60, height: 120, color: '#f5deb3' },
    eiffel: { name: '埃菲尔铁塔', emoji: '🗼', width: 70, height: 140, color: '#4a4a4a' },
    liberty: { name: '自由女神', emoji: '🗽', width: 60, height: 130, color: '#90EE90' },
    bigben: { name: '大本钟', emoji: '🕰️', width: 50, height: 120, color: '#8B4513' },
    pyramid: { name: '金字塔', emoji: '🔺', width: 100, height: 80, color: '#DAA520' },
    taj: { name: '泰姬陵', emoji: '🕌', width: 80, height: 100, color: '#FFFAFA' },
    colosseum: { name: '罗马斗兽场', emoji: '🏟️', width: 90, height: 70, color: '#D2B48C' },
    greatwall: { name: '长城', emoji: '🏯', width: 100, height: 60, color: '#808080' },
    sydney: { name: '悉尼歌剧院', emoji: '🎭', width: 90, height: 70, color: '#F5F5F5' },
    christ: { name: '救世基督像', emoji: '✝️', width: 70, height: 110, color: '#E8E8E8' }
};

class Building {
    constructor(x, y, type) {
        this.x = x;
        this.y = y;
        this.type = type;

        const config = BUILDING_CONFIGS[type] || BUILDING_CONFIGS.pisa;
        this.name = config.name;
        this.emoji = config.emoji;
        this.width = config.width * BUILDING_SCALE;
        this.height = config.height * BUILDING_SCALE;
        this.color = config.color;

        // 状态
        this.explosionTriggered = false;  // 已请求过爆炸（含埃菲尔这种不爆炸的情况）
        this.isExploding = false;
        this.explosionProgress = 0;
        this.particles = [];
        this.canvasWidth = 0;
        this.canvasHeight = 0;
    }

    /**
     * 绘制建筑
     */
    draw(ctx) {
        // 保存画布尺寸用于全屏爆炸
        this.canvasWidth = ctx.canvas.clientWidth || ctx.canvas.width;
        this.canvasHeight = ctx.canvas.clientHeight || ctx.canvas.height;

        if (this.isExploding) {
            this.drawExplosion(ctx);
            return;
        }

        ctx.save();
        ctx.translate(this.x, this.y);

        // 绘制建筑主体
        const gradient = ctx.createLinearGradient(0, -this.height, 0, 0);
        gradient.addColorStop(0, this.lightenColor(this.color, 30));
        gradient.addColorStop(1, this.color);

        ctx.fillStyle = gradient;
        ctx.strokeStyle = this.darkenColor(this.color, 30);
        ctx.lineWidth = 3;

        // 根据建筑类型绘制不同形状
        this.drawBuildingShape(ctx);

        // 绘制建筑名称
        ctx.fillStyle = '#333';
        ctx.font = 'bold 14px Comic Sans MS';
        ctx.textAlign = 'center';
        ctx.fillText(this.name, 0, 20);

        // 绘制emoji图标
        ctx.font = `${this.height * 0.5}px Arial`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(this.emoji, 0, -this.height / 2);

        ctx.restore();
    }

    /**
     * 绘制建筑形状
     */
    drawBuildingShape(ctx) {
        const w = this.width;
        const h = this.height;

        ctx.beginPath();

        switch (this.type) {
            case 'pyramid':
                // 三角形
                ctx.moveTo(0, -h);
                ctx.lineTo(w / 2, 0);
                ctx.lineTo(-w / 2, 0);
                ctx.closePath();
                break;

            case 'colosseum':
            case 'sydney':
                // 椭圆形底部
                ctx.ellipse(0, -h / 2, w / 2, h / 2, 0, 0, Math.PI * 2);
                break;

            default:
                // 矩形建筑
                ctx.roundRect(-w / 2, -h, w, h, 8);
                break;
        }

        ctx.fill();
        ctx.stroke();
    }

    /**
     * 开始爆炸效果 - 全屏效果
     */
    startExplosion() {
        if (this.explosionTriggered) return;
        this.explosionTriggered = true;

        // 埃菲尔铁塔不发生爆炸
        if (this.type === 'eiffel') return;

        this.isExploding = true;
        this.explosionProgress = 0;

        // 生成全屏爆炸粒子 - 大幅增加数量
        const particleCount = 150;
        const colors = ['#FF6B6B', '#FFE66D', '#4ECDC4', '#FF8C42', '#A8E6CF', '#FFD93D', '#FF69B4', '#00CED1', '#FF4500', '#7B68EE'];

        // 从建筑位置向全屏发射粒子
        for (let i = 0; i < particleCount; i++) {
            const angle = (Math.PI * 2 / particleCount) * i + Math.random() * 0.5;
            const speed = 8 + Math.random() * 15;  // 更快的速度覆盖全屏
            const size = 15 + Math.random() * 35;  // 更大的粒子

            this.particles.push({
                x: this.x,
                y: this.y - this.height / 2,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed - 5,
                size: size,
                color: colors[Math.floor(Math.random() * colors.length)],
                rotation: Math.random() * Math.PI * 2,
                rotationSpeed: (Math.random() - 0.5) * 0.4,
                life: 1,
                decay: 0.008 + Math.random() * 0.005,  // 更慢的消失速度
                shape: Math.random() > 0.3 ? 'star' : 'circle'
            });
        }

        // 添加大型彩带粒子
        for (let i = 0; i < 50; i++) {
            const angle = Math.random() * Math.PI * 2;
            const speed = 5 + Math.random() * 10;

            this.particles.push({
                x: this.x,
                y: this.y - this.height / 2,
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed - 8,
                size: 20 + Math.random() * 30,
                color: colors[Math.floor(Math.random() * colors.length)],
                rotation: Math.random() * Math.PI * 2,
                rotationSpeed: (Math.random() - 0.5) * 0.2,
                life: 1,
                decay: 0.006,
                shape: 'ribbon'
            });
        }
    }

    /**
     * 推进爆炸动画状态（与绘制解耦，按真实耗时缩放）
     */
    update(deltaTime = 1000 / 60) {
        if (!this.isExploding) return;

        const frames = deltaTime / (1000 / 60);

        this.particles = this.particles.filter(p => {
            p.x += p.vx * frames;
            p.y += p.vy * frames;
            p.vy += 0.15 * frames; // 较轻的重力
            p.rotation += p.rotationSpeed * frames;
            p.life -= p.decay * frames;
            return p.life > 0;
        });

        this.explosionProgress += 0.015 * frames;
    }

    /**
     * 绘制爆炸效果 - 全屏
     */
    drawExplosion(ctx) {
        ctx.save();

        // 全屏闪光背景
        if (this.explosionProgress < 0.2) {
            const alpha = (1 - this.explosionProgress / 0.2) * 0.6;
            ctx.fillStyle = 'rgba(255, 255, 200, ' + alpha + ')';
            ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);
        }

        // 绘制粒子（使用绝对坐标）
        this.particles.forEach(p => {
            ctx.save();
            ctx.translate(p.x, p.y);
            ctx.rotate(p.rotation);
            ctx.globalAlpha = p.life;
            ctx.fillStyle = p.color;

            if (p.shape === 'circle') {
                ctx.beginPath();
                ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2);
                ctx.fill();
            } else if (p.shape === 'ribbon') {
                // 彩带形状
                ctx.fillRect(-p.size / 2, -p.size / 8, p.size, p.size / 4);
            } else {
                this.drawStar(ctx, 0, 0, 5, p.size / 2, p.size / 4);
            }

            ctx.restore();
        });

        // 绘制多个中心闪光点
        if (this.explosionProgress < 0.4) {
            const flashProgress = this.explosionProgress / 0.4;
            const flashSize = (1 - flashProgress) * 300;

            // 主闪光
            const gradient = ctx.createRadialGradient(this.x, this.y - this.height / 2, 0, this.x, this.y - this.height / 2, flashSize);
            gradient.addColorStop(0, 'rgba(255, 255, 255, ' + (0.9 * (1 - flashProgress)) + ')');
            gradient.addColorStop(0.3, 'rgba(255, 220, 100, ' + (0.7 * (1 - flashProgress)) + ')');
            gradient.addColorStop(0.6, 'rgba(255, 100, 50, ' + (0.4 * (1 - flashProgress)) + ')');
            gradient.addColorStop(1, 'rgba(255, 50, 50, 0)');

            ctx.fillStyle = gradient;
            ctx.beginPath();
            ctx.arc(this.x, this.y - this.height / 2, flashSize, 0, Math.PI * 2);
            ctx.fill();

            // 额外的彩色光环
            const ringColors = ['#FF6B6B', '#4ECDC4', '#FFE66D'];
            ringColors.forEach((color, i) => {
                const ringSize = flashSize * (0.5 + i * 0.3);
                ctx.strokeStyle = color;
                ctx.lineWidth = 8 * (1 - flashProgress);
                ctx.globalAlpha = 0.6 * (1 - flashProgress);
                ctx.beginPath();
                ctx.arc(this.x, this.y - this.height / 2, ringSize, 0, Math.PI * 2);
                ctx.stroke();
            });
        }

        ctx.restore();
    }

    /**
     * 绘制星形
     */
    drawStar(ctx, cx, cy, spikes, outerRadius, innerRadius) {
        let rot = Math.PI / 2 * 3;
        let step = Math.PI / spikes;

        ctx.beginPath();
        ctx.moveTo(cx, cy - outerRadius);

        for (let i = 0; i < spikes; i++) {
            ctx.lineTo(cx + Math.cos(rot) * outerRadius, cy + Math.sin(rot) * outerRadius);
            rot += step;
            ctx.lineTo(cx + Math.cos(rot) * innerRadius, cy + Math.sin(rot) * innerRadius);
            rot += step;
        }

        ctx.lineTo(cx, cy - outerRadius);
        ctx.closePath();
        ctx.fill();
    }

    /**
     * 检测碰撞
     */
    checkCollision(domino) {
        if (this.isExploding) return false;

        const top = domino.getTopPosition();
        const distance = Math.abs(top.x - this.x);
        const threshold = this.width / 2 + 20;

        // 检查骨牌顶部是否接触到建筑
        if (distance < threshold && Math.abs(domino.angle) > Math.PI / 4) {
            return true;
        }
        return false;
    }

    /**
     * 爆炸是否完成
     */
    isExplosionComplete() {
        return this.isExploding && this.particles.length === 0 && this.explosionProgress > 0.5;
    }

    /**
     * 颜色变亮
     */
    lightenColor(color, percent) {
        const num = parseInt(color.replace('#', ''), 16);
        const amt = Math.round(2.55 * percent);
        const R = Math.min(255, (num >> 16) + amt);
        const G = Math.min(255, ((num >> 8) & 0x00FF) + amt);
        const B = Math.min(255, (num & 0x0000FF) + amt);
        return '#' + (0x1000000 + R * 0x10000 + G * 0x100 + B).toString(16).slice(1);
    }

    /**
     * 颜色变暗
     */
    darkenColor(color, percent) {
        const num = parseInt(color.replace('#', ''), 16);
        const amt = Math.round(2.55 * percent);
        const R = Math.max(0, (num >> 16) - amt);
        const G = Math.max(0, ((num >> 8) & 0x00FF) - amt);
        const B = Math.max(0, (num & 0x0000FF) - amt);
        return '#' + (0x1000000 + R * 0x10000 + G * 0x100 + B).toString(16).slice(1);
    }
}

// 建筑类型列表（从配置派生，保证按钮与画布显示一致）
Building.TYPES = Object.entries(BUILDING_CONFIGS).map(([id, config]) => ({
    id,
    name: config.name,
    emoji: config.emoji
}));

// 导出
if (typeof module !== 'undefined' && module.exports) {
    module.exports = Building;
}
