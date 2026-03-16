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
        let contentFrame: CGRect
        let isWide: Bool
        let isUltraWide: Bool
        let isPad: Bool
        let isPhone: Bool
        let isTV: Bool
    }
    
    private struct FirstImpactTelemetry {
        var runID: Int = 0
        var directAssistCount: Int = 0
        var fallbackAssistCount: Int = 0
    }
    
    private struct UDKeys {
        static let backgroundIndex = "dominoes.backgroundIndex"
        static let landmarkIndex = "dominoes.landmarkIndex"
        static let learningCategoryIndex = "dominoes.learningCategoryIndex"
        static let ballColorIndex = "dominoes.ballColorIndex"
        static let guideLineColorIndex = "dominoes.guideLineColorIndex"
        static let tvFocusSensitivityPreset = "dominoes.tvFocusSensitivityPreset"
    }

    private enum TVFocusableElement: Equatable {
        case startButton
        case landmarkButton
        case categoryButton
        case resetButton
        case tower
        case ball
        case guideLine
        case domino(index: Int)
    }

    private struct TVFocusableCandidate {
        let element: TVFocusableElement
        let center: CGPoint
        let frame: CGRect
    }

    private enum TVFocusSensitivityPreset: Int {
        case steady
        case responsive

        private struct Config {
            let displayName: String
            let initialDelay: TimeInterval
            let maxInterval: TimeInterval
            let minInterval: TimeInterval
            let accelerationDuration: TimeInterval
        }

        private static let configs: [TVFocusSensitivityPreset: Config] = [
            .steady: Config(
                displayName: "稳重",
                initialDelay: 0.42,
                maxInterval: 0.24,
                minInterval: 0.085,
                accelerationDuration: 2.6
            ),
            .responsive: Config(
                displayName: "灵敏",
                initialDelay: 0.16,
                maxInterval: 0.10,
                minInterval: 0.032,
                accelerationDuration: 0.75
            )
        ]

        private var config: Config {
            Self.configs[self] ?? Self.configs[.steady]!
        }

        var displayName: String {
            config.displayName
        }

        var initialDelay: TimeInterval {
            config.initialDelay
        }

        var maxInterval: TimeInterval {
            config.maxInterval
        }

        var minInterval: TimeInterval {
            config.minInterval
        }

        var accelerationDuration: TimeInterval {
            config.accelerationDuration
        }
    }

    private var layout: Layout?
    private var lastSafeAreaInsets: UIEdgeInsets = .zero
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
    private var explosionEffect: ExplosionEffect?
    private var cloudTextures: [SKTexture] = []
    
    // Button interaction state
    private var startButtonEnabled = false
    private var resetButtonEnabled = false
    private var landmarkButtonEnabled = false
    private var categoryButtonEnabled = false
    private var tvFocusedElement: TVFocusableElement = .startButton
    private var tvFocusRingNode: SKShapeNode?
    private var tvFocusSensitivityPreset: TVFocusSensitivityPreset = .steady
    private let tvFocusHoldTickInterval: TimeInterval = 0.02
    private let tvFocusRepeatActionKeyPrefix = "tvFocusRepeat."
    private var tvFocusRepeatStates: [String: TVFocusRepeatState] = [:]
    
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
    
    private let dominoColorOptions = LearningContent.colorOptions
    private let learningCategories = LearningContent.categories

    private struct TVFocusRepeatState {
        var heldDuration: TimeInterval = 0
        var elapsedSinceLastMove: TimeInterval = 0
    }


    override func didMove(to view: SKView) {
        backgroundColor = .white
        physicsWorld.gravity = GameConstants.Physics.gravity
        physicsWorld.contactDelegate = self
        explosionEffect = ExplosionEffect(scene: self)
        lastSafeAreaInsets = currentSafeAreaInsets()
        loadUserDefaults()
        buildStaticSceneOnce()
        resetInteractiveElements()
    }

    private func loadUserDefaults() {
        let ud = UserDefaults.standard
        let bgIdx = ud.integer(forKey: UDKeys.backgroundIndex)
        if bgIdx < GameConstants.Colors.backgroundGradients.count {
            currentBackgroundIndex = bgIdx
        }
        let lmIdx = ud.integer(forKey: UDKeys.landmarkIndex)
        let landmarks = TowerNode.Landmark.allCases
        if landmarks.indices.contains(lmIdx) {
            selectedLandmark = landmarks[lmIdx]
        }
        let catIdx = ud.integer(forKey: UDKeys.learningCategoryIndex)
        if learningCategories.indices.contains(catIdx) {
            selectedLearningCategoryIndex = catIdx
        }
        let ballIdx = ud.integer(forKey: UDKeys.ballColorIndex)
        if dominoColorOptions.indices.contains(ballIdx) {
            selectedBallColorOptionIndex = ballIdx
        }
        let guideIdx = ud.integer(forKey: UDKeys.guideLineColorIndex)
        if dominoColorOptions.indices.contains(guideIdx) {
            selectedGuideLineColorOptionIndex = guideIdx
        }
        if let preset = TVFocusSensitivityPreset(rawValue: ud.integer(forKey: UDKeys.tvFocusSensitivityPreset)) {
            tvFocusSensitivityPreset = preset
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard view != nil else { return }
        let insets = currentSafeAreaInsets()
        guard oldSize != size || insets != lastSafeAreaInsets else { return }
        lastSafeAreaInsets = insets
        rebuildSceneForLayoutChange()
    }

    func refreshLayoutForSafeAreaIfNeeded() {
        let insets = currentSafeAreaInsets()
        guard insets != lastSafeAreaInsets else { return }
        lastSafeAreaInsets = insets
        rebuildSceneForLayoutChange()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard let targetName = buttonName(at: location) else { return }

        handleInteraction(targetName: targetName, at: location)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
#if os(tvOS)
        var handled = false
        for press in presses {
            if tvFocusDirection(for: press.type) != nil {
                startTVDirectionalFocusRepeat(for: press.type)
                handled = true
                continue
            }

            if handleTVPress(press.type) {
                handled = true
            }
        }

        if handled {
            return
        }
#endif
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
#if os(tvOS)
        var handled = false
        for press in presses {
            if stopTVDirectionalFocusRepeat(for: press.type) {
                handled = true
            }
        }

        if handled {
            return
        }
#endif
        super.pressesEnded(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
#if os(tvOS)
        var handled = false
        for press in presses {
            if stopTVDirectionalFocusRepeat(for: press.type) {
                handled = true
            }
        }

        if handled {
            return
        }
#endif
        super.pressesCancelled(presses, with: event)
    }

    private func handleInteraction(targetName: String, at location: CGPoint) {
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
            cycleBackgroundAndReset()
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
#if os(tvOS)
        ensureTVFocusRingNode()
#endif
        
        // Prepare reusable textures
        if let layout = layout {
            dominoTexture = DominoNode.createBaseTexture(width: layout.dominoWidth, height: layout.baseDominoHeight + CGFloat(GameConstants.Geometry.numDominos) * layout.heightIncrement)
        }
    }

    private func rebuildSceneForLayoutChange() {
        isInitialized = false
#if os(tvOS)
        tvFocusRingNode = nil
#endif
        removeAllChildren()
        buildStaticSceneOnce()
        resetInteractiveElements()
    }

    private func currentSafeAreaInsets() -> UIEdgeInsets {
        view?.safeAreaInsets ?? .zero
    }
    
    private func resetInteractiveElements() {
        guard let layout = layout else { return }
#if os(tvOS)
        stopAllTVDirectionalFocusRepeats()
#endif
        
        // Clean up previous dynamic elements
        dominos.forEach { $0.removeFromParent() }
        dominos.removeAll()
        ballNode?.removeFromParent()
        towerNode?.removeFromParent()
        staircaseNode?.removeFromParent()
        // Keep staircaseNode reference for potential reuse (don't nil it here)

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
        
        let staircaseMinimumX = layout.contentFrame.minX + layout.ballRadius + (layout.isPhone ? 18 : 8)
        let staircaseCurveFactor: CGFloat = layout.isPhone ? 1.2 : 1.0
        let staircaseBendDirection: CGFloat = layout.isPhone ? -1.0 : 1.0
        let staircase = StaircaseNode.build(
            startX: layout.startX,
            groundY: layout.groundY,
            height: layout.baseDominoHeight * 4,
            ballRadius: layout.ballRadius,
            guideColor: currentGuideLineColorOption().color,
            minimumX: staircaseMinimumX,
            curveFactor: staircaseCurveFactor,
            bendDirection: staircaseBendDirection
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
#if os(tvOS)
        ensureTVFocusedElementIsValid()
        updateTVFocusAppearance()
#endif
    }
    
    private func resetScene() {
        guard !isAnimating else { return }
        resetInteractiveElements()
    }
    
    private func makeLayout(for size: CGSize) -> Layout {
        let sceneWidth = size.width
        let sceneHeight = size.height
        let idiom = view?.traitCollection.userInterfaceIdiom ?? UIDevice.current.userInterfaceIdiom
        let isPad = idiom == .pad
        let isPhone = idiom == .phone
        let isTV = idiom == .tv
        let safeInsets = currentSafeAreaInsets()
        let horizontalMargin = clamp(sceneWidth * 0.02, min: 8, max: 24)
        let verticalMargin = clamp(sceneHeight * 0.02, min: 6, max: 18)
        let contentFrame = CGRect(
            x: safeInsets.left + horizontalMargin,
            y: safeInsets.bottom + verticalMargin,
            width: max(1, sceneWidth - safeInsets.left - safeInsets.right - horizontalMargin * 2),
            height: max(1, sceneHeight - safeInsets.top - safeInsets.bottom - verticalMargin * 2)
        )
        let aspect = contentFrame.width / max(contentFrame.height, 1)
        let isWide = aspect > 1.25
        let isUltraWide = aspect > 1.9
        
        let groundRatio: CGFloat = isTV ? 0.15 : (isPad ? 0.15 : (isUltraWide ? 0.13 : (isWide ? 0.16 : 0.18)))
        let startRatio: CGFloat = isTV ? 0.10 : (isPad ? 0.09 : (isUltraWide ? 0.08 : (isWide ? 0.10 : 0.12)))
        let chainWidthRatio: CGFloat = isTV ? 0.62 : (isPad ? 0.62 : (isUltraWide ? 0.68 : (isWide ? 0.63 : 0.61)))
        let dominoWidthScale: CGFloat = isTV ? 0.0135 : (isPad ? 0.0185 : (isUltraWide ? 0.016 : 0.017))
        let baseDominoHeightScale: CGFloat = isTV ? 0.11 : (isPad ? 0.125 : (isUltraWide ? 0.10 : 0.11))
        let heightIncrementScale: CGFloat = isTV ? 0.0090 : (isPad ? 0.0125 : (isUltraWide ? 0.013 : 0.015))
        let towerWidthScale: CGFloat = isTV ? 0.10 : (isPad ? 0.12 : (isUltraWide ? 0.10 : 0.11))
        let towerGapRatio: CGFloat = isTV ? 0.035 : (isPad ? 0.045 : (isUltraWide ? 0.04 : 0.06))
        let ballTopInset: CGFloat = isTV ? 100 : (isPad ? 56 : (isUltraWide ? 40 : 48))
        let titleTopInset: CGFloat = isTV ? 54 : (isPad ? 36 : (isUltraWide ? 24 : 32))
        let subtitleGap: CGFloat = isTV ? 36 : (isPad ? 30 : (isUltraWide ? 24 : 26))
        let buttonHeightRatio: CGFloat = isTV ? 0.12 : (isPad ? 0.09 : (isUltraWide ? 0.11 : 0.10))

        let groundY = contentFrame.minY + contentFrame.height * groundRatio
        let startX = contentFrame.minX + contentFrame.width * startRatio
        
        let chainWidth = contentFrame.width * chainWidthRatio
        let spacing = chainWidth / CGFloat(GameConstants.Geometry.numDominos - 1)
        let dominoWidth = clamp(
            contentFrame.width * dominoWidthScale,
            min: isTV ? 14 : (isPad ? 14 : 10),
            max: isTV ? 30 : (isPad ? 24 : 18)
        )
        let baseDominoHeight = clamp(
            contentFrame.height * baseDominoHeightScale,
            min: isTV ? 68 : (isPad ? 62 : 34),
            max: isTV ? 160 : (isPad ? 120 : 84)
        )
        let heightIncrement = clamp(
            contentFrame.height * heightIncrementScale,
            min: isTV ? 5 : (isPad ? 8 : 4),
            max: isTV ? 12 : (isPad ? 16 : 11)
        )
        
        let towerWidth = clamp(
            contentFrame.width * towerWidthScale,
            min: isTV ? 110 : (isPad ? 100 : 68),
            max: isTV ? 220 : (isPad ? 220 : 150)
        )
        let towerGap = contentFrame.width * towerGapRatio
        let maxTowerX = contentFrame.maxX - towerWidth
        let towerX = min(startX + chainWidth + towerGap, maxTowerX)
        
        let ballRadius = dominoWidth * 1.1
        let ballStartX = max(contentFrame.minX + ballRadius + 8, startX - contentFrame.width * 0.06)
        let ballStartY = contentFrame.maxY - ballTopInset
        
        let titleY = contentFrame.maxY - titleTopInset
        let subtitleY = titleY - subtitleGap
        let buttonY = contentFrame.minY + contentFrame.height * buttonHeightRatio
        
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
            contentFrame: contentFrame,
            isWide: isWide,
            isUltraWide: isUltraWide,
            isPad: isPad,
            isPhone: isPhone,
            isTV: isTV
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
    
    private func ensureCloudTextures() {
        guard cloudTextures.isEmpty else { return }
        let view = SKView()
        // Pre-render 4 discrete cloud sizes to cover the 120-200 range
        let widths: [CGFloat] = [120, 150, 175, 200]
        for w in widths {
            let h = w * 0.35
            let padding: CGFloat = h * 0.6 // extra space for puffs
            let texW = w + padding * 2
            let texH = h + padding

            let container = SKNode()

            let body = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: h / 2)
            body.fillColor = .white
            body.strokeColor = .clear
            body.position = CGPoint(x: texW / 2, y: h / 2 + 2)
            container.addChild(body)

            let puff1 = SKShapeNode(circleOfRadius: h * 0.6)
            puff1.fillColor = .white
            puff1.strokeColor = .clear
            puff1.position = CGPoint(x: texW / 2 - w * 0.15, y: h * 0.3 + h / 2 + 2)
            container.addChild(puff1)

            let puff2 = SKShapeNode(circleOfRadius: h * 0.5)
            puff2.fillColor = .white
            puff2.strokeColor = .clear
            puff2.position = CGPoint(x: texW / 2 + w * 0.2, y: h * 0.2 + h / 2 + 2)
            container.addChild(puff2)

            if let texture = view.texture(from: container, crop: CGRect(x: 0, y: 0, width: texW, height: texH)) {
                texture.filteringMode = .linear
                cloudTextures.append(texture)
            }
        }
    }

    private func spawnCloud(fromRight: Bool) {
        ensureCloudTextures()
        guard !cloudTextures.isEmpty else { return }

        let texIndex = Int.random(in: 0..<cloudTextures.count)
        let texture = cloudTextures[texIndex]
        let cloudWidth: CGFloat = [120, 150, 175, 200][texIndex]

        let cloud = SKSpriteNode(texture: texture)
        cloud.name = "cloudNode"
        cloud.alpha = CGFloat.random(in: 0.6...0.9)
        cloud.zPosition = -15

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
        label.fontSize = currentLayout.isTV ? 42 : 28
        label.fontColor = GameConstants.Colors.textTitle
        label.position = CGPoint(x: currentLayout.contentFrame.midX, y: currentLayout.titleY)
        label.zPosition = 5
        return label
    }
    
    private func makeSubtitle() -> SKLabelNode {
        let currentLayout = layout ?? makeLayout(for: size)
        let label = SKLabelNode(fontNamed: "AvenirNext-Regular")
        label.text = subtitleText(for: selectedLandmark)
        label.fontSize = currentLayout.isTV ? 24 : 14
        label.fontColor = GameConstants.Colors.textSubtitle
        label.position = CGPoint(x: currentLayout.contentFrame.midX, y: currentLayout.subtitleY)
        label.zPosition = 5
        return label
    }
    
    private func subtitleText(for landmark: TowerNode.Landmark) -> String {
        let category = currentLearningCategory()
        if layout?.isTV == true {
            return "主题：\(category.icon)\(category.displayName)｜方向键移动焦点，按触控板确认，播放键切换手感：\(tvFocusSensitivityPreset.displayName)"
        }
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
        // Tighter spacing improves chain reliability across iPhone/iPad aspect ratios.
        let spacing = layout.spacing * (layout.isPad ? 0.88 : 0.90)
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
        let spacing: CGFloat
        let horizontalPadding: CGFloat
        let preferredWidth: CGFloat
        if currentLayout.isTV {
            spacing = 30
            horizontalPadding = 160
            preferredWidth = 250
        } else if currentLayout.isPad {
            spacing = 16
            horizontalPadding = 56
            preferredWidth = 168
        } else if currentLayout.isPhone && currentLayout.isUltraWide {
            spacing = 12
            horizontalPadding = 32
            preferredWidth = 150
        } else {
            spacing = currentLayout.isWide ? 12 : 8
            horizontalPadding = currentLayout.isWide ? 40 : 16
            preferredWidth = currentLayout.isWide ? 148 : 88
        }
        let buttonWidth = min(preferredWidth, (currentLayout.contentFrame.width - horizontalPadding - 3 * spacing) / 4)
        
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
        let startX = currentLayout.contentFrame.minX + (currentLayout.contentFrame.width - totalWidth) / 2 + start.frame.width / 2
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
        let currentLayout = layout ?? makeLayout(for: size)
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = ""
        label.fontSize = currentLayout.isTV ? 72 : 42
        label.fontColor = SKColor(white: 0.25, alpha: 1.0)
        label.position = CGPoint(x: currentLayout.contentFrame.midX, y: currentLayout.contentFrame.midY)
        label.zPosition = 20
        label.isHidden = true
        addChild(label)
        countdownLabel = label
    }
    
    private func makeButton(name: String, title: String, fillColor: SKColor, textColor: SKColor, layout: Layout, width: CGFloat) -> SKShapeNode {
        let buttonHeight: CGFloat
        let labelFontSize: CGFloat
        if layout.isTV {
            buttonHeight = 78
            labelFontSize = 24
        } else if layout.isPad {
            buttonHeight = 58
            labelFontSize = 17
        } else if layout.isPhone && layout.isUltraWide {
            buttonHeight = 56
            labelFontSize = 16
        } else {
            buttonHeight = layout.isWide ? 54 : 44
            labelFontSize = layout.isWide ? 16 : 13
        }

        let size = CGSize(width: width, height: buttonHeight)
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
        label.fontSize = labelFontSize
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

#if os(tvOS)
        ensureTVFocusedElementIsValid()
        updateTVFocusAppearance()
#endif
    }

    private func cycleBackgroundAndReset() {
        run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
        currentBackgroundIndex = (currentBackgroundIndex + 1) % GameConstants.Colors.backgroundGradients.count
        UserDefaults.standard.set(currentBackgroundIndex, forKey: UDKeys.backgroundIndex)
        updateBackground()
        resetInteractiveElements()
    }

#if os(tvOS)
    private func tvFocusDirection(for pressType: UIPress.PressType) -> CGVector? {
        switch pressType {
        case .leftArrow:
            return CGVector(dx: -1, dy: 0)
        case .rightArrow:
            return CGVector(dx: 1, dy: 0)
        case .upArrow:
            return CGVector(dx: 0, dy: 1)
        case .downArrow:
            return CGVector(dx: 0, dy: -1)
        default:
            return nil
        }
    }

    private func tvRepeatActionKey(for pressType: UIPress.PressType) -> String? {
        switch pressType {
        case .leftArrow:
            return "\(tvFocusRepeatActionKeyPrefix)left"
        case .rightArrow:
            return "\(tvFocusRepeatActionKeyPrefix)right"
        case .upArrow:
            return "\(tvFocusRepeatActionKeyPrefix)up"
        case .downArrow:
            return "\(tvFocusRepeatActionKeyPrefix)down"
        default:
            return nil
        }
    }

    private func startTVDirectionalFocusRepeat(for pressType: UIPress.PressType) {
        guard let direction = tvFocusDirection(for: pressType) else { return }
        guard let actionKey = tvRepeatActionKey(for: pressType) else { return }
        guard action(forKey: actionKey) == nil else { return }

        moveTVFocus(direction: direction)
        tvFocusRepeatStates[actionKey] = TVFocusRepeatState()

        let tickAction = SKAction.sequence([
            SKAction.wait(forDuration: tvFocusHoldTickInterval),
            SKAction.run { [weak self] in
                self?.handleTVDirectionalFocusTick(actionKey: actionKey, direction: direction)
            },
        ])
        let action = SKAction.sequence([
            SKAction.wait(forDuration: tvFocusSensitivityPreset.initialDelay),
            SKAction.repeatForever(tickAction)
        ])
        run(action, withKey: actionKey)
    }

    private func handleTVDirectionalFocusTick(actionKey: String, direction: CGVector) {
        guard var state = tvFocusRepeatStates[actionKey] else { return }

        state.heldDuration += tvFocusHoldTickInterval
        state.elapsedSinceLastMove += tvFocusHoldTickInterval

        let requiredInterval = tvFocusInterval(forHeldDuration: state.heldDuration)
        if state.elapsedSinceLastMove + 0.0001 >= requiredInterval {
            moveTVFocus(direction: direction)
            state.elapsedSinceLastMove = max(0, state.elapsedSinceLastMove - requiredInterval)
        }

        tvFocusRepeatStates[actionKey] = state
    }

    private func tvFocusInterval(forHeldDuration heldDuration: TimeInterval) -> TimeInterval {
        let normalized = min(max(heldDuration / tvFocusSensitivityPreset.accelerationDuration, 0), 1)
        let eased = 1 - pow(1 - normalized, 2)
        return tvFocusSensitivityPreset.maxInterval
            - (tvFocusSensitivityPreset.maxInterval - tvFocusSensitivityPreset.minInterval) * eased
    }

    @discardableResult
    private func stopTVDirectionalFocusRepeat(for pressType: UIPress.PressType) -> Bool {
        guard let actionKey = tvRepeatActionKey(for: pressType) else { return false }
        guard action(forKey: actionKey) != nil else { return false }
        removeAction(forKey: actionKey)
        tvFocusRepeatStates[actionKey] = nil
        return true
    }

    private func stopAllTVDirectionalFocusRepeats() {
        let allDirections: [UIPress.PressType] = [.leftArrow, .rightArrow, .upArrow, .downArrow]
        allDirections.forEach { _ = stopTVDirectionalFocusRepeat(for: $0) }
    }

    private func toggleTVFocusSensitivityPreset() {
        switch tvFocusSensitivityPreset {
        case .steady:
            tvFocusSensitivityPreset = .responsive
        case .responsive:
            tvFocusSensitivityPreset = .steady
        }
        UserDefaults.standard.set(tvFocusSensitivityPreset.rawValue, forKey: UDKeys.tvFocusSensitivityPreset)
        updateSubtitleText()
    }

    private func handleTVPress(_ pressType: UIPress.PressType) -> Bool {
        switch pressType {
        case .select:
            stopAllTVDirectionalFocusRepeats()
            activateTVFocusedElement()
            return true
        case .playPause:
            stopAllTVDirectionalFocusRepeats()
            toggleTVFocusSensitivityPreset()
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            return true
        case .menu:
            stopAllTVDirectionalFocusRepeats()
            return false
        default:
            return false
        }
    }

    private func ensureTVFocusRingNode() {
        if tvFocusRingNode != nil { return }
        let focusRing = SKShapeNode()
        focusRing.name = "tvFocusRing"
        focusRing.zPosition = 80
        focusRing.lineWidth = 5
        focusRing.strokeColor = SKColor.white
        focusRing.fillColor = .clear
        focusRing.glowWidth = 2
        focusRing.alpha = 0.95
        focusRing.isHidden = true
        addChild(focusRing)
        tvFocusRingNode = focusRing
    }

    private func moveTVFocus(direction: CGVector) {
        let candidates = tvFocusableCandidates()
        guard !candidates.isEmpty else {
            tvFocusRingNode?.isHidden = true
            return
        }

        guard let current = currentTVFocusableCandidate(from: candidates) else {
            tvFocusedElement = preferredInitialTVFocusElement(from: candidates)
            updateTVFocusAppearance()
            return
        }

        guard let next = nextTVFocusableCandidate(from: current, among: candidates, direction: direction) else {
            updateTVFocusAppearance()
            return
        }

        if next.element != current.element {
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
        }
        tvFocusedElement = next.element
        updateTVFocusAppearance()
    }

    private func activateTVFocusedElement(forced element: TVFocusableElement? = nil) {
        let candidates = tvFocusableCandidates()
        guard !candidates.isEmpty else { return }

        let targetElement = element ?? tvFocusedElement
        guard let candidate = candidates.first(where: { $0.element == targetElement }) else {
            tvFocusedElement = preferredInitialTVFocusElement(from: candidates)
            updateTVFocusAppearance()
            return
        }

        tvFocusedElement = candidate.element
        updateTVFocusAppearance()

        switch candidate.element {
        case .startButton:
            handleInteraction(targetName: "startButton", at: candidate.center)
        case .landmarkButton:
            handleInteraction(targetName: "landmarkButton", at: candidate.center)
        case .categoryButton:
            handleInteraction(targetName: "categoryButton", at: candidate.center)
        case .resetButton:
            handleInteraction(targetName: "resetButton", at: candidate.center)
        case .tower:
            handleInteraction(targetName: "towerTarget", at: candidate.center)
        case .ball:
            handleInteraction(targetName: "ball", at: candidate.center)
        case .guideLine:
            handleInteraction(targetName: "guideLineTarget", at: candidate.center)
        case let .domino(index):
            guard dominos.indices.contains(index) else { return }
            selectedDominoNode = dominos[index]
            handleInteraction(targetName: "dominoTarget", at: candidate.center)
        }
    }

    private func currentTVFocusableCandidate(from candidates: [TVFocusableCandidate]) -> TVFocusableCandidate? {
        if let current = candidates.first(where: { $0.element == tvFocusedElement }) {
            return current
        }
        return nil
    }

    private func preferredInitialTVFocusElement(from candidates: [TVFocusableCandidate]) -> TVFocusableElement {
        if candidates.contains(where: { $0.element == .startButton }) {
            return .startButton
        }
        return candidates[0].element
    }

    private func nextTVFocusableCandidate(
        from current: TVFocusableCandidate,
        among candidates: [TVFocusableCandidate],
        direction: CGVector
    ) -> TVFocusableCandidate? {
        let directionLength = hypot(direction.dx, direction.dy)
        guard directionLength > 0 else { return nil }

        var bestCandidate: TVFocusableCandidate?
        var bestScore = CGFloat.greatestFiniteMagnitude

        for candidate in candidates where candidate.element != current.element {
            let dx = candidate.center.x - current.center.x
            let dy = candidate.center.y - current.center.y
            let distance = hypot(dx, dy)
            guard distance > 0 else { continue }

            let dot = dx * direction.dx + dy * direction.dy
            guard dot > 0 else { continue }

            let alignment = dot / (distance * directionLength)
            guard alignment >= 0.20 else { continue }

            let perpendicular = abs(dx * direction.dy - dy * direction.dx)
            let score = distance / max(alignment, 0.001) + perpendicular * 0.22

            if score < bestScore {
                bestScore = score
                bestCandidate = candidate
            }
        }

        return bestCandidate
    }

    private func tvFocusableCandidates() -> [TVFocusableCandidate] {
        var candidates: [TVFocusableCandidate] = []

        if startButtonEnabled, let candidate = makeTVButtonCandidate(startButton, element: .startButton) {
            candidates.append(candidate)
        }
        if landmarkButtonEnabled, let candidate = makeTVButtonCandidate(landmarkButton, element: .landmarkButton) {
            candidates.append(candidate)
        }
        if categoryButtonEnabled, let candidate = makeTVButtonCandidate(categoryButton, element: .categoryButton) {
            candidates.append(candidate)
        }
        if resetButtonEnabled, let candidate = makeTVButtonCandidate(resetButton, element: .resetButton) {
            candidates.append(candidate)
        }

        guard !isAnimating else { return candidates }

        if landmarkButtonEnabled, let towerNode {
            let frame = towerNode.calculateAccumulatedFrame().insetBy(dx: -12, dy: -12)
            if frame.width > 0, frame.height > 0 {
                candidates.append(
                    TVFocusableCandidate(
                        element: .tower,
                        center: CGPoint(x: frame.midX, y: frame.midY),
                        frame: frame
                    )
                )
            }
        }

        if let ballNode {
            let frame = ballNode.calculateAccumulatedFrame().insetBy(dx: -10, dy: -10)
            if frame.width > 0, frame.height > 0 {
                candidates.append(
                    TVFocusableCandidate(
                        element: .ball,
                        center: CGPoint(x: frame.midX, y: frame.midY),
                        frame: frame
                    )
                )
            }
        }

        if staircaseNode != nil {
            if let guideCandidate = makeTVGuideLineCandidate() {
                candidates.append(guideCandidate)
            }
        }

        for (index, domino) in dominos.enumerated() {
            let frame = domino.calculateAccumulatedFrame().insetBy(dx: -8, dy: -12)
            guard frame.width > 0, frame.height > 0 else { continue }
            candidates.append(
                TVFocusableCandidate(
                    element: .domino(index: index),
                    center: CGPoint(x: frame.midX, y: frame.midY),
                    frame: frame
                )
            )
        }

        return candidates
    }

    private func makeTVButtonCandidate(_ button: SKShapeNode?, element: TVFocusableElement) -> TVFocusableCandidate? {
        guard let button else { return nil }
        let frame = button.calculateAccumulatedFrame().insetBy(dx: -8, dy: -8)
        guard frame.width > 0, frame.height > 0 else { return nil }
        return TVFocusableCandidate(
            element: element,
            center: CGPoint(x: frame.midX, y: frame.midY),
            frame: frame
        )
    }

    private func makeTVGuideLineCandidate() -> TVFocusableCandidate? {
        guard let staircase = staircaseNode else { return nil }
        let frame = staircase.calculateAccumulatedFrame()
        if frame.width <= 0 || frame.height <= 0 { return nil }

        let midIndex = staircase.rollPath.count / 2
        if staircase.rollPath.indices.contains(midIndex) {
            let midPoint = staircase.rollPath[midIndex].position
            let candidateFrame = CGRect(x: midPoint.x - 90, y: midPoint.y - 30, width: 180, height: 60)
            return TVFocusableCandidate(
                element: .guideLine,
                center: midPoint,
                frame: candidateFrame
            )
        }

        return TVFocusableCandidate(
            element: .guideLine,
            center: CGPoint(x: frame.midX, y: frame.midY),
            frame: CGRect(x: frame.midX - 90, y: frame.midY - 30, width: 180, height: 60)
        )
    }

    private func ensureTVFocusedElementIsValid() {
        let candidates = tvFocusableCandidates()
        guard !candidates.isEmpty else {
            tvFocusRingNode?.isHidden = true
            return
        }

        if !candidates.contains(where: { $0.element == tvFocusedElement }) {
            tvFocusedElement = preferredInitialTVFocusElement(from: candidates)
        }
    }

    private func updateTVFocusAppearance() {
        ensureTVFocusRingNode()
        let candidates = tvFocusableCandidates()
        guard !candidates.isEmpty else {
            tvFocusRingNode?.isHidden = true
            return
        }

        if !candidates.contains(where: { $0.element == tvFocusedElement }) {
            tvFocusedElement = preferredInitialTVFocusElement(from: candidates)
        }

        guard let focusedCandidate = candidates.first(where: { $0.element == tvFocusedElement }) else {
            tvFocusRingNode?.isHidden = true
            return
        }

        let ringFrame = focusedCandidate.frame
        let cornerRadius = min(20, max(10, min(ringFrame.width, ringFrame.height) * 0.24))
        let ringPath = CGPath(
            roundedRect: ringFrame,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        tvFocusRingNode?.path = ringPath
        tvFocusRingNode?.isHidden = false
    }
#endif
    
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
        let options = TowerNode.Landmark.allCases.map { landmark in
            PickerPresenter.Option(
                title: "\(landmark.thumbnailIcon) \(landmark.englishName)",
                isSelected: landmark == selectedLandmark
            )
        }
        let currentLayout = layout ?? makeLayout(for: size)
        let anchor = landmarkButton?.position ?? CGPoint(x: currentLayout.contentFrame.midX, y: currentLayout.buttonY)
        PickerPresenter.presentActionSheet(
            title: "Choose Building", message: "Pick one building",
            options: options, anchor: anchor, scene: self
        ) { [weak self] index in
            let landmark = TowerNode.Landmark.allCases[index]
            self?.applySelectedLandmark(landmark)
        }
    }
    
    private func applySelectedLandmark(_ landmark: TowerNode.Landmark) {
        speakEnglish(landmark.englishName)
        guard selectedLandmark != landmark else { return }
        selectedLandmark = landmark
        UserDefaults.standard.set(TowerNode.Landmark.allCases.firstIndex(of: landmark) ?? 0, forKey: UDKeys.landmarkIndex)
        updateSubtitleText()
        replaceTower()
    }

    private func presentLearningCategoryPicker() {
        let options = learningCategories.enumerated().map { index, category in
            PickerPresenter.Option(
                title: "\(category.icon) \(category.displayName) · \(category.englishName)",
                isSelected: index == selectedLearningCategoryIndex
            )
        }
        let currentLayout = layout ?? makeLayout(for: size)
        let anchor = categoryButton?.position ?? CGPoint(x: currentLayout.contentFrame.midX, y: currentLayout.buttonY)
        PickerPresenter.presentActionSheet(
            title: "选择学习主题", message: "适合 4 岁儿童的图片词汇",
            options: options, anchor: anchor, scene: self
        ) { [weak self] index in
            self?.applySelectedLearningCategory(index: index)
        }
    }

    private func applySelectedLearningCategory(index: Int) {
        guard learningCategories.indices.contains(index) else { return }
        let category = learningCategories[index]
        speakEnglish(category.englishName)

        guard selectedLearningCategoryIndex != index else { return }

        selectedLearningCategoryIndex = index
        UserDefaults.standard.set(index, forKey: UDKeys.learningCategoryIndex)
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
        let category = currentLearningCategory()
        let options = category.items.enumerated().map { index, item in
            PickerPresenter.Option(
                title: "\(item.icon) \(item.englishName) (\(item.chineseName))",
                isSelected: index == targetDomino.colorOptionIndex
            )
        }
        PickerPresenter.presentActionSheet(
            title: "选择图片与英语单词",
            message: "主题：\(category.icon)\(category.displayName)",
            options: options, anchor: targetDomino.position, scene: self
        ) { [weak self] index in
            self?.applySelectedDominoLearning(index: index, to: targetDomino)
        }
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
        UserDefaults.standard.set(index, forKey: UDKeys.ballColorIndex)

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
        UserDefaults.standard.set(index, forKey: UDKeys.guideLineColorIndex)

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
        let options = dominoColorOptions.enumerated().map { index, option in
            PickerPresenter.Option(title: option.name, isSelected: index == currentIndex)
        }
        PickerPresenter.presentActionSheet(
            title: title, message: message,
            options: options, anchor: anchor, scene: self,
            onSelect: onSelect
        )
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
        explosionEffect?.explode(
            dominos: dominos,
            tower: towerNode,
            sceneSize: size,
            baseDominoHeight: layout?.baseDominoHeight ?? 40
        )
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
                let sizeFactor = max(1.0, firstDomino.height / 72.0)

                let firstDominoLeftEdge = firstDomino.position.x - firstDomino.width
                let releasePosition = CGPoint(
                    x: firstDominoLeftEdge - layout.ballRadius * (layout.isPad ? 0.72 : 0.86),
                    y: layout.groundY + max(layout.ballRadius * 0.95, min(firstDomino.height * 0.40, layout.ballRadius * 1.95))
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
                let launchSpeed = layout.ballRadius * (9.2 + (sizeFactor - 1.0) * 2.0)
                ballBody.velocity = CGVector(dx: launchSpeed, dy: 0)
                ballBody.applyImpulse(CGVector(dx: layout.ballRadius * (0.62 + (sizeFactor - 1.0) * 0.28), dy: 0))
                ballBody.applyAngularImpulse(-0.01)

                // Give the first domino a manual tip so it gracefully falls and starts the chain
                if let firstBody = firstDomino.physicsBodyForSimulation {
                    firstBody.isResting = false
                    let tipAngularImpulse = 0.11 * sizeFactor
                    let tipLinearImpulse = max(layout.ballRadius * 0.82, firstDomino.height * 0.11)
                    firstBody.applyAngularImpulse(-tipAngularImpulse)
                    firstBody.applyImpulse(
                        CGVector(dx: tipLinearImpulse, dy: 0),
                        at: CGPoint(x: -firstDomino.width * 0.82, y: firstDomino.height * 0.88)
                    )
                    firstBody.angularVelocity = min(firstBody.angularVelocity, -2.2 * sizeFactor)
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
            SKAction.wait(forDuration: 0.12),
            SKAction.run { [weak self] in
                guard let self else { return }
                guard self.isAnimating else { return }
                guard let firstDomino = self.dominos.first else { return }
                guard !firstDomino.hasFallen else { return }
                guard let firstBody = firstDomino.physicsBodyForSimulation else { return }
                let sizeFactor = max(1.0, firstDomino.height / 72.0)
                let needsBoost = abs(firstBody.angularVelocity) < (1.8 * sizeFactor)
                guard needsBoost else { return }

                firstBody.isResting = false
                let fallbackLinearImpulse = max(layout.ballRadius * 1.08, firstDomino.height * 0.14)
                let fallbackAngularImpulse = 0.15 * sizeFactor
                firstBody.applyImpulse(
                    CGVector(dx: fallbackLinearImpulse, dy: 0),
                    at: CGPoint(x: -firstDomino.width * 0.85, y: firstDomino.height * 0.9)
                )
                firstBody.applyAngularImpulse(-fallbackAngularImpulse)
                firstBody.angularVelocity = min(firstBody.angularVelocity, -3.0 * sizeFactor)
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
