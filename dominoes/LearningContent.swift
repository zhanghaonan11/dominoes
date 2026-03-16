import SpriteKit

struct DominoColorOption {
    let name: String
    let englishName: String
    let color: SKColor
}

struct LearningItem {
    let icon: String
    let englishName: String
    let chineseName: String
    let color: SKColor
}

struct LearningCategory {
    let icon: String
    let displayName: String
    let englishName: String
    let items: [LearningItem]
}

enum LearningContent {
    static let colorOptions: [DominoColorOption] = [
        DominoColorOption(name: "🟥 red", englishName: "red", color: SKColor(red: 0.90, green: 0.18, blue: 0.19, alpha: 1.0)),
        DominoColorOption(name: "🟧 orange", englishName: "orange", color: SKColor(red: 0.97, green: 0.49, blue: 0.13, alpha: 1.0)),
        DominoColorOption(name: "🟨 yellow", englishName: "yellow", color: SKColor(red: 0.95, green: 0.78, blue: 0.17, alpha: 1.0)),
        DominoColorOption(name: "🟩 green", englishName: "green", color: SKColor(red: 0.12, green: 0.72, blue: 0.39, alpha: 1.0)),
        DominoColorOption(name: "🩵 cyan", englishName: "cyan", color: SKColor(red: 0.08, green: 0.71, blue: 0.68, alpha: 1.0)),
        DominoColorOption(name: "🟦 blue", englishName: "blue", color: SKColor(red: 0.18, green: 0.55, blue: 0.96, alpha: 1.0)),
        DominoColorOption(name: "🔷 navy", englishName: "navy", color: SKColor(red: 0.09, green: 0.20, blue: 0.52, alpha: 1.0)),
        DominoColorOption(name: "🟪 purple", englishName: "purple", color: SKColor(red: 0.57, green: 0.31, blue: 0.89, alpha: 1.0)),
        DominoColorOption(name: "🩷 pink", englishName: "pink", color: SKColor(red: 0.90, green: 0.23, blue: 0.59, alpha: 1.0)),
        DominoColorOption(name: "⬛ black", englishName: "black", color: SKColor(red: 0.22, green: 0.24, blue: 0.29, alpha: 1.0))
    ]

