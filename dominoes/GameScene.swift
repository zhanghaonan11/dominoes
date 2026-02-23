//
//  GameScene.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import SpriteKit
import UIKit
import os
import AVFoundation

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private struct Layout {
        let groundY: CGFloat
        let startX: CGFloat
        let dominoWidth: CGFloat
        let baseDominoHeight: CGFloat
        let heightIncrement: CGFloat
        let spacing: CGFloat
        let towerX: CGFloat
        let towerWidth: CGFloat
        let ballRadius: CGFloat
        let ballStartX: CGFloat
        let ballStartY: CGFloat
        let titleY: CGFloat
        let subtitleY: CGFloat
        let buttonY: CGFloat
        let isWide: Bool
    }
    
    private struct DominoColorOption {
        let name: String
        let englishName: String
        let color: SKColor
    }

    private struct LearningItem {
        let icon: String
        let englishName: String
        let chineseName: String
        let color: SKColor
    }

    private struct LearningCategory {
        let icon: String
        let displayName: String
        let englishName: String
        let items: [LearningItem]
    }

    private struct FirstImpactTelemetry {
        var runID: Int = 0
        var directAssistCount: Int = 0
        var fallbackAssistCount: Int = 0
    }
    
    private var layout: Layout?
    private var dominos: [DominoNode] = []
    
    // Core Elements
    private var ballNode: SKShapeNode?
    private var towerNode: SKNode?
    private var startButton: SKShapeNode?
    private var resetButton: SKShapeNode?
    private var landmarkButton: SKShapeNode?
    private var categoryButton: SKShapeNode?
    private var subtitleLabel: SKLabelNode?
    private var countdownLabel: SKLabelNode?
    private var staircaseNode: StaircaseNode?
    
    // Managers and State
    private var isAnimating = false
    private var isInitialized = false

    // Physics chain-reaction monitoring
    private var lastProgressTime: TimeInterval = 0
    private var fallenCount: Int = 0
    private var nudgeCount: Int = 0
    private var chainWatchdogActionKey = "chainWatchdog"
    private var firstImpactAssistActionKey = "firstImpactAssist"
    private var firstImpactFallbackActionKey = "firstImpactFallback"
    private var towerToppleActionKey = "towerTopple"
    private var hasTriggeredExplosion = false
    private var currentBackgroundIndex = 0
    private var backgroundNode: SKSpriteNode?
    
    // Reusable Textures
    private var dominoTexture: SKTexture?
    private var explosionParticleTexture: SKTexture?
    
    // Button interaction state
    private var startButtonEnabled = false
    private var resetButtonEnabled = false
    private var landmarkButtonEnabled = false
    private var categoryButtonEnabled = false
    
    private var selectedLandmark: TowerNode.Landmark = .eiffelTower
    private var selectedDominoNode: DominoNode?
    private var selectedDominoLearningItemIndices: [Int] = []
    private var selectedLearningCategoryIndex = 0
    private var selectedBallColorOptionIndex = 5
    private var selectedGuideLineColorOptionIndex = 5
    private var flowStateMachine = GameFlowStateMachine()
    private var firstImpactTelemetry = FirstImpactTelemetry()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "wipo.dominoes", category: "Simulation")
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private let dominoColorOptions: [DominoColorOption] = [
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

    private let learningCategories: [LearningCategory] = [
        LearningCategory(
            icon: "🎨",
            displayName: "颜色",
            englishName: "colors",
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
            icon: "🚗",
            displayName: "交通",
            englishName: "transportation",
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
            icon: "🍎",
            displayName: "水果",
            englishName: "fruits",
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
            icon: "🐶",
            displayName: "动物",
            englishName: "animals",
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
            icon: "🌱",
            displayName: "植物",
            englishName: "plants",
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
            icon: "🚀",
            displayName: "太空",
            englishName: "space",
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
            icon: "🧍",
            displayName: "身体",
            englishName: "body",
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
            icon: "👨‍👩‍👧",
            displayName: "家庭",
            englishName: "family",
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
            icon: "🍽️",
            displayName: "食物",
            englishName: "food",
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
            icon: "🔺",
            displayName: "形状",
            englishName: "shapes",
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
            icon: "☀️",
            displayName: "天气",
            englishName: "weather",
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
            icon: "⚽️",
            displayName: "运动",
            englishName: "sports",
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
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        physicsWorld.gravity = GameConstants.Physics.gravity
        physicsWorld.contactDelegate = self
        buildStaticSceneOnce()
        resetInteractiveElements()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        // For simplicity, we just rebuild if the size changes (e.g., orientation change)
        isInitialized = false
        removeAllChildren()
        buildStaticSceneOnce()
        resetInteractiveElements()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard let targetName = buttonName(at: location) else { return }
        
        switch targetName {
        case "dominoTarget":
            guard !isAnimating else { return }
            guard let domino = touchedDomino(at: location) else { return }
            selectedDominoNode = domino
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentDominoLearningPicker()
        case "ball":
            guard !isAnimating else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentBallColorPicker()
        case "guideLineTarget":
            guard !isAnimating else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentGuideLineColorPicker(anchor: location)
        case "startButton":
            guard startButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            startAnimation()
        case "landmarkButton", "towerTarget":
            guard landmarkButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentLandmarkPicker()
        case "categoryButton":
            guard categoryButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentLearningCategoryPicker()
        case "resetButton":
            guard resetButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            currentBackgroundIndex = (currentBackgroundIndex + 1) % GameConstants.Colors.backgroundGradients.count
            updateBackground()
            resetInteractiveElements()
        default:
            break
        }
    }
    
    // MARK: - Scene Construction
    
    private func buildStaticSceneOnce() {
        guard !isInitialized else { return }
        isInitialized = true
        layout = makeLayout(for: size)
        
        let bgNode = makeGradientBackground(size: size)
        addChild(bgNode)
        backgroundNode = bgNode
        makeClouds()
        addChild(makeGround())
        addChild(makeTitle())
        let subtitle = makeSubtitle()
        addChild(subtitle)
        subtitleLabel = subtitle
        
        makeButtons()
        makeCountdownLabel()
        
        // Prepare reusable textures
        if let layout = layout {
            dominoTexture = DominoNode.createBaseTexture(width: layout.dominoWidth, height: layout.baseDominoHeight + CGFloat(GameConstants.Geometry.numDominos) * layout.heightIncrement)
        }
    }
    
    private func resetInteractiveElements() {
        guard let layout = layout else { return }
        
        // Clean up previous dynamic elements
        dominos.forEach { $0.removeFromParent() }
        dominos.removeAll()
        ballNode?.removeFromParent()
        towerNode?.removeFromParent()
        staircaseNode?.removeFromParent()
        
        // Remove active emitters if any
        enumerateChildNodes(withName: "explosionEmitter") { node, _ in
            node.removeFromParent()
        }
        
        isAnimating = false
        removeAction(forKey: GameConstants.autoResetActionKey)
        removeAction(forKey: chainWatchdogActionKey)
        removeAction(forKey: firstImpactAssistActionKey)
        removeAction(forKey: firstImpactFallbackActionKey)
        towerNode?.removeAction(forKey: towerToppleActionKey)
        countdownLabel?.text = ""
        countdownLabel?.isHidden = true
        selectedDominoNode = nil
        fallenCount = 0
        nudgeCount = 0
        lastProgressTime = 0
        hasTriggeredExplosion = false
        flowStateMachine.resetToIdle()
        
        // Build new dynamic elements
        let ball = makeBall(layout: layout)
        ballNode = ball
        addChild(ball)
        
        let staircase = StaircaseNode.build(
            startX: layout.startX,
            groundY: layout.groundY,
            height: layout.baseDominoHeight * 4,
            ballRadius: layout.ballRadius,
            guideColor: currentGuideLineColorOption().color
        )
        staircaseNode = staircase
        addChild(staircase)
        
        // Initially place ball at the top of the stairs
        if let firstPoint = staircase.rollPath.first {
            ball.position = firstPoint.position
            ball.zPosition = firstPoint.zPosition
            ball.setScale(firstPoint.scale)
        }
        
        makeDominos(layout: layout)
        makeTower(layout: layout)
        updateLearningThemeButtonTitle()
        updateSubtitleText()
        
        setButtonEnabled(resetButton, enabled: true)
        setButtonEnabled(startButton, enabled: true)
        setButtonEnabled(landmarkButton, enabled: true)
        setButtonEnabled(categoryButton, enabled: true)
    }
    
    private func resetScene() {
        guard !isAnimating else { return }
        resetInteractiveElements()
    }
    
    private func makeLayout(for size: CGSize) -> Layout {
        let sceneWidth = size.width
        let sceneHeight = size.height
        let isWide = sceneWidth > sceneHeight * 1.2
        
        let groundY = sceneHeight * (isWide ? 0.16 : 0.18)
        let startX = sceneWidth * (isWide ? 0.08 : 0.12)
        
        let chainWidth = sceneWidth * (isWide ? 0.64 : 0.62)
        let spacing = chainWidth / CGFloat(GameConstants.Geometry.numDominos - 1)
        let dominoWidth = clamp(sceneWidth * 0.016, min: 10, max: 18)
        let baseDominoHeight = sceneHeight * 0.10
        let heightIncrement = sceneHeight * 0.015
        
        let towerX = startX + chainWidth + sceneWidth * (isWide ? 0.06 : 0.08)
        let towerWidth = sceneWidth * (isWide ? 0.10 : 0.12)
        
        let ballRadius = dominoWidth * 1.1
        let ballStartX = sceneWidth * (isWide ? 0.03 : 0.04)
        let ballStartY = sceneHeight * (isWide ? 0.90 : 0.88)
        
        let titleY = sceneHeight - (isWide ? 42 : 60)
        let subtitleY = sceneHeight - (isWide ? 66 : 88)
        let buttonY = sceneHeight * (isWide ? 0.12 : 0.08)
        
        return Layout(
            groundY: groundY,
            startX: startX,
            dominoWidth: dominoWidth,
            baseDominoHeight: baseDominoHeight,
            heightIncrement: heightIncrement,
            spacing: spacing,
            towerX: towerX,
            towerWidth: towerWidth,
            ballRadius: ballRadius,
            ballStartX: ballStartX,
            ballStartY: ballStartY,
            titleY: titleY,
            subtitleY: subtitleY,
            buttonY: buttonY,
            isWide: isWide
        )
    }
    
    private func makeGradientBackground(size: CGSize) -> SKSpriteNode {
        let colors = GameConstants.Colors.backgroundGradients[currentBackgroundIndex]
        let texture = gradientTexture(
            size: size,
            colors: [colors.0, colors.1]
        )
        let node = SKSpriteNode(texture: texture)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.zPosition = -20
        return node
    }
    
    private func updateBackground() {
        guard let node = backgroundNode else { return }
        let colors = GameConstants.Colors.backgroundGradients[currentBackgroundIndex]
        let texture = gradientTexture(
            size: size,
            colors: [colors.0, colors.1]
        )
        let fadeOut = SKAction.fadeAlpha(to: 0.8, duration: 0.15)
        let updateTexture = SKAction.run { node.texture = texture }
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
        node.run(SKAction.sequence([fadeOut, updateTexture, fadeIn]))
        
        // 蓝天白云时产生云，其他背景停止生成并淡出当前云
        if currentBackgroundIndex == 0 {
            makeClouds()
        } else {
            removeAction(forKey: "spawnClouds")
            enumerateChildNodes(withName: "cloudNode") { cloud, _ in
                let fade = SKAction.fadeOut(withDuration: 1.0)
                let remove = SKAction.removeFromParent()
                cloud.run(SKAction.sequence([fade, remove]))
            }
        }
    }
    
    private func makeClouds() {
        removeAction(forKey: "spawnClouds")
        let numClouds = Int.random(in: 4...7)
        for _ in 0..<numClouds {
            spawnCloud(fromRight: false)
        }
        
        let wait = SKAction.wait(forDuration: 6.0, withRange: 4.0)
        let spawn = SKAction.run { [weak self] in
            self?.spawnCloud(fromRight: true)
        }
        let seq = SKAction.sequence([wait, spawn])
        run(SKAction.repeatForever(seq), withKey: "spawnClouds")
    }
    
    private func spawnCloud(fromRight: Bool) {
        let cloudWidth = CGFloat.random(in: 120...200)
        let cloudHeight = cloudWidth * 0.35
        let cloud = SKShapeNode(rectOf: CGSize(width: cloudWidth, height: cloudHeight), cornerRadius: cloudHeight / 2)
        cloud.name = "cloudNode"
        cloud.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.6...0.9))
        cloud.strokeColor = .clear
        cloud.zPosition = -15
        
        // 分别在云的上方添加大小不一的凸起结构，使其更像云朵
        let puff1 = SKShapeNode(circleOfRadius: cloudHeight * 0.6)
        puff1.fillColor = cloud.fillColor
        puff1.strokeColor = .clear
        puff1.position = CGPoint(x: -cloudWidth * 0.15, y: cloudHeight * 0.3)
        cloud.addChild(puff1)
        
        let puff2 = SKShapeNode(circleOfRadius: cloudHeight * 0.5)
        puff2.fillColor = cloud.fillColor
        puff2.strokeColor = .clear
        puff2.position = CGPoint(x: cloudWidth * 0.2, y: cloudHeight * 0.2)
        cloud.addChild(puff2)
        
        let scale = CGFloat.random(in: 0.5...1.2)
        cloud.setScale(scale)
        
        let py = size.height * CGFloat.random(in: 0.50...0.85)
        let px: CGFloat
        if fromRight {
            px = size.width + cloudWidth * scale + 50
        } else {
            px = CGFloat.random(in: -50...size.width + 50)
        }
        cloud.position = CGPoint(x: px, y: py)
        addChild(cloud)
        
        // 让远处的云（较小）移动得更慢，形成视差效果
        let duration = TimeInterval(CGFloat.random(in: 30.0...50.0) / scale)
        let endX = -cloudWidth * scale - 50
        let distance = px - endX
        if distance > 0 {
            let time = TimeInterval(distance / (size.width + cloudWidth * scale * 2 + 100)) * duration
            let move = SKAction.moveTo(x: endX, duration: time)
            let remove = SKAction.removeFromParent()
            cloud.run(SKAction.sequence([move, remove]))
        } else {
            cloud.removeFromParent()
        }
    }
    
    private func makeGround() -> SKNode {
        let group = SKNode()
        group.zPosition = -5
        guard let layout = layout else { return group }

        let ground = SKSpriteNode(color: GameConstants.Colors.groundMain, size: CGSize(width: size.width, height: layout.groundY))
        ground.anchorPoint = CGPoint(x: 0.5, y: 0)
        ground.position = CGPoint(x: size.width / 2, y: 0)
        ground.name = "ground"
        
        // Static physics body for collisions.
        ground.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: -size.width / 2, y: 0, width: size.width, height: layout.groundY))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = GameConstants.Physics.ground
        ground.physicsBody?.collisionBitMask = GameConstants.Physics.domino | GameConstants.Physics.ball
        ground.physicsBody?.contactTestBitMask = GameConstants.Physics.domino | GameConstants.Physics.ball

        group.addChild(ground)

        let topStrip = SKSpriteNode(color: GameConstants.Colors.groundStrip, size: CGSize(width: size.width, height: 8))
        topStrip.anchorPoint = CGPoint(x: 0.5, y: 0)
        topStrip.position = CGPoint(x: size.width / 2, y: layout.groundY - 8)
        group.addChild(topStrip)

        return group
    }
    
    private func makeTitle() -> SKLabelNode {
        let currentLayout = layout ?? makeLayout(for: size)
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "多米诺骨牌效应"
        label.fontSize = 28
        label.fontColor = GameConstants.Colors.textTitle
        label.position = CGPoint(x: size.width / 2, y: currentLayout.titleY)
        label.zPosition = 5
        return label
    }
    
    private func makeSubtitle() -> SKLabelNode {
        let currentLayout = layout ?? makeLayout(for: size)
        let label = SKLabelNode(fontNamed: "AvenirNext-Regular")
        label.text = subtitleText(for: selectedLandmark)
        label.fontSize = 14
        label.fontColor = GameConstants.Colors.textSubtitle
        label.position = CGPoint(x: size.width / 2, y: currentLayout.subtitleY)
        label.zPosition = 5
        return label
    }
    
    private func subtitleText(for landmark: TowerNode.Landmark) -> String {
        let category = currentLearningCategory()
        return "主题：\(category.icon)\(category.displayName)｜点骨牌学单词，开始模拟击倒\(landmark.displayName)"
    }
    
    private func updateSubtitleText() {
        subtitleLabel?.text = subtitleText(for: selectedLandmark)
    }
    
    private func makeBall(layout: Layout) -> SKShapeNode {
        let colorOption = currentBallColorOption()
        let ball = SKShapeNode(circleOfRadius: layout.ballRadius)
        ball.fillColor = colorOption.color
        ball.strokeColor = ballStrokeColor(for: colorOption.color)
        ball.lineWidth = 2
        ball.position = CGPoint(x: layout.ballStartX, y: layout.ballStartY)
        ball.zPosition = 2
        ball.name = "ball"
        
        // Ball is animated along the staircase path first; physics is enabled right before impact.
        let body = SKPhysicsBody(circleOfRadius: layout.ballRadius)
        body.isDynamic = false
        body.affectedByGravity = true
        body.friction = GameConstants.Physics.ballFriction
        body.restitution = GameConstants.Physics.ballRestitution
        body.linearDamping = GameConstants.Physics.ballLinearDamping
        body.angularDamping = GameConstants.Physics.ballAngularDamping
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = GameConstants.Physics.ball
        // 动画下落过程中不进行碰撞检测
        body.collisionBitMask = 0
        body.contactTestBitMask = 0
        ball.physicsBody = body
        
        return ball
    }
    
    private func makeDominos(layout: Layout) {
        // Slightly tighter spacing improves chain reliability in a physics simulation.
        let spacing = layout.spacing * 0.95
        let category = currentLearningCategory()
        let itemIndices = resolvedDominoLearningItemIndices()
        
        for index in 0..<GameConstants.Geometry.numDominos {
            let x = layout.startX + CGFloat(index) * spacing
            let height = layout.baseDominoHeight + CGFloat(index) * layout.heightIncrement
            let itemIndex = itemIndices[index]
            let item = category.items[itemIndex]
            
            let domino = DominoNode(
                color: item.color,
                colorOptionIndex: itemIndex,
                learningIcon: item.icon,
                xPosition: x,
                width: layout.dominoWidth,
                height: height,
                texture: dominoTexture
            )
            domino.position = CGPoint(x: x + layout.dominoWidth, y: layout.groundY)
            domino.zPosition = 3
            domino.name = "dominoTarget"
            domino.configurePhysics()
            
            addChild(domino)
            dominos.append(domino)
        }
    }
    
    private func makeTower(layout: Layout) {
        let lastDominoHeight = layout.baseDominoHeight + CGFloat(GameConstants.Geometry.numDominos - 1) * layout.heightIncrement
        let minTowerHeight = lastDominoHeight * 1.06
        let towerWidth = max(layout.towerWidth, minTowerHeight / TowerNode.heightFactor(for: selectedLandmark))

        let tower = TowerNode.build(width: towerWidth, landmark: selectedLandmark)
        tower.position = CGPoint(x: layout.towerX + towerWidth / 2, y: layout.groundY)
        tower.zPosition = 4
        tower.name = "towerTarget"
        addChild(tower)
        towerNode = tower
    }
    
    private func makeButtons() {
        let currentLayout = layout ?? makeLayout(for: size)
        let spacing: CGFloat = currentLayout.isWide ? 12 : 8
        let horizontalPadding: CGFloat = currentLayout.isWide ? 48 : 16
        let preferredWidth: CGFloat = currentLayout.isWide ? 132 : 88
        let buttonWidth = min(preferredWidth, (size.width - horizontalPadding - 3 * spacing) / 4)
        
        let start = makeButton(
            name: "startButton",
            title: "开始模拟",
            fillColor: GameConstants.Colors.buttonBlueFill,
            textColor: GameConstants.Colors.buttonBlueText,
            layout: currentLayout,
            width: buttonWidth
        )
        let landmark = makeButton(
            name: "landmarkButton",
            title: "选择建筑",
            fillColor: SKColor(red: 0.20, green: 0.70, blue: 0.66, alpha: 1.0),
            textColor: SKColor.white,
            layout: currentLayout,
            width: buttonWidth
        )
        let category = makeButton(
            name: "categoryButton",
            title: learningThemeButtonTitle(),
            fillColor: SKColor(red: 0.99, green: 0.62, blue: 0.29, alpha: 1.0),
            textColor: SKColor.white,
            layout: currentLayout,
            width: buttonWidth
        )
        let reset = makeButton(
            name: "resetButton",
            title: "切换背景",
            fillColor: GameConstants.Colors.buttonGrayFill,
            textColor: GameConstants.Colors.buttonGrayText,
            layout: currentLayout,
            width: buttonWidth
        )
        
        let totalWidth = 4 * start.frame.width + 3 * spacing
        let startX = (size.width - totalWidth) / 2 + start.frame.width / 2
        let y = currentLayout.buttonY
        
        start.position = CGPoint(x: startX, y: y)
        landmark.position = CGPoint(x: startX + start.frame.width + spacing, y: y)
        category.position = CGPoint(x: startX + 2 * (start.frame.width + spacing), y: y)
        reset.position = CGPoint(x: startX + 3 * (start.frame.width + spacing), y: y)
        
        addChild(start)
        addChild(landmark)
        addChild(category)
        addChild(reset)
        startButton = start
        landmarkButton = landmark
        categoryButton = category
        resetButton = reset
    }
    
    private func makeCountdownLabel() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = ""
        label.fontSize = 42
        label.fontColor = SKColor(white: 0.25, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 20
        label.isHidden = true
        addChild(label)
        countdownLabel = label
    }
    
    private func makeButton(name: String, title: String, fillColor: SKColor, textColor: SKColor, layout: Layout, width: CGFloat) -> SKShapeNode {
        let size = CGSize(width: width, height: layout.isWide ? 52 : 44)
        let button = SKShapeNode(rectOf: size, cornerRadius: 12)
        button.name = name
        button.fillColor = fillColor
        button.strokeColor = fillColor
        button.zPosition = 6
        
        let shadow = SKShapeNode(rectOf: size, cornerRadius: 12)
        shadow.fillColor = SKColor(white: 0.0, alpha: 0.1)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -3)
        shadow.zPosition = -1
        button.addChild(shadow)
        
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = title
        label.fontSize = layout.isWide ? 15 : 13
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = name
        button.addChild(label)
        
        return button
    }
    
    // MARK: - Interactions
    
    private func learningThemeButtonTitle() -> String {
        let category = currentLearningCategory()
        return "\(category.icon)\(category.displayName)"
    }

    private func updateLearningThemeButtonTitle() {
        guard let label = categoryButton?.children.compactMap({ $0 as? SKLabelNode }).first else { return }
        label.text = learningThemeButtonTitle()
    }

    private func setButtonEnabled(_ button: SKShapeNode?, enabled: Bool) {
        guard let button = button else { return }
        button.alpha = enabled ? 1.0 : 0.45
        button.isUserInteractionEnabled = false // SKShapeNode doesn't handle touches directly here
        
        if button.name == "startButton" {
            startButtonEnabled = enabled
        } else if button.name == "landmarkButton" {
            landmarkButtonEnabled = enabled
        } else if button.name == "resetButton" {
            resetButtonEnabled = enabled
        } else if button.name == "categoryButton" {
            categoryButtonEnabled = enabled
        }
    }
    
    private func buttonName(at location: CGPoint) -> String? {
        let nodesAtPoint = nodes(at: location)
        for node in nodesAtPoint {
            var current: SKNode? = node
            while let candidate = current {
                if let name = candidate.name {
                    return name
                }
                current = candidate.parent
            }
        }
        return nil
    }
    
    private func presentLandmarkPicker() {
        guard let presenter = presentingViewController() else { return }
        
        let alert = UIAlertController(title: "Choose Building", message: "Pick one building", preferredStyle: .actionSheet)
        
        for landmark in TowerNode.Landmark.allCases {
            let landmarkTitle = "\(landmark.thumbnailIcon) \(landmark.englishName)"
            let title = landmark == selectedLandmark ? "\(landmarkTitle) ✓" : landmarkTitle
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applySelectedLandmark(landmark)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController, let sceneView = view {
            popover.sourceView = sceneView
            let anchorPoint = landmarkButton?.position ?? CGPoint(x: size.width / 2, y: size.height * 0.1)
            let anchorInView = convertPoint(toView: anchorPoint)
            popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
            popover.permittedArrowDirections = [.up, .down]
        }
        
        presenter.present(alert, animated: true)
    }
    
    private func applySelectedLandmark(_ landmark: TowerNode.Landmark) {
        speakEnglish(landmark.englishName)
        guard selectedLandmark != landmark else { return }
        selectedLandmark = landmark
        updateSubtitleText()
        replaceTower()
    }

    private func presentLearningCategoryPicker() {
        guard let presenter = presentingViewController() else { return }

        let alert = UIAlertController(title: "选择学习主题", message: "适合 4 岁儿童的图片词汇", preferredStyle: .actionSheet)

        for (index, category) in learningCategories.enumerated() {
            let baseTitle = "\(category.icon) \(category.displayName) · \(category.englishName)"
            let title = index == selectedLearningCategoryIndex ? "\(baseTitle) ✓" : baseTitle
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applySelectedLearningCategory(index: index)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let popover = alert.popoverPresentationController, let sceneView = view {
            popover.sourceView = sceneView
            let anchorPoint = categoryButton?.position ?? CGPoint(x: size.width / 2, y: size.height * 0.1)
            let anchorInView = convertPoint(toView: anchorPoint)
            popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
            popover.permittedArrowDirections = [.up, .down]
        }

        presenter.present(alert, animated: true)
    }

    private func applySelectedLearningCategory(index: Int) {
        guard learningCategories.indices.contains(index) else { return }
        let category = learningCategories[index]
        speakEnglish(category.englishName)

        guard selectedLearningCategoryIndex != index else { return }

        selectedLearningCategoryIndex = index
        selectedDominoLearningItemIndices.removeAll()
        updateLearningThemeButtonTitle()
        updateSubtitleText()
        resetInteractiveElements()
    }
    
    private func replaceTower() {
        guard let layout = layout else { return }
        towerNode?.removeAllActions()
        towerNode?.removeFromParent()
        makeTower(layout: layout)
    }
    
    private func presentingViewController() -> UIViewController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let controller = current as? UIViewController {
                return controller
            }
            responder = current.next
        }
        return nil
    }
    
    private func touchedDomino(at location: CGPoint) -> DominoNode? {
        let nodesAtPoint = nodes(at: location)
        for node in nodesAtPoint {
            var current: SKNode? = node
            while let candidate = current {
                if let domino = candidate as? DominoNode {
                    return domino
                }
                current = candidate.parent
            }
        }
        return nil
    }
    
    private func currentLearningCategory() -> LearningCategory {
        guard !learningCategories.isEmpty else {
            return LearningCategory(
                icon: "🎯",
                displayName: "默认",
                englishName: "default",
                items: [LearningItem(icon: "⭐️", englishName: "star", chineseName: "星星", color: SKColor(red: 0.97, green: 0.80, blue: 0.28, alpha: 1.0))]
            )
        }

        if learningCategories.indices.contains(selectedLearningCategoryIndex) {
            return learningCategories[selectedLearningCategoryIndex]
        }

        selectedLearningCategoryIndex = 0
        return learningCategories[0]
    }

    private func learningItem(at index: Int) -> LearningItem? {
        let category = currentLearningCategory()
        guard category.items.indices.contains(index) else { return nil }
        return category.items[index]
    }

    private func presentDominoLearningPicker() {
        guard let targetDomino = selectedDominoNode else { return }
        guard let presenter = presentingViewController() else { return }

        let category = currentLearningCategory()
        let alert = UIAlertController(
            title: "选择图片与英语单词",
            message: "主题：\(category.icon)\(category.displayName)",
            preferredStyle: .actionSheet
        )

        for (index, item) in category.items.enumerated() {
            let baseTitle = "\(item.icon) \(item.englishName) (\(item.chineseName))"
            let title = index == targetDomino.colorOptionIndex ? "\(baseTitle) ✓" : baseTitle
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applySelectedDominoLearning(index: index, to: targetDomino)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let popover = alert.popoverPresentationController, let sceneView = view {
            popover.sourceView = sceneView
            let anchorInView = convertPoint(toView: targetDomino.position)
            popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
            popover.permittedArrowDirections = [.up, .down]
        }

        presenter.present(alert, animated: true)
    }

    private func applySelectedDominoLearning(index: Int, to domino: DominoNode) {
        guard let item = learningItem(at: index) else { return }
        speakEnglish(item.englishName)

        guard domino.colorOptionIndex != index else {
            persistDominoLearningSelection(for: domino, itemIndex: index)
            selectedDominoNode = nil
            return
        }

        domino.updateColor(item.color, colorOptionIndex: index, learningIcon: item.icon)
        persistDominoLearningSelection(for: domino, itemIndex: index)
        selectedDominoNode = nil
    }

    private func presentBallColorPicker() {
        guard let ballNode else { return }
        presentColorPicker(
            title: "选择小球颜色",
            message: "应用到当前小球",
            currentIndex: selectedBallColorOptionIndex,
            anchor: ballNode.position
        ) { [weak self] index in
            self?.applySelectedBallColor(index: index)
        }
    }

    private func applySelectedBallColor(index: Int) {
        guard let option = colorOption(at: index) else { return }
        speakEnglish(option.englishName)
        guard selectedBallColorOptionIndex != index else { return }
        selectedBallColorOptionIndex = index

        guard let ballNode = ballNode else { return }
        ballNode.fillColor = option.color
        ballNode.strokeColor = ballStrokeColor(for: option.color)
    }

    private func presentGuideLineColorPicker(anchor: CGPoint) {
        guard staircaseNode != nil else { return }
        presentColorPicker(
            title: "选择引导线颜色",
            message: "应用到当前引导线",
            currentIndex: selectedGuideLineColorOptionIndex,
            anchor: anchor
        ) { [weak self] index in
            self?.applySelectedGuideLineColor(index: index)
        }
    }

    private func applySelectedGuideLineColor(index: Int) {
        guard let option = colorOption(at: index) else { return }
        speakEnglish(option.englishName)
        guard selectedGuideLineColorOptionIndex != index else { return }
        selectedGuideLineColorOptionIndex = index

        staircaseNode?.updateGuideColor(option.color)
    }

    private func currentBallColorOption() -> DominoColorOption {
        currentColorOption(for: &selectedBallColorOptionIndex, fallbackColor: GameConstants.Colors.ballFill)
    }

    private func currentGuideLineColorOption() -> DominoColorOption {
        currentColorOption(for: &selectedGuideLineColorOptionIndex, fallbackColor: GameConstants.Colors.buttonBlueFill)
    }

    private func presentColorPicker(
        title: String,
        message: String,
        currentIndex: Int,
        anchor: CGPoint,
        onSelect: @escaping (Int) -> Void
    ) {
        guard let presenter = presentingViewController() else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for (index, option) in dominoColorOptions.enumerated() {
            let optionTitle = index == currentIndex ? "\(option.name) ✓" : option.name
            let action = UIAlertAction(title: optionTitle, style: .default) { _ in
                onSelect(index)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let popover = alert.popoverPresentationController, let sceneView = view {
            popover.sourceView = sceneView
            let anchorInView = convertPoint(toView: anchor)
            popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
            popover.permittedArrowDirections = [.up, .down]
        }

        presenter.present(alert, animated: true)
    }

    private func colorOption(at index: Int) -> DominoColorOption? {
        guard dominoColorOptions.indices.contains(index) else { return nil }
        return dominoColorOptions[index]
    }

    private func currentColorOption(for selectedIndex: inout Int, fallbackColor: SKColor) -> DominoColorOption {
        guard !dominoColorOptions.isEmpty else {
            return DominoColorOption(name: "default", englishName: "default", color: fallbackColor)
        }

        guard dominoColorOptions.indices.contains(selectedIndex) else {
            selectedIndex = min(5, dominoColorOptions.count - 1)
            return dominoColorOptions[selectedIndex]
        }

        return dominoColorOptions[selectedIndex]
    }

    private func resolvedDominoLearningItemIndices() -> [Int] {
        let items = currentLearningCategory().items
        guard !items.isEmpty else {
            return Array(repeating: 0, count: GameConstants.Geometry.numDominos)
        }

        let fallbackIndices = (0..<GameConstants.Geometry.numDominos).map { $0 % items.count }

        guard selectedDominoLearningItemIndices.count == GameConstants.Geometry.numDominos else {
            selectedDominoLearningItemIndices = fallbackIndices
            return fallbackIndices
        }

        for (index, value) in selectedDominoLearningItemIndices.enumerated() where !items.indices.contains(value) {
            selectedDominoLearningItemIndices[index] = fallbackIndices[index]
        }

        return selectedDominoLearningItemIndices
    }

    private func persistDominoLearningSelection(for domino: DominoNode, itemIndex: Int) {
        guard let dominoIndex = dominos.firstIndex(where: { $0 === domino }) else { return }
        let currentIndices = resolvedDominoLearningItemIndices()
        guard currentIndices.indices.contains(dominoIndex) else { return }
        selectedDominoLearningItemIndices[dominoIndex] = itemIndex
    }

    private func speakEnglish(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.46
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0
        speechSynthesizer.speak(utterance)
    }

    private func ballStrokeColor(for fillColor: SKColor) -> SKColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard fillColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return GameConstants.Colors.ballStroke
        }

        let darkenFactor: CGFloat = 0.58
        return SKColor(
            red: max(0, red * darkenFactor),
            green: max(0, green * darkenFactor),
            blue: max(0, blue * darkenFactor),
            alpha: alpha
        )
    }
    
    // MARK: - Animations
    
    private func startAnimation() {
        guard !isAnimating, let layout = layout else { return }
        guard flowStateMachine.startSimulation() else { return }
        isAnimating = true
        removeAction(forKey: GameConstants.autoResetActionKey)
        removeAction(forKey: chainWatchdogActionKey)
        removeAction(forKey: firstImpactAssistActionKey)
        removeAction(forKey: firstImpactFallbackActionKey)
        towerNode?.removeAction(forKey: towerToppleActionKey)
        countdownLabel?.text = ""
        setButtonEnabled(startButton, enabled: false)
        // Disable settings while animating
        setButtonEnabled(resetButton, enabled: false)
        setButtonEnabled(landmarkButton, enabled: false)
        setButtonEnabled(categoryButton, enabled: false)

        // Reset domino physics states and ensure they are visible (in case last run exploded them).
        for domino in dominos {
            domino.isHidden = false
            domino.resetPhysicsState()
            domino.removeAllActions()
        }

        fallenCount = 0
        nudgeCount = 0
        lastProgressTime = CACurrentMediaTime()
        hasTriggeredExplosion = false
        firstImpactTelemetry.runID += 1
        firstImpactTelemetry.directAssistCount = 0
        firstImpactTelemetry.fallbackAssistCount = 0
        logger.info("Run \(self.firstImpactTelemetry.runID) started. landmark=\(self.selectedLandmark.englishName, privacy: .public)")

        let ballDuration = runBallReleaseSequence(layout: layout)

        // User requested deterministic behavior: once the ball reaches the ground,
        // it directly drives into the first domino.
        scheduleDirectFirstImpact(after: max(0, ballDuration + 0.05), layout: layout)
    }
    
    // MARK: - Physics Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        // Lightweight audio feedback (avoid spamming too much)
        let a = contact.bodyA.categoryBitMask
        let b = contact.bodyB.categoryBitMask

        let dominoHit = (a == GameConstants.Physics.domino || b == GameConstants.Physics.domino)
        guard dominoHit else { return }

        // Find a domino node and mark progress on meaningful contacts.
        if let dominoNode = (contact.bodyA.node?.parent as? DominoNode) ?? (contact.bodyB.node?.parent as? DominoNode) {
            if !dominoNode.hasPlayedHitSound {
                dominoNode.hasPlayedHitSound = true
                run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            }
            lastProgressTime = CACurrentMediaTime()
        }
    }

    // MARK: - Particle Optimization (SKEmitterNode)
    
    private func explodeScene() {
        guard !hasTriggeredExplosion else { return }
        hasTriggeredExplosion = true
        
        run(SKAction.playSoundFileNamed("explode.wav", waitForCompletion: false))
        
        let colors: [SKColor] = [
            GameConstants.Colors.dominos[0],
            GameConstants.Colors.dominos[1],
            GameConstants.Colors.dominos[2],
            GameConstants.Colors.dominos[3],
            GameConstants.Colors.dominos[4],
            GameConstants.Colors.towerBase,
            GameConstants.Colors.towerFlag
        ]
        let budget = explosionBudget()
        
        // Explode dominos
        for domino in dominos {
            domino.isHidden = true
            createExplosion(
                at: domino.position,
                color: domino.color,
                particleCount: Int.random(in: budget.particlesPerBurst),
                particleSpeed: budget.particleSpeed,
                includeSmoke: Int.random(in: 0...4) == 0
            )
        }
        
        // Explode tower using sampled points from the full tower bounds.
        // This avoids creating hundreds of emitters on complex landmarks and is stable on older iPads.
        if let tower = towerNode {
            let points = towerExplosionPoints(for: tower, limit: budget.maxTowerEmitters)
            tower.isHidden = true
            
            for point in points {
                let randomColor = colors.randomElement() ?? GameConstants.Colors.towerBase
                createExplosion(
                    at: point,
                    color: randomColor,
                    particleCount: Int.random(in: budget.particlesPerBurst),
                    particleSpeed: budget.particleSpeed,
                    includeSmoke: true
                )
            }
        }
    }
    
    private func createExplosion(at position: CGPoint, color: SKColor, particleCount: Int, particleSpeed: CGFloat, includeSmoke: Bool) {
        addExplosionFlash(at: position, color: color)
        
        let texture = resolvedExplosionParticleTexture()
        let lowHeight = size.height * 0.32
        let verticalLift = position.y < lowHeight ? max(size.height * 0.08, 26) : 0
        let elevatedPosition = CGPoint(x: position.x, y: min(position.y + verticalLift, size.height * 0.92))
        let burstHeight = max((layout?.baseDominoHeight ?? 40) * 0.65, size.height * 0.08)
        let burstOrigin = CGPoint(x: 0, y: burstHeight / 2)
        let burstRange = CGVector(dx: 18, dy: burstHeight * 1.1)
        
        // Core burst: bright, fast, short-lived.
        let coreEmitter = SKEmitterNode()
        coreEmitter.name = "explosionEmitter"
        coreEmitter.targetNode = self
        coreEmitter.particleTexture = texture
        coreEmitter.particleBirthRate = 380
        coreEmitter.numParticlesToEmit = max(2, Int(CGFloat(particleCount) * 0.7))
        coreEmitter.particleLifetime = 0.9
        coreEmitter.particleLifetimeRange = 0.25
        coreEmitter.particlePosition = burstOrigin
        coreEmitter.particlePositionRange = burstRange
        coreEmitter.emissionAngle = .pi / 2
        coreEmitter.emissionAngleRange = .pi * 2
        coreEmitter.particleSpeed = particleSpeed * 1.05
        coreEmitter.particleSpeedRange = particleSpeed * 0.65
        coreEmitter.yAcceleration = -480
        coreEmitter.particleAlpha = 1.0
        coreEmitter.particleAlphaRange = 0.2
        coreEmitter.particleAlphaSpeed = -1.15
        coreEmitter.particleScale = 0.065
        coreEmitter.particleScaleRange = 0.04
        coreEmitter.particleScaleSpeed = -0.04
        coreEmitter.particleRotationRange = .pi * 2
        coreEmitter.particleRotationSpeed = 9.0
        coreEmitter.particleBlendMode = .add
        coreEmitter.particleColor = color
        coreEmitter.particleColorBlendFactor = 1.0
        coreEmitter.position = elevatedPosition
        coreEmitter.zPosition = 34
        addChild(coreEmitter)
        
        // Debris burst: slower, lingering, less additive for depth.
        let debrisEmitter = SKEmitterNode()
        debrisEmitter.name = "explosionEmitter"
        debrisEmitter.targetNode = self
        debrisEmitter.particleTexture = texture
        debrisEmitter.particleBirthRate = 280
        debrisEmitter.numParticlesToEmit = max(2, Int(CGFloat(particleCount) * 0.55))
        debrisEmitter.particleLifetime = 1.6
        debrisEmitter.particleLifetimeRange = 0.45
        debrisEmitter.particlePosition = burstOrigin
        debrisEmitter.particlePositionRange = burstRange
        debrisEmitter.emissionAngle = .pi / 2
        debrisEmitter.emissionAngleRange = .pi * 2
        debrisEmitter.particleSpeed = particleSpeed * 0.55
        debrisEmitter.particleSpeedRange = particleSpeed * 0.35
        debrisEmitter.yAcceleration = -360
        debrisEmitter.particleAlpha = 0.7
        debrisEmitter.particleAlphaRange = 0.2
        debrisEmitter.particleAlphaSpeed = -0.4
        debrisEmitter.particleScale = 0.09
        debrisEmitter.particleScaleRange = 0.05
        debrisEmitter.particleScaleSpeed = -0.02
        debrisEmitter.particleRotationRange = .pi * 2
        debrisEmitter.particleRotationSpeed = 4.5
        debrisEmitter.particleBlendMode = .alpha
        debrisEmitter.particleColor = color
        debrisEmitter.particleColorBlendFactor = 0.9
        debrisEmitter.position = elevatedPosition
        debrisEmitter.zPosition = 33
        addChild(debrisEmitter)
        
        if includeSmoke {
            createSmokePlume(at: elevatedPosition)
        }
        
        let coreDuration = CGFloat(coreEmitter.particleLifetime + coreEmitter.particleLifetimeRange + 0.12)
        coreEmitter.run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(coreDuration)),
            SKAction.removeFromParent()
        ]))
        
        let debrisDuration = CGFloat(debrisEmitter.particleLifetime + debrisEmitter.particleLifetimeRange + 0.2)
        debrisEmitter.run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(debrisDuration)),
            SKAction.removeFromParent()
        ]))
    }
    
    private func addExplosionFlash(at position: CGPoint, color: SKColor) {
        let flash = SKShapeNode(circleOfRadius: 12)
        flash.name = "explosionEmitter"
        flash.fillColor = color.withAlphaComponent(0.9)
        flash.strokeColor = SKColor.white.withAlphaComponent(0.9)
        flash.lineWidth = 1.8
        flash.glowWidth = 8.0
        flash.alpha = 0
        flash.position = position
        flash.zPosition = 35
        addChild(flash)
        
        let appear = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.03),
            SKAction.scale(to: 1.35, duration: 0.03)
        ])
        let fadeOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.28),
            SKAction.scale(to: 3.4, duration: 0.28)
        ])
        flash.run(SKAction.sequence([appear, fadeOut, SKAction.removeFromParent()]))
    }
    
    private func createSmokePlume(at position: CGPoint) {
        let smoke = SKEmitterNode()
        smoke.name = "explosionEmitter"
        smoke.targetNode = self
        smoke.particleTexture = resolvedExplosionParticleTexture()
        
        smoke.particleBirthRate = 120
        smoke.numParticlesToEmit = Int.random(in: 8...12)
        smoke.particleLifetime = 2.1
        smoke.particleLifetimeRange = 0.55
        
        smoke.particlePosition = .zero
        smoke.particlePositionRange = CGVector(dx: 12, dy: 10)
        smoke.emissionAngle = .pi / 2
        smoke.emissionAngleRange = .pi / 3
        smoke.particleSpeed = 52
        smoke.particleSpeedRange = 26
        smoke.yAcceleration = 54
        
        smoke.particleAlpha = 0.32
        smoke.particleAlphaRange = 0.16
        smoke.particleAlphaSpeed = -0.15
        
        smoke.particleScale = 0.19
        smoke.particleScaleRange = 0.09
        smoke.particleScaleSpeed = 0.06
        
        smoke.particleColor = SKColor(white: 0.26, alpha: 1.0)
        smoke.particleColorBlendFactor = 1.0
        smoke.particleBlendMode = .alpha
        
        smoke.position = position
        smoke.zPosition = 32
        addChild(smoke)
        
        let duration = CGFloat(smoke.particleLifetime + smoke.particleLifetimeRange + 0.24)
        smoke.run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(duration)),
            SKAction.removeFromParent()
        ]))
    }
    
    private func explosionBudget() -> (maxTowerEmitters: Int, particlesPerBurst: ClosedRange<Int>, particleSpeed: CGFloat) {
        let lowMemoryDevice = ProcessInfo.processInfo.physicalMemory <= 3_500_000_000
        let reducedMode = lowMemoryDevice || ProcessInfo.processInfo.isLowPowerModeEnabled
        
        if reducedMode {
            return (maxTowerEmitters: 10, particlesPerBurst: 13...18, particleSpeed: 200)
        }
        return (maxTowerEmitters: 18, particlesPerBurst: 17...24, particleSpeed: 245)
    }
    
    private func towerExplosionPoints(for tower: SKNode, limit: Int) -> [CGPoint] {
        guard limit > 0 else { return [] }
        
        let frame = tower.calculateAccumulatedFrame()
        guard !frame.isNull, frame.width > 0, frame.height > 0 else { return [] }
        
        let columns = 4
        let rows = max(2, Int(ceil(Double(limit) / Double(columns))))
        var points: [CGPoint] = []
        points.reserveCapacity(limit)
        
        for row in 0..<rows {
            for column in 0..<columns {
                if points.count >= limit {
                    return points
                }
                
                let u = (CGFloat(column) + 0.5) / CGFloat(columns)
                let v = (CGFloat(row) + 0.5) / CGFloat(rows)
                let jitterX = CGFloat.random(in: -frame.width * 0.07...frame.width * 0.07)
                let jitterY = CGFloat.random(in: -frame.height * 0.04...frame.height * 0.04)
                
                points.append(
                    CGPoint(
                        x: frame.minX + frame.width * u + jitterX,
                        y: frame.minY + frame.height * v + jitterY
                    )
                )
            }
        }
        
        return points
    }
    
    // MARK: - Helpers
    
    private func gradientTexture(size: CGSize, colors: [UIColor]) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgColors = colors.map { $0.cgColor } as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: [0, 1]) else { return }
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: size.height),
                end: CGPoint(x: 0, y: 0),
                options: []
            )
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private func resolvedExplosionParticleTexture() -> SKTexture {
        if let cached = explosionParticleTexture {
            return cached
        }
        
        if let sparkImage = UIImage(named: "spark") {
            let texture = SKTexture(image: sparkImage)
            texture.filteringMode = .linear
            explosionParticleTexture = texture
            return texture
        }
        
        // Resource fallback: generate a small soft circular particle.
        let size = CGSize(width: 24, height: 24)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let colors = [
                UIColor.white.withAlphaComponent(1).cgColor,
                UIColor.white.withAlphaComponent(0).cgColor
            ] as CFArray
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                context.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 1,
                    endCenter: center,
                    endRadius: rect.width * 0.5,
                    options: [.drawsAfterEndLocation]
                )
            } else {
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fillEllipse(in: rect)
            }
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        explosionParticleTexture = texture
        return texture
    }
    
    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(max, value))
    }
    
    private func runBallReleaseSequence(layout: Layout) -> TimeInterval {
        guard let ballNode = ballNode, let staircase = staircaseNode else { return 0.6 }
        let pathPoints = staircase.rollPath
        guard pathPoints.count > 1 else { return 0.6 }
        
        var actions: [SKAction] = []
        var totalDuration: TimeInterval = 0
        
        // Ensure starting position is correct
        if let startPoint = pathPoints.first {
            ballNode.position = startPoint.position
            ballNode.zPosition = startPoint.zPosition
            ballNode.setScale(startPoint.scale)
        }
        
        for index in 1..<pathPoints.count {
            let point = pathPoints[index]
            let previous = pathPoints[index - 1]
            let dx = point.position.x - previous.position.x
            let dy = point.position.y - previous.position.y
            let distance = hypot(dx, dy)
            let segmentDuration = TimeInterval(clamp(distance / 190, min: 0.2, max: 0.34))
            let rollDuration = segmentDuration * 0.62
            let dropDuration = segmentDuration - rollDuration
            totalDuration += segmentDuration
            
            let edgePoint = CGPoint(
                x: previous.position.x + dx * 0.64,
                y: previous.position.y + dy * 0.32
            )
            
            let rollMove = SKAction.move(to: edgePoint, duration: rollDuration)
            rollMove.timingMode = .easeIn
            let rollSpin = SKAction.rotate(
                byAngle: -(hypot(edgePoint.x - previous.position.x, edgePoint.y - previous.position.y) / max(layout.ballRadius, 1)),
                duration: rollDuration
            )
            rollSpin.timingMode = .easeIn
            let rollScale = SKAction.scale(to: previous.scale * 1.02, duration: rollDuration * 0.7)
            rollScale.timingMode = .easeOut
            
            let dropMove = SKAction.move(to: point.position, duration: dropDuration)
            dropMove.timingMode = .easeOut
            let dropSpin = SKAction.rotate(
                byAngle: -(hypot(point.position.x - edgePoint.x, point.position.y - edgePoint.y) / max(layout.ballRadius, 1)) * 1.15,
                duration: dropDuration
            )
            dropSpin.timingMode = .easeOut
            let dropSquish = SKAction.sequence([
                SKAction.scaleX(to: point.scale * 1.07, y: point.scale * 0.93, duration: dropDuration * 0.45),
                SKAction.scale(to: point.scale, duration: dropDuration * 0.55)
            ])
            dropSquish.timingMode = .easeOut
            
            let changeZAtDrop = SKAction.run {
                ballNode.zPosition = point.zPosition
            }
            
            let segmentAction = SKAction.sequence([
                SKAction.group([rollMove, rollSpin, rollScale]),
                SKAction.group([dropMove, dropSpin, dropSquish, changeZAtDrop])
            ])
            
            if index == 1 {
                actions.append(SKAction.playSoundFileNamed("roll.wav", waitForCompletion: false))
            }
            
            actions.append(segmentAction)
        }
        
        ballNode.run(SKAction.sequence(actions))
        return totalDuration
    }
    
    private func startChainWatchdog() {
        let check = SKAction.run { [weak self] in
            self?.checkChainProgressAndNudgeIfNeeded()
        }
        let wait = SKAction.wait(forDuration: GameConstants.Physics.stallCheckInterval)
        let loop = SKAction.repeatForever(SKAction.sequence([check, wait]))
        run(loop, withKey: chainWatchdogActionKey)
    }

    private func scheduleDirectFirstImpact(after delay: TimeInterval, layout: Layout) {
        let action = SKAction.sequence([
            SKAction.wait(forDuration: max(0, delay)),
            SKAction.run { [weak self] in
                guard let self else { return }
                guard self.isAnimating else { return }
                guard let ball = self.ballNode else { return }
                guard let firstDomino = self.dominos.first else { return }

                let firstDominoLeftEdge = firstDomino.position.x - firstDomino.width
                let releasePosition = CGPoint(
                    x: firstDominoLeftEdge - layout.ballRadius * 1.02,
                    y: layout.groundY + layout.ballRadius
                )

                ball.removeAllActions()
                ball.position = releasePosition
                ball.setScale(1.0)
                ball.zPosition = 3

                guard let ballBody = ball.physicsBody else { return }
                
                // 恢复碰撞检测
                ballBody.collisionBitMask = GameConstants.Physics.domino | GameConstants.Physics.ground | GameConstants.Physics.tower
                ballBody.contactTestBitMask = GameConstants.Physics.domino | GameConstants.Physics.ground
                
                ballBody.isDynamic = true
                ballBody.isResting = false
                ballBody.velocity = .zero
                ballBody.angularVelocity = 0
                ballBody.velocity = CGVector(dx: layout.ballRadius * 8.0, dy: 0)
                ballBody.applyImpulse(CGVector(dx: layout.ballRadius * 0.4, dy: 0))
                ballBody.applyAngularImpulse(-0.01)

                // Give the first domino a manual tip so it gracefully falls and starts the chain
                if let firstBody = firstDomino.physicsBodyForSimulation {
                    firstBody.isResting = false
                    // 加大角冲量和推力，确保100%击倒
                    firstBody.applyAngularImpulse(-0.06)
                    firstBody.applyImpulse(CGVector(dx: 2.0, dy: 0), at: CGPoint(x: -firstDomino.width / 2, y: firstDomino.height * 0.8))
                }

                self.firstImpactTelemetry.directAssistCount += 1
                let transitioned = self.flowStateMachine.markFirstImpact()
                if transitioned {
                    self.logger.info("Run \(self.firstImpactTelemetry.runID) direct first-impact assist fired.")
                } else {
                    let stateDescription = String(describing: self.flowStateMachine.state)
                    self.logger.debug("Run \(self.firstImpactTelemetry.runID) first-impact transition skipped (state=\(stateDescription, privacy: .public)).")
                }

                self.lastProgressTime = CACurrentMediaTime()
                if self.action(forKey: self.chainWatchdogActionKey) == nil {
                    self.startChainWatchdog()
                }

                // Safety net: if the first tile still doesn't move, give it a tiny push.
                self.scheduleFirstImpactFallback(layout: layout)
            }
        ])
        run(action, withKey: firstImpactAssistActionKey)
    }

    private func scheduleFirstImpactFallback(layout: Layout) {
        let fallback = SKAction.sequence([
            SKAction.wait(forDuration: 0.16),
            SKAction.run { [weak self] in
                guard let self else { return }
                guard self.isAnimating else { return }
                guard let firstDomino = self.dominos.first else { return }
                guard !firstDomino.hasFallen else { return }
                guard let firstBody = firstDomino.physicsBodyForSimulation else { return }

                let stillStuck = abs(firstBody.angularVelocity) < 0.22 && abs(firstBody.velocity.dx) < layout.ballRadius * 1.4
                guard stillStuck else { return }

                firstBody.isResting = false
                firstBody.applyImpulse(CGVector(dx: layout.ballRadius * 0.48, dy: 0))
                firstBody.applyAngularImpulse(-0.055)
                self.firstImpactTelemetry.fallbackAssistCount += 1
                self.logger.notice("Run \(self.firstImpactTelemetry.runID) fallback first-impact assist fired.")
                self.lastProgressTime = CACurrentMediaTime()
            }
        ])
        run(fallback, withKey: firstImpactFallbackActionKey)
    }

    private func checkChainProgressAndNudgeIfNeeded() {
        guard isAnimating else { return }
        let now = CACurrentMediaTime()
        
        // Mark new fallen tiles (angle threshold) even if no contact fired.
        for domino in dominos {
            if domino.evaluateFallenIfNeeded() {
                fallenCount += 1
                lastProgressTime = now
                // Stronger feedback on actual fall.
                run(SKAction.playSoundFileNamed("hit.wav", waitForCompletion: false))
            }
        }

        let stalled = (now - lastProgressTime) >= GameConstants.Physics.stallTimeout
        guard stalled else {
            // If we finished, end run.
            if fallenCount >= dominos.count {
                finishAfterChain()
            }
            return
        }

        if fallenCount >= dominos.count {
            finishAfterChain()
            return
        }

        guard nudgeCount < GameConstants.Physics.maxNudges else {
            // Hard-stop: still allow finish by time (or keep waiting). We choose to finish.
            finishAfterChain()
            return
        }

        // Nudge the next standing domino a tiny bit to keep the chain going (kid-friendly reliability).
        if let target = dominos.first(where: { !$0.hasFallen }) {
            nudgeCount += 1
            lastProgressTime = now

            // Apply impulses to the underlying sprite physics body.
            if let body = target.physicsBodyForSimulation {
                body.applyAngularImpulse(GameConstants.Physics.nudgeAngularImpulse)
                body.applyImpulse(CGVector(dx: GameConstants.Physics.nudgeLinearImpulseX, dy: 0))
            }
        }
    }

    private func finishAfterChain() {
        removeAction(forKey: chainWatchdogActionKey)
        removeAction(forKey: firstImpactAssistActionKey)
        removeAction(forKey: firstImpactFallbackActionKey)
        isAnimating = false
        logger.info(
            "Run \(self.firstImpactTelemetry.runID) finished. fallen=\(self.fallenCount), directAssist=\(self.firstImpactTelemetry.directAssistCount), fallbackAssist=\(self.firstImpactTelemetry.fallbackAssistCount)"
        )
        setButtonEnabled(resetButton, enabled: true)
        setButtonEnabled(landmarkButton, enabled: true)
        setButtonEnabled(categoryButton, enabled: true)

        let completeSequence = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.explodeScene()
            },
            SKAction.wait(forDuration: 3.0),
            SKAction.run { [weak self] in
                self?.startAutoResetCountdown(seconds: GameConstants.Geometry.autoResetDelay)
            }
        ])

        guard let tower = towerNode else {
            run(completeSequence, withKey: GameConstants.autoResetActionKey)
            return
        }

        tower.removeAction(forKey: towerToppleActionKey)
        let topple = SKAction.rotate(toAngle: -CGFloat.pi * 86 / 180, duration: 1.15)
        topple.timingMode = .easeIn
        let settle = SKAction.wait(forDuration: 0.1)
        let done = SKAction.run { [weak self] in
            self?.run(completeSequence, withKey: GameConstants.autoResetActionKey)
        }
        tower.run(SKAction.sequence([topple, settle, done]), withKey: towerToppleActionKey)
    }

    private func startAutoResetCountdown(seconds: Int) {
        guard seconds > 0 else { return }
        guard flowStateMachine.startAutoResetCountdown(seconds: seconds) else {
            let stateDescription = String(describing: flowStateMachine.state)
            logger.error("Run \(self.firstImpactTelemetry.runID) could not start countdown from state=\(stateDescription, privacy: .public).")
            return
        }

        var actions: [SKAction] = []
        for _ in stride(from: seconds, through: 1, by: -1) {
            actions.append(SKAction.run { [weak self] in
                guard let self else { return }
                guard let value = self.flowStateMachine.countdownSecondsRemaining else { return }
                self.countdownLabel?.isHidden = false
                self.countdownLabel?.text = "自动重置 \(value)s"
            })
            actions.append(SKAction.wait(forDuration: 1))
            actions.append(SKAction.run { [weak self] in
                _ = self?.flowStateMachine.tickCountdown()
            })
        }
        actions.append(SKAction.run { [weak self] in
            self?.countdownLabel?.text = ""
            self?.countdownLabel?.isHidden = true
            self?.resetScene()
        })
        run(SKAction.sequence(actions), withKey: GameConstants.autoResetActionKey)
    }
}
