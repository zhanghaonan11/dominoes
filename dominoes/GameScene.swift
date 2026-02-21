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
        let color: SKColor
    }

    private struct FirstImpactTelemetry {
        var runID: Int = 0
        var directAssistCount: Int = 0
        var fallbackAssistCount: Int = 0
    }

    private enum LearningMode: CaseIterable {
        case learning
        case challenge

        var title: String {
            switch self {
            case .learning:
                return "学习模式"
            case .challenge:
                return "挑战模式"
            }
        }
    }

    private enum DifficultyLevel: Int, CaseIterable {
        case l1 = 1
        case l2
        case l3
        case l4

        var title: String {
            switch self {
            case .l1:
                return "L1 字母"
            case .l2:
                return "L2 单词"
            case .l3:
                return "L3 短语"
            case .l4:
                return "L4 句型"
            }
        }
    }

    private enum MatchingRule: CaseIterable {
        case imageToWord
        case audioToWord
        case wordToMeaning

        var title: String {
            switch self {
            case .imageToWord:
                return "图-词匹配"
            case .audioToWord:
                return "词-音匹配"
            case .wordToMeaning:
                return "词-词组匹配"
            }
        }
    }

    private struct VocabularyItem: Hashable {
        let emoji: String
        let word: String
        let meaning: String
        let phrase: String
        let sentence: String
    }

    private enum LearningTheme: CaseIterable {
        case animals
        case colors
        case foods
        case family
        case transport

        var title: String {
            switch self {
            case .animals:
                return "动物"
            case .colors:
                return "颜色"
            case .foods:
                return "食物"
            case .family:
                return "家庭"
            case .transport:
                return "交通"
            }
        }

        var icon: String {
            switch self {
            case .animals:
                return "🐾"
            case .colors:
                return "🎨"
            case .foods:
                return "🍎"
            case .family:
                return "🏠"
            case .transport:
                return "🚗"
            }
        }

        var vocabulary: [VocabularyItem] {
            switch self {
            case .animals:
                return [
                    VocabularyItem(emoji: "🐶", word: "dog", meaning: "狗", phrase: "a happy dog", sentence: "The dog can run."),
                    VocabularyItem(emoji: "🐱", word: "cat", meaning: "猫", phrase: "a cute cat", sentence: "The cat is small."),
                    VocabularyItem(emoji: "🐰", word: "rabbit", meaning: "兔子", phrase: "a white rabbit", sentence: "A rabbit can jump."),
                    VocabularyItem(emoji: "🐼", word: "panda", meaning: "熊猫", phrase: "a giant panda", sentence: "The panda eats bamboo."),
                    VocabularyItem(emoji: "🦁", word: "lion", meaning: "狮子", phrase: "a brave lion", sentence: "The lion is strong."),
                    VocabularyItem(emoji: "🐵", word: "monkey", meaning: "猴子", phrase: "a funny monkey", sentence: "The monkey climbs trees."),
                    VocabularyItem(emoji: "🐘", word: "elephant", meaning: "大象", phrase: "a big elephant", sentence: "An elephant has a trunk."),
                    VocabularyItem(emoji: "🐦", word: "bird", meaning: "鸟", phrase: "a blue bird", sentence: "The bird can sing."),
                    VocabularyItem(emoji: "🐟", word: "fish", meaning: "鱼", phrase: "a small fish", sentence: "The fish swims fast."),
                    VocabularyItem(emoji: "🐯", word: "tiger", meaning: "老虎", phrase: "a wild tiger", sentence: "The tiger has stripes.")
                ]
            case .colors:
                return [
                    VocabularyItem(emoji: "🔴", word: "red", meaning: "红色", phrase: "a red ball", sentence: "My hat is red."),
                    VocabularyItem(emoji: "🟠", word: "orange", meaning: "橙色", phrase: "an orange kite", sentence: "This orange bag is new."),
                    VocabularyItem(emoji: "🟡", word: "yellow", meaning: "黄色", phrase: "a yellow sun", sentence: "The sun looks yellow."),
                    VocabularyItem(emoji: "🟢", word: "green", meaning: "绿色", phrase: "green leaves", sentence: "The grass is green."),
                    VocabularyItem(emoji: "🔵", word: "blue", meaning: "蓝色", phrase: "a blue sky", sentence: "The sky is blue."),
                    VocabularyItem(emoji: "🟣", word: "purple", meaning: "紫色", phrase: "a purple flower", sentence: "She likes purple shoes."),
                    VocabularyItem(emoji: "🟤", word: "brown", meaning: "棕色", phrase: "a brown bear", sentence: "The table is brown."),
                    VocabularyItem(emoji: "⚫️", word: "black", meaning: "黑色", phrase: "a black cat", sentence: "My shoes are black."),
                    VocabularyItem(emoji: "⚪️", word: "white", meaning: "白色", phrase: "a white cloud", sentence: "The cloud is white."),
                    VocabularyItem(emoji: "🩷", word: "pink", meaning: "粉色", phrase: "a pink dress", sentence: "The toy is pink.")
                ]
            case .foods:
                return [
                    VocabularyItem(emoji: "🍎", word: "apple", meaning: "苹果", phrase: "an apple", sentence: "I eat an apple."),
                    VocabularyItem(emoji: "🍌", word: "banana", meaning: "香蕉", phrase: "a banana", sentence: "The banana is sweet."),
                    VocabularyItem(emoji: "🍞", word: "bread", meaning: "面包", phrase: "warm bread", sentence: "We have bread for breakfast."),
                    VocabularyItem(emoji: "🥚", word: "egg", meaning: "鸡蛋", phrase: "a boiled egg", sentence: "I can cook an egg."),
                    VocabularyItem(emoji: "🥛", word: "milk", meaning: "牛奶", phrase: "a cup of milk", sentence: "Drink milk every day."),
                    VocabularyItem(emoji: "🍚", word: "rice", meaning: "米饭", phrase: "a bowl of rice", sentence: "We eat rice at dinner."),
                    VocabularyItem(emoji: "🥕", word: "carrot", meaning: "胡萝卜", phrase: "a carrot", sentence: "The rabbit likes carrots."),
                    VocabularyItem(emoji: "🍅", word: "tomato", meaning: "西红柿", phrase: "a red tomato", sentence: "Tomatoes are juicy."),
                    VocabularyItem(emoji: "🍓", word: "strawberry", meaning: "草莓", phrase: "fresh strawberry", sentence: "I pick a strawberry."),
                    VocabularyItem(emoji: "🍕", word: "pizza", meaning: "披萨", phrase: "hot pizza", sentence: "Pizza smells good.")
                ]
            case .family:
                return [
                    VocabularyItem(emoji: "👨", word: "father", meaning: "爸爸", phrase: "my father", sentence: "My father is kind."),
                    VocabularyItem(emoji: "👩", word: "mother", meaning: "妈妈", phrase: "my mother", sentence: "My mother can cook."),
                    VocabularyItem(emoji: "👦", word: "brother", meaning: "哥哥/弟弟", phrase: "my brother", sentence: "My brother plays ball."),
                    VocabularyItem(emoji: "👧", word: "sister", meaning: "姐姐/妹妹", phrase: "my sister", sentence: "My sister reads books."),
                    VocabularyItem(emoji: "👴", word: "grandpa", meaning: "爷爷/外公", phrase: "my grandpa", sentence: "Grandpa tells stories."),
                    VocabularyItem(emoji: "👵", word: "grandma", meaning: "奶奶/外婆", phrase: "my grandma", sentence: "Grandma gives me hugs."),
                    VocabularyItem(emoji: "👶", word: "baby", meaning: "宝宝", phrase: "a baby", sentence: "The baby is sleeping."),
                    VocabularyItem(emoji: "🏠", word: "home", meaning: "家", phrase: "my home", sentence: "I love my home."),
                    VocabularyItem(emoji: "🛏️", word: "bedroom", meaning: "卧室", phrase: "a bedroom", sentence: "This is my bedroom."),
                    VocabularyItem(emoji: "🍽️", word: "kitchen", meaning: "厨房", phrase: "the kitchen", sentence: "We cook in the kitchen.")
                ]
            case .transport:
                return [
                    VocabularyItem(emoji: "🚗", word: "car", meaning: "汽车", phrase: "a fast car", sentence: "The car is red."),
                    VocabularyItem(emoji: "🚌", word: "bus", meaning: "公交车", phrase: "a school bus", sentence: "I go by bus."),
                    VocabularyItem(emoji: "🚲", word: "bike", meaning: "自行车", phrase: "a small bike", sentence: "I ride my bike."),
                    VocabularyItem(emoji: "🚆", word: "train", meaning: "火车", phrase: "a long train", sentence: "The train is on time."),
                    VocabularyItem(emoji: "✈️", word: "plane", meaning: "飞机", phrase: "a big plane", sentence: "The plane flies high."),
                    VocabularyItem(emoji: "🚢", word: "ship", meaning: "轮船", phrase: "a large ship", sentence: "The ship is on the sea."),
                    VocabularyItem(emoji: "🚕", word: "taxi", meaning: "出租车", phrase: "a yellow taxi", sentence: "The taxi stops here."),
                    VocabularyItem(emoji: "🚒", word: "fire truck", meaning: "消防车", phrase: "a fire truck", sentence: "The fire truck is loud."),
                    VocabularyItem(emoji: "🚁", word: "helicopter", meaning: "直升机", phrase: "a helicopter", sentence: "The helicopter can hover."),
                    VocabularyItem(emoji: "🚜", word: "tractor", meaning: "拖拉机", phrase: "a green tractor", sentence: "The tractor works on farms.")
                ]
            }
        }
    }

    private enum LearningRoundStage {
        case waitingToStart
        case matching
        case readyForChain
        case chainRunning
    }

    private struct DominoLearningCard {
        let pairID: Int
        let primaryText: String
        let secondaryText: String?
        let shouldSpeakOnTap: Bool
        let spokenText: String?
        let item: VocabularyItem
    }
    
    private var layout: Layout?
    private var dominos: [DominoNode] = []
    
    // Core Elements
    private var ballNode: SKShapeNode?
    private var towerNode: SKNode?
    private var startButton: SKShapeNode?
    private var resetButton: SKShapeNode?
    private var landmarkButton: SKShapeNode?
    private var subtitleLabel: SKLabelNode?
    private var countdownLabel: SKLabelNode?
    private var statusLabel: SKLabelNode?
    private var progressLabel: SKLabelNode?
    private var modeEntryNode: SKNode?
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
    
    private var selectedLandmark: TowerNode.Landmark = .eiffelTower
    private var selectedDominoNode: DominoNode?
    private var selectedBallColorOptionIndex = 5
    private var selectedGuideLineColorOptionIndex = 5
    private var hasSelectedModeEntry = false
    private var learningMode: LearningMode = .learning
    private var selectedTheme: LearningTheme = .animals
    private var selectedRule: MatchingRule = .imageToWord
    private var selectedLevel: DifficultyLevel = .l1
    private var noPressureMode = true
    private var learningRoundStage: LearningRoundStage = .waitingToStart
    private var roundCards: [DominoLearningCard] = []
    private var cardByDominoID: [ObjectIdentifier: DominoLearningCard] = [:]
    private var selectedDominoPair: [DominoNode] = []
    private var matchedPairIDs: Set<Int> = []
    private var pendingReviewItems: Set<VocabularyItem> = []
    private var forceReviewRound = false
    private var masteredWords: Set<String> = []
    private var roundCorrectCount = 0
    private var roundWrongCount = 0
    private var roundStartTimestamp: TimeInterval = 0
    private var lastRoundStars = 0
    private var totalStars = 0
    private var completedRounds = 0
    private var totalStudyDuration: TimeInterval = 0
    private var currentStreakDays = 1
    private var flowStateMachine = GameFlowStateMachine()
    private var firstImpactTelemetry = FirstImpactTelemetry()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "wipo.dominoes", category: "Simulation")
    
    private let dominoColorOptions: [DominoColorOption] = [
        DominoColorOption(name: "🟥 red", color: SKColor(red: 0.90, green: 0.18, blue: 0.19, alpha: 1.0)),
        DominoColorOption(name: "🟧 orange", color: SKColor(red: 0.97, green: 0.49, blue: 0.13, alpha: 1.0)),
        DominoColorOption(name: "🟨 yellow", color: SKColor(red: 0.95, green: 0.78, blue: 0.17, alpha: 1.0)),
        DominoColorOption(name: "🟩 green", color: SKColor(red: 0.12, green: 0.72, blue: 0.39, alpha: 1.0)),
        DominoColorOption(name: "🟦 cyan", color: SKColor(red: 0.08, green: 0.71, blue: 0.68, alpha: 1.0)),
        DominoColorOption(name: "🟦 blue", color: SKColor(red: 0.18, green: 0.55, blue: 0.96, alpha: 1.0)),
        DominoColorOption(name: "🟦 navy", color: SKColor(red: 0.12, green: 0.33, blue: 0.76, alpha: 1.0)),
        DominoColorOption(name: "🟪 purple", color: SKColor(red: 0.57, green: 0.31, blue: 0.89, alpha: 1.0)),
        DominoColorOption(name: "🩷 pink", color: SKColor(red: 0.90, green: 0.23, blue: 0.59, alpha: 1.0)),
        DominoColorOption(name: "⬛ black", color: SKColor(red: 0.22, green: 0.24, blue: 0.29, alpha: 1.0))
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
        case "entryLearningMode":
            applySelectedLearningMode(.learning, shouldResetRound: true)
        case "entryChallengeMode":
            applySelectedLearningMode(.challenge, shouldResetRound: true)
        case "dominoTarget":
            guard !isAnimating else { return }
            guard let domino = touchedDomino(at: location) else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            handleDominoTap(domino)
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
            handleStartButtonTapped()
        case "landmarkButton":
            guard landmarkButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentLearningSetupMenu()
        case "towerTarget":
            guard landmarkButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentLandmarkPicker()
        case "resetButton":
            guard resetButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentParentPanel()
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
        makeLearningHUD()
        
        makeButtons()
        makeCountdownLabel()
        makeModeEntryOverlay()
        
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
        learningRoundStage = .waitingToStart
        selectedDominoPair.removeAll()
        matchedPairIDs.removeAll()
        cardByDominoID.removeAll()
        roundCorrectCount = 0
        roundWrongCount = 0
        roundStartTimestamp = 0
        lastRoundStars = 0
        flowStateMachine.resetToIdle()
        roundCards = buildRoundCards()
        
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
        
        updateSubtitleText()
        updateProgressText()

        if hasSelectedModeEntry {
            setButtonEnabled(resetButton, enabled: true)
            setButtonEnabled(startButton, enabled: true)
            setButtonEnabled(landmarkButton, enabled: true)
            updateStartButtonTitle("开始配对")
            updateStatusText("点击“开始配对”，完成后解锁推倒奖励。")
            modeEntryNode?.removeFromParent()
        } else {
            setButtonEnabled(resetButton, enabled: false)
            setButtonEnabled(startButton, enabled: false)
            setButtonEnabled(landmarkButton, enabled: false)
            updateStartButtonTitle("先选模式")
            updateStatusText("先选择“学习模式”或“挑战模式”。")
            makeModeEntryOverlay()
        }
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
        let dominoWidth = clamp(sceneWidth * 0.022, min: 14, max: 24)
        let baseDominoHeight = sceneHeight * 0.11
        let heightIncrement = sceneHeight * 0.013
        
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
        label.text = "多米诺英语启蒙"
        label.fontSize = 28
        label.fontColor = GameConstants.Colors.textTitle
        label.position = CGPoint(x: size.width / 2, y: currentLayout.titleY)
        label.zPosition = 5
        return label
    }
    
    private func makeSubtitle() -> SKLabelNode {
        let currentLayout = layout ?? makeLayout(for: size)
        let label = SKLabelNode(fontNamed: "AvenirNext-Regular")
        label.text = subtitleText()
        label.fontSize = 14
        label.fontColor = GameConstants.Colors.textSubtitle
        label.position = CGPoint(x: size.width / 2, y: currentLayout.subtitleY)
        label.zPosition = 5
        return label
    }
    
    private func subtitleText() -> String {
        let mode = hasSelectedModeEntry ? learningMode.title : "待选择"
        return "\(selectedTheme.icon) \(selectedTheme.title) · \(selectedRule.title) · \(selectedLevel.title) · \(mode)"
    }
    
    private func updateSubtitleText() {
        subtitleLabel?.text = subtitleText()
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
        
        for index in 0..<GameConstants.Geometry.numDominos {
            let x = layout.startX + CGFloat(index) * spacing
            let height = layout.baseDominoHeight + CGFloat(index) * layout.heightIncrement
            let colorOptionIndex = index % dominoColorOptions.count
            let color = dominoColorOptions[colorOptionIndex].color
            
            let domino = DominoNode(
                color: color,
                colorOptionIndex: colorOptionIndex,
                xPosition: x,
                width: layout.dominoWidth,
                height: height,
                texture: dominoTexture
            )
            domino.position = CGPoint(x: x + layout.dominoWidth, y: layout.groundY)
            domino.zPosition = 3
            domino.name = "dominoTarget"
            domino.configurePhysics()

            if roundCards.indices.contains(index) {
                let card = roundCards[index]
                let content = DominoNode.LearningContent(
                    primaryText: card.primaryText,
                    secondaryText: card.secondaryText,
                    shouldSpeakOnTap: card.shouldSpeakOnTap,
                    spokenText: card.spokenText
                )
                domino.updateLearningContent(content)
                cardByDominoID[ObjectIdentifier(domino)] = card
            } else {
                domino.clearLearningContent()
            }
            
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
        let spacing: CGFloat = currentLayout.isWide ? 14 : 10
        let horizontalPadding: CGFloat = currentLayout.isWide ? 48 : 24
        let preferredWidth: CGFloat = currentLayout.isWide ? 150 : 112
        let buttonWidth = min(preferredWidth, (size.width - horizontalPadding - 2 * spacing) / 3)
        
        let start = makeButton(
            name: "startButton",
            title: "开始配对",
            fillColor: GameConstants.Colors.buttonBlueFill,
            textColor: GameConstants.Colors.buttonBlueText,
            layout: currentLayout,
            width: buttonWidth
        )
        let landmark = makeButton(
            name: "landmarkButton",
            title: "词库规则",
            fillColor: SKColor(red: 0.20, green: 0.70, blue: 0.66, alpha: 1.0),
            textColor: SKColor.white,
            layout: currentLayout,
            width: buttonWidth
        )
        let reset = makeButton(
            name: "resetButton",
            title: "家长面板",
            fillColor: GameConstants.Colors.buttonGrayFill,
            textColor: GameConstants.Colors.buttonGrayText,
            layout: currentLayout,
            width: buttonWidth
        )
        
        let totalWidth = 3 * start.frame.width + 2 * spacing
        let startX = (size.width - totalWidth) / 2 + start.frame.width / 2
        let y = currentLayout.buttonY
        
        start.position = CGPoint(x: startX, y: y)
        landmark.position = CGPoint(x: startX + start.frame.width + spacing, y: y)
        reset.position = CGPoint(x: startX + 2 * (start.frame.width + spacing), y: y)
        
        addChild(start)
        addChild(landmark)
        addChild(reset)
        startButton = start
        landmarkButton = landmark
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

    private var totalPairCount: Int {
        max(1, roundCards.count / 2)
    }

    private func makeLearningHUD() {
        let currentLayout = layout ?? makeLayout(for: size)

        let status = SKLabelNode(fontNamed: "AvenirNext-Medium")
        status.text = ""
        status.fontSize = 14
        status.fontColor = SKColor(white: 0.2, alpha: 0.95)
        status.position = CGPoint(x: size.width / 2, y: currentLayout.subtitleY - 20)
        status.zPosition = 7
        addChild(status)
        statusLabel = status

        let progress = SKLabelNode(fontNamed: "AvenirNext-Regular")
        progress.text = ""
        progress.fontSize = 13
        progress.fontColor = SKColor(white: 0.26, alpha: 0.92)
        progress.position = CGPoint(x: size.width / 2, y: currentLayout.subtitleY - 40)
        progress.zPosition = 7
        addChild(progress)
        progressLabel = progress
    }

    private func makeModeEntryOverlay() {
        guard !hasSelectedModeEntry else {
            modeEntryNode?.removeFromParent()
            return
        }

        modeEntryNode?.removeFromParent()
        let container = SKNode()
        container.zPosition = 40

        let dim = SKShapeNode(rectOf: size, cornerRadius: 0)
        dim.fillColor = SKColor(white: 0.0, alpha: 0.18)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(dim)

        let panelSize = CGSize(width: min(size.width * 0.78, 420), height: 216)
        let panel = SKShapeNode(rectOf: panelSize, cornerRadius: 24)
        panel.fillColor = SKColor(white: 1.0, alpha: 0.95)
        panel.strokeColor = SKColor(white: 0.85, alpha: 1.0)
        panel.lineWidth = 1
        panel.position = CGPoint(x: size.width / 2, y: size.height * 0.54)
        container.addChild(panel)

        let title = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        title.text = "选择模式"
        title.fontSize = 22
        title.fontColor = SKColor(white: 0.15, alpha: 1)
        title.position = CGPoint(x: 0, y: 74)
        panel.addChild(title)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Regular")
        subtitle.text = "学习模式更温和，挑战模式更紧凑"
        subtitle.fontSize = 14
        subtitle.fontColor = SKColor(white: 0.35, alpha: 1)
        subtitle.position = CGPoint(x: 0, y: 44)
        panel.addChild(subtitle)

        let optionSize = CGSize(width: panelSize.width * 0.40, height: 60)
        let learningButton = makeModeEntryButton(
            name: "entryLearningMode",
            title: "学习模式",
            fillColor: SKColor(red: 0.20, green: 0.70, blue: 0.66, alpha: 1.0),
            size: optionSize
        )
        learningButton.position = CGPoint(x: -panelSize.width * 0.24, y: -18)
        panel.addChild(learningButton)

        let challengeButton = makeModeEntryButton(
            name: "entryChallengeMode",
            title: "挑战模式",
            fillColor: SKColor(red: 0.95, green: 0.53, blue: 0.28, alpha: 1.0),
            size: optionSize
        )
        challengeButton.position = CGPoint(x: panelSize.width * 0.24, y: -18)
        panel.addChild(challengeButton)

        addChild(container)
        modeEntryNode = container
    }

    private func makeModeEntryButton(name: String, title: String, fillColor: SKColor, size: CGSize) -> SKShapeNode {
        let button = SKShapeNode(rectOf: size, cornerRadius: 16)
        button.name = name
        button.fillColor = fillColor
        button.strokeColor = fillColor
        button.lineWidth = 0

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = title
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = name
        button.addChild(label)
        return button
    }

    private func updateButtonTitle(_ button: SKShapeNode?, text: String) {
        guard let button else { return }
        guard let label = button.children.compactMap({ $0 as? SKLabelNode }).first else { return }
        label.text = text
    }

    private func updateStartButtonTitle(_ title: String) {
        updateButtonTitle(startButton, text: title)
    }

    private func updateStatusText(_ text: String) {
        statusLabel?.text = text
    }

    private func updateProgressText() {
        let modeText = hasSelectedModeEntry ? learningMode.title : "待选择"
        let progress = "配对 \(matchedPairIDs.count)/\(totalPairCount) · 错题 \(pendingReviewItems.count) · 已掌握 \(masteredWords.count) · ⭐️\(totalStars)"
        progressLabel?.text = "\(modeText) | \(progress)"
    }

    private func applySelectedLearningMode(_ mode: LearningMode, shouldResetRound: Bool) {
        learningMode = mode
        hasSelectedModeEntry = true
        noPressureMode = (mode == .learning)

        modeEntryNode?.removeFromParent()
        modeEntryNode = nil
        updateSubtitleText()

        if shouldResetRound {
            resetInteractiveElements()
        }
    }

    private func handleStartButtonTapped() {
        guard hasSelectedModeEntry else {
            updateStatusText("请先选择学习模式或挑战模式。")
            makeModeEntryOverlay()
            return
        }

        switch learningRoundStage {
        case .waitingToStart:
            beginMatchingRound()
        case .matching:
            updateStatusText("先完成全部配对，再触发推倒奖励。")
        case .readyForChain:
            startAnimation()
        case .chainRunning:
            break
        }
    }

    private func beginMatchingRound() {
        guard hasSelectedModeEntry else { return }
        guard !isAnimating else { return }

        learningRoundStage = .matching
        selectedDominoPair.removeAll()
        roundCorrectCount = 0
        roundWrongCount = 0
        roundStartTimestamp = CACurrentMediaTime()
        updateStartButtonTitle("配对进行中")
        updateStatusText("点击两张骨牌配对：\(selectedRule.title)")
        updateProgressText()
    }

    private func handleDominoTap(_ domino: DominoNode) {
        guard hasSelectedModeEntry else {
            updateStatusText("先选择模式，再开始配对。")
            makeModeEntryOverlay()
            return
        }

        guard !domino.isMatchedForLearning else { return }
        guard let card = cardByDominoID[ObjectIdentifier(domino)] else { return }

        if learningRoundStage == .waitingToStart {
            beginMatchingRound()
        }

        guard learningRoundStage == .matching else {
            if learningRoundStage == .readyForChain {
                updateStatusText("配对完成，点击“推倒奖励”开始连锁反应。")
            }
            return
        }

        if selectedDominoPair.contains(where: { $0 === domino }) {
            domino.setLearningSelectionActive(false)
            selectedDominoPair.removeAll { $0 === domino }
            return
        }

        domino.setLearningSelectionActive(true)
        selectedDominoPair.append(domino)

        if card.shouldSpeakOnTap, let spoken = card.spokenText {
            speak(spoken)
        }

        evaluateSelectedPairIfNeeded()
    }

    private func evaluateSelectedPairIfNeeded() {
        guard selectedDominoPair.count == 2 else { return }
        let first = selectedDominoPair[0]
        let second = selectedDominoPair[1]

        defer {
            selectedDominoPair.removeAll()
            updateProgressText()
        }

        guard
            let firstCard = cardByDominoID[ObjectIdentifier(first)],
            let secondCard = cardByDominoID[ObjectIdentifier(second)]
        else {
            first.setLearningSelectionActive(false)
            second.setLearningSelectionActive(false)
            return
        }

        if firstCard.pairID == secondCard.pairID {
            first.setLearningMatched(true)
            second.setLearningMatched(true)
            matchedPairIDs.insert(firstCard.pairID)
            roundCorrectCount += 1
            masteredWords.insert(firstCard.item.word)
            pendingReviewItems.remove(firstCard.item)
            pendingReviewItems.remove(secondCard.item)

            updateStatusText("配对成功：\(firstCard.item.word)")
            speak(encouragementText())

            if matchedPairIDs.count >= totalPairCount {
                finishMatchingRound()
            }
            return
        }

        roundWrongCount += 1
        pendingReviewItems.insert(firstCard.item)
        pendingReviewItems.insert(secondCard.item)

        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.52, duration: 0.08),
            SKAction.fadeAlpha(to: 1.0, duration: 0.12)
        ])
        first.run(blink)
        second.run(blink)
        first.setLearningSelectionActive(false)
        second.setLearningSelectionActive(false)

        if noPressureMode || learningMode == .learning {
            updateStatusText("再试一次：\(firstCard.item.word) = \(firstCard.item.meaning)")
        } else {
            updateStatusText("挑战模式：当前错误 \(roundWrongCount) 次")
        }
    }

    private func finishMatchingRound() {
        guard learningRoundStage == .matching else { return }
        learningRoundStage = .readyForChain

        let elapsed = max(0.5, CACurrentMediaTime() - roundStartTimestamp)
        totalStudyDuration += elapsed
        lastRoundStars = computeStarRating(elapsed: elapsed)
        totalStars += lastRoundStars
        completedRounds += 1

        let stars = String(repeating: "⭐️", count: lastRoundStars)
        updateStartButtonTitle("推倒奖励")
        updateStatusText("配对完成 \(stars)！点击“推倒奖励”触发连锁。")
        updateProgressText()
        speak("Great job")
    }

    private func computeStarRating(elapsed: TimeInterval) -> Int {
        let totalAttempts = max(1, roundCorrectCount + roundWrongCount)
        let accuracy = Double(roundCorrectCount) / Double(totalAttempts)
        let targetPerPair = learningMode == .challenge ? 4.2 : 5.6
        let timeScore = elapsed / Double(totalPairCount) <= targetPerPair

        if accuracy >= 0.90 && timeScore { return 3 }
        if accuracy >= 0.72 { return 2 }
        return 1
    }

    private func buildRoundCards() -> [DominoLearningCard] {
        let pairCount = max(1, GameConstants.Geometry.numDominos / 2)
        var pool = selectedVocabularyPool()
        var chosen: [VocabularyItem] = []

        let reviewCandidates = pendingReviewItems.filter { pool.contains($0) }.shuffled()
        let reviewCap = forceReviewRound ? pairCount : min(2, pairCount)
        for item in reviewCandidates.prefix(reviewCap) where !chosen.contains(item) {
            chosen.append(item)
        }

        pool.shuffle()
        for item in pool where chosen.count < pairCount {
            if !chosen.contains(item) {
                chosen.append(item)
            }
        }

        if chosen.count < pairCount {
            var fallback = selectedTheme.vocabulary.shuffled()
            while chosen.count < pairCount, let item = fallback.popLast() {
                if !chosen.contains(item) {
                    chosen.append(item)
                }
            }
        }

        forceReviewRound = false

        var cards: [DominoLearningCard] = []
        cards.reserveCapacity(pairCount * 2)
        for (pairID, item) in chosen.enumerated() {
            cards.append(contentsOf: cardsForVocabulary(item, pairID: pairID))
        }
        cards.shuffle()
        return cards
    }

    private func selectedVocabularyPool() -> [VocabularyItem] {
        let all = selectedTheme.vocabulary
        switch selectedLevel {
        case .l1:
            return Array(all.prefix(8))
        case .l2:
            return Array(all.prefix(9))
        case .l3, .l4:
            return all
        }
    }

    private func cardsForVocabulary(_ item: VocabularyItem, pairID: Int) -> [DominoLearningCard] {
        switch selectedRule {
        case .imageToWord:
            let wordText = selectedLevel == .l1 ? String(item.word.prefix(1)).uppercased() : item.word
            return [
                DominoLearningCard(
                    pairID: pairID,
                    primaryText: item.emoji,
                    secondaryText: "图片",
                    shouldSpeakOnTap: true,
                    spokenText: item.word,
                    item: item
                ),
                DominoLearningCard(
                    pairID: pairID,
                    primaryText: wordText,
                    secondaryText: selectedLevel.rawValue >= 3 ? item.meaning : nil,
                    shouldSpeakOnTap: true,
                    spokenText: item.word,
                    item: item
                )
            ]
        case .audioToWord:
            let wordText = selectedLevel == .l1 ? String(item.word.prefix(1)).uppercased() : item.word
            return [
                DominoLearningCard(
                    pairID: pairID,
                    primaryText: "🔊",
                    secondaryText: "listen",
                    shouldSpeakOnTap: true,
                    spokenText: item.word,
                    item: item
                ),
                DominoLearningCard(
                    pairID: pairID,
                    primaryText: wordText,
                    secondaryText: selectedLevel.rawValue >= 2 ? item.meaning : nil,
                    shouldSpeakOnTap: true,
                    spokenText: item.word,
                    item: item
                )
            ]
        case .wordToMeaning:
            let target: (primary: String, secondary: String?) = {
                switch selectedLevel {
                case .l1:
                    return (String(item.word.prefix(1)).uppercased(), nil)
                case .l2:
                    return (item.meaning, nil)
                case .l3:
                    return (item.phrase, nil)
                case .l4:
                    return (item.sentence, nil)
                }
            }()

            return [
                DominoLearningCard(
                    pairID: pairID,
                    primaryText: item.word,
                    secondaryText: selectedLevel == .l4 ? "word" : nil,
                    shouldSpeakOnTap: true,
                    spokenText: item.word,
                    item: item
                ),
                DominoLearningCard(
                    pairID: pairID,
                    primaryText: target.primary,
                    secondaryText: target.secondary,
                    shouldSpeakOnTap: false,
                    spokenText: nil,
                    item: item
                )
            ]
        }
    }

    private func speak(_ text: String, language: String = "en-US") {
        guard !text.isEmpty else { return }
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.06
        speechSynthesizer.speak(utterance)
    }

    private func encouragementText() -> String {
        let options = ["Great", "Nice match", "Awesome", "Well done"]
        return options.randomElement() ?? "Great"
    }

    private func presentLearningSetupMenu() {
        guard hasSelectedModeEntry else {
            makeModeEntryOverlay()
            return
        }
        guard let presenter = presentingViewController() else { return }

        let alert = UIAlertController(title: "学习设置", message: "调整词库、规则、关卡与模式", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "主题词库：\(selectedTheme.icon) \(selectedTheme.title)", style: .default) { [weak self] _ in
            self?.presentThemePicker()
        })
        alert.addAction(UIAlertAction(title: "配对规则：\(selectedRule.title)", style: .default) { [weak self] _ in
            self?.presentRulePicker()
        })
        alert.addAction(UIAlertAction(title: "关卡：\(selectedLevel.title)", style: .default) { [weak self] _ in
            self?.presentLevelPicker()
        })
        alert.addAction(UIAlertAction(title: "模式：\(learningMode.title)", style: .default) { [weak self] _ in
            self?.presentModePicker()
        })
        alert.addAction(UIAlertAction(title: "奖励建筑：\(selectedLandmark.displayName)", style: .default) { [weak self] _ in
            self?.presentLandmarkPicker()
        })
        alert.addAction(UIAlertAction(title: "切换背景", style: .default) { [weak self] _ in
            guard let self else { return }
            self.currentBackgroundIndex = (self.currentBackgroundIndex + 1) % GameConstants.Colors.backgroundGradients.count
            self.updateBackground()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let popover = alert.popoverPresentationController, let sceneView = view {
            popover.sourceView = sceneView
            let anchor = landmarkButton?.position ?? CGPoint(x: size.width / 2, y: size.height * 0.08)
            let anchorInView = convertPoint(toView: anchor)
            popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
            popover.permittedArrowDirections = [.up, .down]
        }

        presenter.present(alert, animated: true)
    }

    private func presentThemePicker() {
        guard let presenter = presentingViewController() else { return }
        let alert = UIAlertController(title: "选择主题词库", message: nil, preferredStyle: .actionSheet)
        for theme in LearningTheme.allCases {
            let title = theme == selectedTheme ? "\(theme.icon) \(theme.title) ✓" : "\(theme.icon) \(theme.title)"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                self.selectedTheme = theme
                self.resetInteractiveElements()
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        configurePopoverIfNeeded(for: alert, anchor: landmarkButton?.position ?? CGPoint(x: size.width / 2, y: size.height * 0.08))
        presenter.present(alert, animated: true)
    }

    private func presentRulePicker() {
        guard let presenter = presentingViewController() else { return }
        let alert = UIAlertController(title: "选择配对规则", message: nil, preferredStyle: .actionSheet)
        for rule in MatchingRule.allCases {
            let title = rule == selectedRule ? "\(rule.title) ✓" : rule.title
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                self.selectedRule = rule
                self.resetInteractiveElements()
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        configurePopoverIfNeeded(for: alert, anchor: landmarkButton?.position ?? CGPoint(x: size.width / 2, y: size.height * 0.08))
        presenter.present(alert, animated: true)
    }

    private func presentLevelPicker() {
        guard let presenter = presentingViewController() else { return }
        let alert = UIAlertController(title: "选择关卡难度", message: nil, preferredStyle: .actionSheet)
        for level in DifficultyLevel.allCases {
            let title = level == selectedLevel ? "\(level.title) ✓" : level.title
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                self.selectedLevel = level
                self.resetInteractiveElements()
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        configurePopoverIfNeeded(for: alert, anchor: landmarkButton?.position ?? CGPoint(x: size.width / 2, y: size.height * 0.08))
        presenter.present(alert, animated: true)
    }

    private func presentModePicker() {
        guard let presenter = presentingViewController() else { return }
        let alert = UIAlertController(title: "切换模式", message: nil, preferredStyle: .actionSheet)
        for mode in LearningMode.allCases {
            let title = mode == learningMode ? "\(mode.title) ✓" : mode.title
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applySelectedLearningMode(mode, shouldResetRound: true)
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        configurePopoverIfNeeded(for: alert, anchor: landmarkButton?.position ?? CGPoint(x: size.width / 2, y: size.height * 0.08))
        presenter.present(alert, animated: true)
    }

    private func presentParentPanel() {
        guard hasSelectedModeEntry else {
            makeModeEntryOverlay()
            return
        }
        guard let presenter = presentingViewController() else { return }

        let wrongWords = pendingReviewItems.map(\.word).sorted()
        let wrongPreview = wrongWords.prefix(4).joined(separator: ", ")
        let message = """
        模式：\(learningMode.title)
        无压力模式：\(noPressureMode ? "已开启" : "已关闭")
        累计关卡：\(completedRounds)
        连续学习天数：\(currentStreakDays)
        学习时长：\(formattedDuration(totalStudyDuration))
        已掌握词数：\(masteredWords.count)
        最近错词：\(wrongPreview.isEmpty ? "无" : wrongPreview)
        """

        let alert = UIAlertController(title: "家长面板", message: message, preferredStyle: .actionSheet)
        let toggleTitle = noPressureMode ? "关闭无压力模式" : "开启无压力模式"
        alert.addAction(UIAlertAction(title: toggleTitle, style: .default) { [weak self] _ in
            guard let self else { return }
            self.noPressureMode.toggle()
            self.updateStatusText(self.noPressureMode ? "无压力模式已开启。" : "无压力模式已关闭。")
        })
        if !pendingReviewItems.isEmpty {
            alert.addAction(UIAlertAction(title: "开始错词复习关", style: .default) { [weak self] _ in
                self?.startReviewRound()
            })
        }
        alert.addAction(UIAlertAction(title: "恢复默认学习设置", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.selectedRule = .imageToWord
            self.selectedLevel = .l1
            self.noPressureMode = true
            self.resetInteractiveElements()
        })
        alert.addAction(UIAlertAction(title: "关闭", style: .cancel))

        if let popover = alert.popoverPresentationController, let sceneView = view {
            popover.sourceView = sceneView
            let anchor = resetButton?.position ?? CGPoint(x: size.width / 2, y: size.height * 0.08)
            let anchorInView = convertPoint(toView: anchor)
            popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
            popover.permittedArrowDirections = [.up, .down]
        }

        presenter.present(alert, animated: true)
    }

    private func startReviewRound() {
        guard !pendingReviewItems.isEmpty else { return }
        forceReviewRound = true
        resetInteractiveElements()
        updateStatusText("已开启错词复习关。")
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let total = max(0, Int(duration.rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
        label.fontSize = 16
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = name
        button.addChild(label)
        
        return button
    }
    
    // MARK: - Interactions
    
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
        guard selectedLandmark != landmark else { return }
        selectedLandmark = landmark
        updateSubtitleText()
        replaceTower()
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

    private func configurePopoverIfNeeded(for alert: UIAlertController, anchor: CGPoint) {
        guard let popover = alert.popoverPresentationController, let sceneView = view else { return }
        popover.sourceView = sceneView
        let anchorInView = convertPoint(toView: anchor)
        popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
        popover.permittedArrowDirections = [.up, .down]
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
    
    private func presentDominoColorPicker() {
        guard let targetDomino = selectedDominoNode else { return }
        presentColorPicker(
            title: "选择骨牌颜色",
            message: "仅应用到当前点击的骨牌",
            currentIndex: targetDomino.colorOptionIndex,
            anchor: targetDomino.position
        ) { [weak self] index in
            self?.applySelectedDominoColor(index: index, to: targetDomino)
        }
    }
    
    private func applySelectedDominoColor(index: Int, to domino: DominoNode) {
        guard domino.colorOptionIndex != index else { return }
        guard let option = colorOption(at: index) else { return }
        domino.updateColor(option.color, colorOptionIndex: index)
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
        guard selectedBallColorOptionIndex != index else { return }
        guard let option = colorOption(at: index) else { return }
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
        guard selectedGuideLineColorOptionIndex != index else { return }
        guard let option = colorOption(at: index) else { return }
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
            return DominoColorOption(name: "default", color: fallbackColor)
        }

        guard dominoColorOptions.indices.contains(selectedIndex) else {
            selectedIndex = min(5, dominoColorOptions.count - 1)
            return dominoColorOptions[selectedIndex]
        }

        return dominoColorOptions[selectedIndex]
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
        guard learningRoundStage == .readyForChain else { return }
        guard flowStateMachine.startSimulation() else { return }
        learningRoundStage = .chainRunning
        isAnimating = true
        removeAction(forKey: GameConstants.autoResetActionKey)
        removeAction(forKey: chainWatchdogActionKey)
        removeAction(forKey: firstImpactAssistActionKey)
        removeAction(forKey: firstImpactFallbackActionKey)
        towerNode?.removeAction(forKey: towerToppleActionKey)
        countdownLabel?.text = ""
        setButtonEnabled(startButton, enabled: false)
        updateStartButtonTitle("连锁进行中")
        // Disable settings while animating
        setButtonEnabled(resetButton, enabled: false)
        setButtonEnabled(landmarkButton, enabled: false)

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
        learningRoundStage = .waitingToStart
        logger.info(
            "Run \(self.firstImpactTelemetry.runID) finished. fallen=\(self.fallenCount), directAssist=\(self.firstImpactTelemetry.directAssistCount), fallbackAssist=\(self.firstImpactTelemetry.fallbackAssistCount)"
        )
        let stars = String(repeating: "⭐️", count: max(1, lastRoundStars))
        updateStatusText("连锁完成！本关星级：\(stars)")
        updateProgressText()
        setButtonEnabled(resetButton, enabled: true)
        setButtonEnabled(landmarkButton, enabled: true)

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
