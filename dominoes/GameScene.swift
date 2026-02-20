//
//  GameScene.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import SpriteKit
import UIKit

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
    private var staircaseNode: StaircaseNode?
    
    // Managers and State
    private var isAnimating = false
    private var isInitialized = false

    // Physics chain-reaction monitoring
    private var lastProgressTime: TimeInterval = 0
    private var fallenCount: Int = 0
    private var nudgeCount: Int = 0
    private var chainWatchdogActionKey = "chainWatchdog"
    
    // Reusable Textures
    private var dominoTexture: SKTexture?
    private var explosionParticleTexture: SKTexture?
    
    // Button interaction state
    private var startButtonEnabled = false
    private var resetButtonEnabled = false
    private var landmarkButtonEnabled = false
    
    private var selectedLandmark: TowerNode.Landmark = .eiffelTower
    private var selectedDominoNode: DominoNode?
    
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
        case "dominoTarget":
            guard !isAnimating else { return }
            guard let domino = touchedDomino(at: location) else { return }
            selectedDominoNode = domino
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentDominoColorPicker()
        case "startButton":
            guard startButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            startAnimation()
        case "landmarkButton", "towerTarget":
            guard landmarkButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            presentLandmarkPicker()
        case "resetButton":
            guard resetButtonEnabled else { return }
            run(SKAction.playSoundFileNamed("click.wav", waitForCompletion: false))
            resetScene()
        default:
            break
        }
    }
    
    // MARK: - Scene Construction
    
    private func buildStaticSceneOnce() {
        guard !isInitialized else { return }
        isInitialized = true
        layout = makeLayout(for: size)
        
        addChild(makeGradientBackground(size: size))
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
        countdownLabel?.text = ""
        selectedDominoNode = nil
        fallenCount = 0
        nudgeCount = 0
        lastProgressTime = 0
        
        // Build new dynamic elements
        let ball = makeBall(layout: layout)
        ballNode = ball
        addChild(ball)
        
        let staircase = StaircaseNode.build(startX: layout.startX, groundY: layout.groundY, height: layout.baseDominoHeight * 4, ballRadius: layout.ballRadius)
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
        
        setButtonEnabled(resetButton, enabled: false)
        setButtonEnabled(startButton, enabled: true)
        setButtonEnabled(landmarkButton, enabled: true)
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
        let texture = gradientTexture(
            size: size,
            colors: [GameConstants.Colors.backgroundGradientStart, GameConstants.Colors.backgroundGradientEnd]
        )
        let node = SKSpriteNode(texture: texture)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.zPosition = -20
        return node
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
        "点击“开始模拟”，观看多米诺骨牌击倒\(landmark.displayName)"
    }
    
    private func updateSubtitleText() {
        subtitleLabel?.text = subtitleText(for: selectedLandmark)
    }
    
    private func makeBall(layout: Layout) -> SKShapeNode {
        let ball = SKShapeNode(circleOfRadius: layout.ballRadius)
        ball.fillColor = GameConstants.Colors.ballFill
        ball.strokeColor = GameConstants.Colors.ballStroke
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
        body.categoryBitMask = GameConstants.Physics.ball
        body.collisionBitMask = GameConstants.Physics.domino | GameConstants.Physics.ground | GameConstants.Physics.tower
        body.contactTestBitMask = GameConstants.Physics.domino | GameConstants.Physics.ground
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
            
            addChild(domino)
            dominos.append(domino)
        }
    }
    
    private func makeTower(layout: Layout) {
        let tower = TowerNode.build(width: layout.towerWidth, landmark: selectedLandmark)
        tower.position = CGPoint(x: layout.towerX + layout.towerWidth / 2, y: layout.groundY)
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
        let reset = makeButton(
            name: "resetButton",
            title: "重置场景",
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
        guard let presenter = presentingViewController() else { return }
        
        let alert = UIAlertController(title: "选择骨牌颜色", message: "仅应用到当前点击的骨牌", preferredStyle: .actionSheet)
        
        for (index, option) in dominoColorOptions.enumerated() {
            let title = index == targetDomino.colorOptionIndex ? "\(option.name) ✓" : option.name
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applySelectedDominoColor(index: index, to: targetDomino)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController, let sceneView = view {
            popover.sourceView = sceneView
            let anchorPoint = targetDomino.position
            let anchorInView = convertPoint(toView: anchorPoint)
            popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
            popover.permittedArrowDirections = [.up, .down]
        }
        
        presenter.present(alert, animated: true)
    }
    
    private func applySelectedDominoColor(index: Int, to domino: DominoNode) {
        guard index >= 0, index < dominoColorOptions.count else { return }
        guard domino.colorOptionIndex != index else { return }
        let option = dominoColorOptions[index]
        domino.updateColor(option.color, colorOptionIndex: index)
        selectedDominoNode = nil
    }
    
    // MARK: - Animations
    
    private func startAnimation() {
        guard !isAnimating, let layout = layout else { return }
        isAnimating = true
        removeAction(forKey: GameConstants.autoResetActionKey)
        removeAction(forKey: chainWatchdogActionKey)
        countdownLabel?.text = ""
        setButtonEnabled(startButton, enabled: false)
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

        let ballDuration = runBallReleaseSequence(layout: layout)

        // Switch ball to physics right before it reaches the first domino.
        let enablePhysicsTime = max(0, ballDuration - 0.18)
        let enableBallPhysics = SKAction.sequence([
            SKAction.wait(forDuration: enablePhysicsTime),
            SKAction.run { [weak self] in
                guard let self else { return }
                guard let ball = self.ballNode else { return }
                // Allow physics to take over for the impact.
                ball.physicsBody?.isDynamic = true
                
                // Give it a gentle forward impulse so it can actually topple the first tile.
                // A-mode: keep the push more physical (less "scripted")
                ball.physicsBody?.applyImpulse(CGVector(dx: 1.25 * layout.ballRadius, dy: 0.10 * layout.ballRadius))
            }
        ])
        run(enableBallPhysics)

        startChainWatchdog()
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
    
    private func explodeDominos() {
        run(SKAction.playSoundFileNamed("explode.wav", waitForCompletion: false))
        for domino in dominos {
            domino.isHidden = true
            createExplosion(at: domino.position, color: domino.color)
        }
    }
    
    private func createExplosion(at position: CGPoint, color: SKColor) {
        // Create an emitter node programmatically
        let emitter = SKEmitterNode()
        emitter.name = "explosionEmitter"
        
        // Define particle properties
        emitter.particleTexture = resolvedExplosionParticleTexture()
        
        emitter.particleBirthRate = 500
        emitter.numParticlesToEmit = Int.random(in: 12...24)
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.4
        
        emitter.particlePosition = CGPoint(x: 0, y: layout?.baseDominoHeight ?? 50 / 2)
        emitter.particlePositionRange = CGVector(dx: 15, dy: layout?.baseDominoHeight ?? 30)
        
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        
        emitter.particleSpeed = 250
        emitter.particleSpeedRange = 100
        emitter.yAcceleration = -800 // Gravity
        
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.8
        
        emitter.particleScale = 0.05
        emitter.particleScaleRange = 0.03
        emitter.particleScaleSpeed = -0.02
        
        // Use the domino's color
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorBlendFactorRange = 0.0
        
        emitter.position = position
        emitter.zPosition = 5
        
        addChild(emitter)
        
        // Remove emitter after it finishes
        let duration = CGFloat(emitter.particleLifetime + emitter.particleLifetimeRange)
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(duration)),
            SKAction.removeFromParent()
        ]))
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
        
        // Hit the ground roll towards the domino
        let finalRollTarget = CGPoint(x: layout.startX, y: layout.groundY + layout.ballRadius)
        let groundRollDuration: TimeInterval = 0.28
        let groundMove = SKAction.move(to: finalRollTarget, duration: groundRollDuration)
        groundMove.timingMode = .easeIn
        let groundSpin = SKAction.rotate(byAngle: -.pi, duration: groundRollDuration)
        groundSpin.timingMode = .easeIn
        let groundScale = SKAction.scale(to: 1.0, duration: groundRollDuration)
        actions.append(SKAction.group([groundMove, groundSpin, groundScale]))
        totalDuration += groundRollDuration
        
        // Small squish on hitting the domino
        let hitSound = SKAction.playSoundFileNamed("hit.wav", waitForCompletion: false)
        let squish = SKAction.scaleX(to: 0.9, y: 1.1, duration: 0.1)
        let restore = SKAction.scale(to: 1.0, duration: 0.1)
        actions.append(SKAction.sequence([hitSound, squish, restore]))
        totalDuration += 0.2
        
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
        isAnimating = false
        setButtonEnabled(resetButton, enabled: true)
        setButtonEnabled(landmarkButton, enabled: true)
        
        // Optional: you can keep explodeDominos() as a reward, or disable for a more realistic ending.
        explodeDominos()
        startAutoResetCountdown(seconds: GameConstants.Geometry.autoResetDelay)
    }

    private func startAutoResetCountdown(seconds: Int) {
        guard seconds > 0 else { return }
        var actions: [SKAction] = []
        for value in stride(from: seconds, through: 1, by: -1) {
            actions.append(SKAction.run { [weak self] in
                self?.countdownLabel?.text = "自动重置 \(value)s"
            })
            actions.append(SKAction.wait(forDuration: 1))
        }
        actions.append(SKAction.run { [weak self] in
            self?.countdownLabel?.text = ""
            self?.resetScene()
        })
        run(SKAction.sequence(actions), withKey: GameConstants.autoResetActionKey)
    }
}