    static let categories: [LearningCategory] = [
        LearningCategory(
            icon: "🎨", displayName: "颜色", englishName: "colors",
            items: [
                LearningItem(icon: "🟥", englishName: "red", chineseName: "红色", color: SKColor(red: 0.90, green: 0.18, blue: 0.19, alpha: 1.0)),
                LearningItem(icon: "🟧", englishName: "orange", chineseName: "橙色", color: SKColor(red: 0.97, green: 0.49, blue: 0.13, alpha: 1.0)),
                LearningItem(icon: "🟨", englishName: "yellow", chineseName: "黄色", color: SKColor(red: 0.95, green: 0.78, blue: 0.17, alpha: 1.0)),
                LearningItem(icon: "🟩", englishName: "green", chineseName: "绿色", color: SKColor(red: 0.12, green: 0.72, blue: 0.39, alpha: 1.0)),
                LearningItem(icon: "🩵", englishName: "cyan", chineseName: "青色", color: SKColor(red: 0.08, green: 0.71, blue: 0.68, alpha: 1.0)),
                LearningItem(icon: "🟦", englishName: "blue", chineseName: "蓝色", color: SKColor(red: 0.18, green: 0.55, blue: 0.96, alpha: 1.0)),
                LearningItem(icon: "🔷", englishName: "navy", chineseName: "藏蓝色", color: SKColor(red: 0.09, green: 0.20, blue: 0.52, alpha: 1.0)),
                LearningItem(icon: "🟪", englishName: "purple", chineseName: "紫色", color: SKColor(red: 0.57, green: 0.31, blue: 0.89, alpha: 1.0)),
                LearningItem(icon: "🩷", englishName: "pink", chineseName: "粉色", color: SKColor(red: 0.90, green: 0.23, blue: 0.59, alpha: 1.0)),
                LearningItem(icon: "⬛", englishName: "black", chineseName: "黑色", color: SKColor(red: 0.22, green: 0.24, blue: 0.29, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "🚗", displayName: "交通", englishName: "transportation",
            items: [
                LearningItem(icon: "🚗", englishName: "car", chineseName: "汽车", color: SKColor(red: 0.97, green: 0.58, blue: 0.44, alpha: 1.0)),
                LearningItem(icon: "🚌", englishName: "bus", chineseName: "公交车", color: SKColor(red: 0.99, green: 0.75, blue: 0.34, alpha: 1.0)),
                LearningItem(icon: "🚲", englishName: "bike", chineseName: "自行车", color: SKColor(red: 0.48, green: 0.83, blue: 0.50, alpha: 1.0)),
                LearningItem(icon: "🚂", englishName: "train", chineseName: "火车", color: SKColor(red: 0.46, green: 0.71, blue: 0.94, alpha: 1.0)),
                LearningItem(icon: "✈️", englishName: "plane", chineseName: "飞机", color: SKColor(red: 0.67, green: 0.64, blue: 0.93, alpha: 1.0)),
                LearningItem(icon: "🚢", englishName: "ship", chineseName: "轮船", color: SKColor(red: 0.39, green: 0.77, blue: 0.82, alpha: 1.0)),
                LearningItem(icon: "🚕", englishName: "taxi", chineseName: "出租车", color: SKColor(red: 0.98, green: 0.86, blue: 0.39, alpha: 1.0)),
                LearningItem(icon: "🚜", englishName: "tractor", chineseName: "拖拉机", color: SKColor(red: 0.72, green: 0.83, blue: 0.44, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "🍎", displayName: "水果", englishName: "fruits",
            items: [
                LearningItem(icon: "🍎", englishName: "apple", chineseName: "苹果", color: SKColor(red: 0.97, green: 0.47, blue: 0.47, alpha: 1.0)),
                LearningItem(icon: "🍌", englishName: "banana", chineseName: "香蕉", color: SKColor(red: 0.98, green: 0.87, blue: 0.37, alpha: 1.0)),
                LearningItem(icon: "🍊", englishName: "orange", chineseName: "橙子", color: SKColor(red: 0.99, green: 0.66, blue: 0.32, alpha: 1.0)),
                LearningItem(icon: "🍇", englishName: "grape", chineseName: "葡萄", color: SKColor(red: 0.73, green: 0.56, blue: 0.92, alpha: 1.0)),
                LearningItem(icon: "🍓", englishName: "strawberry", chineseName: "草莓", color: SKColor(red: 0.94, green: 0.38, blue: 0.56, alpha: 1.0)),
                LearningItem(icon: "🍉", englishName: "watermelon", chineseName: "西瓜", color: SKColor(red: 0.47, green: 0.82, blue: 0.50, alpha: 1.0)),
                LearningItem(icon: "🍐", englishName: "pear", chineseName: "梨", color: SKColor(red: 0.79, green: 0.86, blue: 0.38, alpha: 1.0)),
                LearningItem(icon: "🥝", englishName: "kiwi", chineseName: "猕猴桃", color: SKColor(red: 0.54, green: 0.76, blue: 0.39, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "🐶", displayName: "动物", englishName: "animals",
            items: [
                LearningItem(icon: "🐶", englishName: "dog", chineseName: "小狗", color: SKColor(red: 0.96, green: 0.73, blue: 0.50, alpha: 1.0)),
                LearningItem(icon: "🐱", englishName: "cat", chineseName: "小猫", color: SKColor(red: 0.97, green: 0.66, blue: 0.47, alpha: 1.0)),
                LearningItem(icon: "🐰", englishName: "rabbit", chineseName: "兔子", color: SKColor(red: 0.98, green: 0.80, blue: 0.87, alpha: 1.0)),
                LearningItem(icon: "🐻", englishName: "bear", chineseName: "熊", color: SKColor(red: 0.84, green: 0.65, blue: 0.48, alpha: 1.0)),
                LearningItem(icon: "🦁", englishName: "lion", chineseName: "狮子", color: SKColor(red: 0.98, green: 0.76, blue: 0.41, alpha: 1.0)),
                LearningItem(icon: "🐼", englishName: "panda", chineseName: "熊猫", color: SKColor(red: 0.77, green: 0.79, blue: 0.82, alpha: 1.0)),
                LearningItem(icon: "🐢", englishName: "turtle", chineseName: "乌龟", color: SKColor(red: 0.51, green: 0.82, blue: 0.52, alpha: 1.0)),
                LearningItem(icon: "🐘", englishName: "elephant", chineseName: "大象", color: SKColor(red: 0.68, green: 0.76, blue: 0.88, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "🌱", displayName: "植物", englishName: "plants",
            items: [
                LearningItem(icon: "🌳", englishName: "tree", chineseName: "树", color: SKColor(red: 0.46, green: 0.73, blue: 0.37, alpha: 1.0)),
                LearningItem(icon: "🌻", englishName: "sunflower", chineseName: "向日葵", color: SKColor(red: 0.98, green: 0.76, blue: 0.30, alpha: 1.0)),
                LearningItem(icon: "🌹", englishName: "rose", chineseName: "玫瑰", color: SKColor(red: 0.90, green: 0.32, blue: 0.44, alpha: 1.0)),
                LearningItem(icon: "🌷", englishName: "tulip", chineseName: "郁金香", color: SKColor(red: 0.92, green: 0.57, blue: 0.63, alpha: 1.0)),
                LearningItem(icon: "🍀", englishName: "clover", chineseName: "三叶草", color: SKColor(red: 0.36, green: 0.76, blue: 0.42, alpha: 1.0)),
                LearningItem(icon: "🌿", englishName: "leaf", chineseName: "叶子", color: SKColor(red: 0.39, green: 0.80, blue: 0.46, alpha: 1.0)),
                LearningItem(icon: "🌵", englishName: "cactus", chineseName: "仙人掌", color: SKColor(red: 0.48, green: 0.72, blue: 0.36, alpha: 1.0)),
                LearningItem(icon: "🍄", englishName: "mushroom", chineseName: "蘑菇", color: SKColor(red: 0.88, green: 0.45, blue: 0.34, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "🚀", displayName: "太空", englishName: "space",
            items: [
                LearningItem(icon: "☀️", englishName: "sun", chineseName: "太阳", color: SKColor(red: 0.98, green: 0.76, blue: 0.30, alpha: 1.0)),
                LearningItem(icon: "🌙", englishName: "moon", chineseName: "月亮", color: SKColor(red: 0.84, green: 0.83, blue: 0.63, alpha: 1.0)),
                LearningItem(icon: "⭐️", englishName: "star", chineseName: "星星", color: SKColor(red: 0.99, green: 0.86, blue: 0.42, alpha: 1.0)),
                LearningItem(icon: "🪐", englishName: "planet", chineseName: "行星", color: SKColor(red: 0.72, green: 0.57, blue: 0.91, alpha: 1.0)),
                LearningItem(icon: "🌍", englishName: "earth", chineseName: "地球", color: SKColor(red: 0.43, green: 0.73, blue: 0.91, alpha: 1.0)),
                LearningItem(icon: "☄️", englishName: "comet", chineseName: "彗星", color: SKColor(red: 0.79, green: 0.81, blue: 0.90, alpha: 1.0)),
                LearningItem(icon: "🛸", englishName: "ufo", chineseName: "飞碟", color: SKColor(red: 0.68, green: 0.79, blue: 0.88, alpha: 1.0)),
                LearningItem(icon: "🚀", englishName: "rocket", chineseName: "火箭", color: SKColor(red: 0.90, green: 0.40, blue: 0.43, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "🧍", displayName: "身体", englishName: "body",
            items: [
                LearningItem(icon: "👀", englishName: "eyes", chineseName: "眼睛", color: SKColor(red: 0.50, green: 0.73, blue: 0.90, alpha: 1.0)),
                LearningItem(icon: "👂", englishName: "ears", chineseName: "耳朵", color: SKColor(red: 0.95, green: 0.76, blue: 0.60, alpha: 1.0)),
                LearningItem(icon: "👃", englishName: "nose", chineseName: "鼻子", color: SKColor(red: 0.93, green: 0.66, blue: 0.58, alpha: 1.0)),
                LearningItem(icon: "👄", englishName: "mouth", chineseName: "嘴巴", color: SKColor(red: 0.94, green: 0.45, blue: 0.55, alpha: 1.0)),
                LearningItem(icon: "✋", englishName: "hand", chineseName: "手", color: SKColor(red: 0.98, green: 0.78, blue: 0.56, alpha: 1.0)),
                LearningItem(icon: "🦶", englishName: "foot", chineseName: "脚", color: SKColor(red: 0.90, green: 0.65, blue: 0.52, alpha: 1.0)),
                LearningItem(icon: "🦷", englishName: "tooth", chineseName: "牙齿", color: SKColor(red: 0.86, green: 0.88, blue: 0.92, alpha: 1.0)),
                LearningItem(icon: "❤️", englishName: "heart", chineseName: "心脏", color: SKColor(red: 0.90, green: 0.33, blue: 0.38, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "👨‍👩‍👧", displayName: "家庭", englishName: "family",
            items: [
                LearningItem(icon: "👨", englishName: "father", chineseName: "爸爸", color: SKColor(red: 0.53, green: 0.74, blue: 0.92, alpha: 1.0)),
                LearningItem(icon: "👩", englishName: "mother", chineseName: "妈妈", color: SKColor(red: 0.96, green: 0.62, blue: 0.70, alpha: 1.0)),
                LearningItem(icon: "👦", englishName: "boy", chineseName: "男孩", color: SKColor(red: 0.42, green: 0.73, blue: 0.88, alpha: 1.0)),
                LearningItem(icon: "👧", englishName: "girl", chineseName: "女孩", color: SKColor(red: 0.94, green: 0.64, blue: 0.74, alpha: 1.0)),
                LearningItem(icon: "👶", englishName: "baby", chineseName: "宝宝", color: SKColor(red: 0.98, green: 0.78, blue: 0.62, alpha: 1.0)),
                LearningItem(icon: "👴", englishName: "grandpa", chineseName: "爷爷", color: SKColor(red: 0.74, green: 0.80, blue: 0.86, alpha: 1.0)),
                LearningItem(icon: "👵", englishName: "grandma", chineseName: "奶奶", color: SKColor(red: 0.86, green: 0.76, blue: 0.84, alpha: 1.0)),
                LearningItem(icon: "🏠", englishName: "home", chineseName: "家", color: SKColor(red: 0.86, green: 0.68, blue: 0.46, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "🍽️", displayName: "食物", englishName: "food",
            items: [
                LearningItem(icon: "🍚", englishName: "rice", chineseName: "米饭", color: SKColor(red: 0.90, green: 0.88, blue: 0.82, alpha: 1.0)),
                LearningItem(icon: "🍞", englishName: "bread", chineseName: "面包", color: SKColor(red: 0.90, green: 0.68, blue: 0.46, alpha: 1.0)),
                LearningItem(icon: "🥚", englishName: "egg", chineseName: "鸡蛋", color: SKColor(red: 0.96, green: 0.86, blue: 0.62, alpha: 1.0)),
                LearningItem(icon: "🥛", englishName: "milk", chineseName: "牛奶", color: SKColor(red: 0.84, green: 0.90, blue: 0.97, alpha: 1.0)),
                LearningItem(icon: "🧀", englishName: "cheese", chineseName: "奶酪", color: SKColor(red: 0.98, green: 0.82, blue: 0.36, alpha: 1.0)),
                LearningItem(icon: "🍜", englishName: "noodles", chineseName: "面条", color: SKColor(red: 0.92, green: 0.72, blue: 0.46, alpha: 1.0)),
                LearningItem(icon: "🍪", englishName: "cookie", chineseName: "饼干", color: SKColor(red: 0.83, green: 0.62, blue: 0.42, alpha: 1.0)),
                LearningItem(icon: "🍯", englishName: "honey", chineseName: "蜂蜜", color: SKColor(red: 0.95, green: 0.67, blue: 0.28, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "🔺", displayName: "形状", englishName: "shapes",
            items: [
                LearningItem(icon: "⚪️", englishName: "circle", chineseName: "圆形", color: SKColor(red: 0.86, green: 0.88, blue: 0.92, alpha: 1.0)),
                LearningItem(icon: "⬜️", englishName: "square", chineseName: "正方形", color: SKColor(red: 0.82, green: 0.90, blue: 0.95, alpha: 1.0)),
                LearningItem(icon: "🔺", englishName: "triangle", chineseName: "三角形", color: SKColor(red: 0.94, green: 0.46, blue: 0.43, alpha: 1.0)),
                LearningItem(icon: "🔷", englishName: "diamond", chineseName: "菱形", color: SKColor(red: 0.45, green: 0.68, blue: 0.93, alpha: 1.0)),
                LearningItem(icon: "🟧", englishName: "rectangle", chineseName: "长方形", color: SKColor(red: 0.95, green: 0.62, blue: 0.33, alpha: 1.0)),
                LearningItem(icon: "⭐️", englishName: "star", chineseName: "星形", color: SKColor(red: 0.98, green: 0.82, blue: 0.36, alpha: 1.0)),
                LearningItem(icon: "❤️", englishName: "heart", chineseName: "心形", color: SKColor(red: 0.90, green: 0.35, blue: 0.45, alpha: 1.0)),
                LearningItem(icon: "🌙", englishName: "crescent", chineseName: "月牙形", color: SKColor(red: 0.84, green: 0.84, blue: 0.66, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "☀️", displayName: "天气", englishName: "weather",
            items: [
                LearningItem(icon: "☀️", englishName: "sunny", chineseName: "晴天", color: SKColor(red: 0.98, green: 0.78, blue: 0.31, alpha: 1.0)),
                LearningItem(icon: "☁️", englishName: "cloudy", chineseName: "多云", color: SKColor(red: 0.72, green: 0.80, blue: 0.88, alpha: 1.0)),
                LearningItem(icon: "🌧️", englishName: "rainy", chineseName: "下雨", color: SKColor(red: 0.43, green: 0.62, blue: 0.86, alpha: 1.0)),
                LearningItem(icon: "⛈️", englishName: "stormy", chineseName: "雷雨", color: SKColor(red: 0.44, green: 0.49, blue: 0.67, alpha: 1.0)),
                LearningItem(icon: "❄️", englishName: "snowy", chineseName: "下雪", color: SKColor(red: 0.83, green: 0.92, blue: 0.98, alpha: 1.0)),
                LearningItem(icon: "🌈", englishName: "rainbow", chineseName: "彩虹", color: SKColor(red: 0.86, green: 0.68, blue: 0.92, alpha: 1.0)),
                LearningItem(icon: "💨", englishName: "windy", chineseName: "有风", color: SKColor(red: 0.72, green: 0.84, blue: 0.95, alpha: 1.0)),
                LearningItem(icon: "🌫️", englishName: "foggy", chineseName: "有雾", color: SKColor(red: 0.76, green: 0.80, blue: 0.85, alpha: 1.0))
            ]
        ),
        LearningCategory(
            icon: "⚽️", displayName: "运动", englishName: "sports",
            items: [
                LearningItem(icon: "⚽️", englishName: "soccer", chineseName: "足球", color: SKColor(red: 0.56, green: 0.80, blue: 0.40, alpha: 1.0)),
                LearningItem(icon: "🏀", englishName: "basketball", chineseName: "篮球", color: SKColor(red: 0.95, green: 0.57, blue: 0.28, alpha: 1.0)),
                LearningItem(icon: "🏈", englishName: "football", chineseName: "橄榄球", color: SKColor(red: 0.74, green: 0.48, blue: 0.32, alpha: 1.0)),
                LearningItem(icon: "⚾️", englishName: "baseball", chineseName: "棒球", color: SKColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1.0)),
                LearningItem(icon: "🎾", englishName: "tennis", chineseName: "网球", color: SKColor(red: 0.78, green: 0.86, blue: 0.38, alpha: 1.0)),
                LearningItem(icon: "🏸", englishName: "badminton", chineseName: "羽毛球", color: SKColor(red: 0.80, green: 0.88, blue: 0.95, alpha: 1.0)),
                LearningItem(icon: "🏊", englishName: "swimming", chineseName: "游泳", color: SKColor(red: 0.45, green: 0.69, blue: 0.91, alpha: 1.0)),
                LearningItem(icon: "🏃", englishName: "running", chineseName: "跑步", color: SKColor(red: 0.90, green: 0.62, blue: 0.36, alpha: 1.0))
            ]
        )
    ]
}
