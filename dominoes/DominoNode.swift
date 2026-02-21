//
//  DominoNode.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import SpriteKit

final class DominoNode: SKNode {
    struct LearningContent {
        let primaryText: String
        let secondaryText: String?
        let shouldSpeakOnTap: Bool
        let spokenText: String?
    }

    private(set) var color: SKColor
    private(set) var colorOptionIndex: Int
    let xPosition: CGFloat
    let height: CGFloat
    let width: CGFloat

    private let sprite: SKSpriteNode
    private let primaryLabel: SKLabelNode
    private let secondaryLabel: SKLabelNode
    private let selectionOutline: SKShapeNode

    private(set) var learningContent: LearningContent?
    private(set) var isMatchedForLearning = false

    // Physics / state
    var hasFallen = false
    var hasPlayedHitSound = false

    init(color: SKColor, colorOptionIndex: Int, xPosition: CGFloat, width: CGFloat, height: CGFloat, texture: SKTexture?) {
        self.color = color
        self.colorOptionIndex = colorOptionIndex
        self.xPosition = xPosition
        self.height = height
        self.width = width

        if let tex = texture {
            sprite = SKSpriteNode(texture: tex, size: CGSize(width: width, height: height))
        } else {
            sprite = SKSpriteNode(color: color, size: CGSize(width: width, height: height))
        }

        primaryLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        secondaryLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")

        let outlinePath = CGPath(
            roundedRect: CGRect(x: -width, y: 0, width: width, height: height),
            cornerWidth: max(2, width * 0.15),
            cornerHeight: max(2, width * 0.15),
            transform: nil
        )
        selectionOutline = SKShapeNode(path: outlinePath)

        super.init()

        sprite.anchorPoint = CGPoint(x: 1.0, y: 0)
        sprite.color = color
        sprite.colorBlendFactor = 1.0
        addChild(sprite)

        configureLearningLabels()

        selectionOutline.strokeColor = .clear
        selectionOutline.fillColor = .clear
        selectionOutline.lineWidth = 0
        selectionOutline.glowWidth = 0
        selectionOutline.zPosition = 4
        addChild(selectionOutline)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configurePhysics() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height), center: CGPoint(x: -width / 2, y: height / 2))
        body.isDynamic = true
        body.allowsRotation = true
        body.affectedByGravity = true

        body.mass = GameConstants.Physics.dominoMass
        body.friction = GameConstants.Physics.dominoFriction
        body.restitution = GameConstants.Physics.dominoRestitution
        body.linearDamping = GameConstants.Physics.dominoLinearDamping
        body.angularDamping = GameConstants.Physics.dominoAngularDamping

        body.categoryBitMask = GameConstants.Physics.domino
        body.collisionBitMask = GameConstants.Physics.domino | GameConstants.Physics.ball | GameConstants.Physics.ground | GameConstants.Physics.tower
        body.contactTestBitMask = GameConstants.Physics.domino | GameConstants.Physics.ball | GameConstants.Physics.ground

        sprite.physicsBody = body
    }

    var physicsBodyForSimulation: SKPhysicsBody? { sprite.physicsBody }

    func resetPhysicsState() {
        hasFallen = false
        hasPlayedHitSound = false
        sprite.physicsBody?.velocity = .zero
        sprite.physicsBody?.angularVelocity = 0
        sprite.zRotation = 0
        sprite.physicsBody?.isDynamic = true
        sprite.alpha = 1.0
        setLearningMatched(false)
        setLearningSelectionActive(false)
    }

    /// Used to decide when a tile is considered "fallen".
    func evaluateFallenIfNeeded() -> Bool {
        guard !hasFallen else { return false }
        if abs(sprite.zRotation) >= GameConstants.Physics.fallenAngleThreshold {
            hasFallen = true
            return true
        }
        return false
    }

    func updateColor(_ newColor: SKColor, colorOptionIndex: Int) {
        color = newColor
        self.colorOptionIndex = colorOptionIndex
        sprite.color = newColor
        sprite.colorBlendFactor = 1.0
    }

    func updateLearningContent(_ content: LearningContent) {
        learningContent = content
        primaryLabel.text = content.primaryText
        secondaryLabel.text = content.secondaryText
        secondaryLabel.isHidden = content.secondaryText == nil
        updateLearningLabelSizing(primary: content.primaryText, secondary: content.secondaryText)
    }

    func clearLearningContent() {
        learningContent = nil
        primaryLabel.text = nil
        secondaryLabel.text = nil
    }

    func setLearningSelectionActive(_ active: Bool) {
        guard !isMatchedForLearning else { return }
        selectionOutline.strokeColor = active
            ? SKColor(red: 1.0, green: 0.84, blue: 0.28, alpha: 1.0)
            : .clear
        selectionOutline.lineWidth = active ? 2.8 : 0
        selectionOutline.glowWidth = active ? 4.6 : 0
    }

    func setLearningMatched(_ matched: Bool) {
        isMatchedForLearning = matched
        if matched {
            selectionOutline.strokeColor = SKColor(red: 0.13, green: 0.78, blue: 0.42, alpha: 1.0)
            selectionOutline.lineWidth = 3
            selectionOutline.glowWidth = 6
            sprite.alpha = 0.9
        } else {
            selectionOutline.strokeColor = .clear
            selectionOutline.lineWidth = 0
            selectionOutline.glowWidth = 0
            sprite.alpha = 1.0
        }
    }

    static func createBaseTexture(width: CGFloat, height: CGFloat) -> SKTexture? {
        let rect = CGPath(rect: CGRect(x: -width, y: 0, width: width, height: height), transform: nil)
        let domino = SKShapeNode(path: rect)
        domino.fillColor = .white
        domino.strokeColor = SKColor(white: 0.2, alpha: 0.25)
        domino.lineWidth = 1

        let highlightRect = CGPath(
            roundedRect: CGRect(x: -width + 2, y: 2, width: 3, height: height - 4),
            cornerWidth: 1,
            cornerHeight: 1,
            transform: nil
        )
        let highlight = SKShapeNode(path: highlightRect)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.25)
        highlight.strokeColor = .clear

        let container = SKNode()
        container.addChild(domino)
        container.addChild(highlight)

        let view = SKView()
        return view.texture(from: container)
    }

    private func configureLearningLabels() {
        let labelContainer = SKNode()
        labelContainer.position = CGPoint(x: -width / 2, y: height * 0.52)
        labelContainer.zPosition = 3
        labelContainer.zRotation = -.pi / 2
        sprite.addChild(labelContainer)

        primaryLabel.text = nil
        primaryLabel.fontColor = SKColor(white: 0.12, alpha: 1.0)
        primaryLabel.verticalAlignmentMode = .center
        primaryLabel.horizontalAlignmentMode = .center
        primaryLabel.position = CGPoint(x: 0, y: 7)
        labelContainer.addChild(primaryLabel)

        secondaryLabel.text = nil
        secondaryLabel.fontColor = SKColor(white: 0.17, alpha: 0.95)
        secondaryLabel.verticalAlignmentMode = .center
        secondaryLabel.horizontalAlignmentMode = .center
        secondaryLabel.position = CGPoint(x: 0, y: -10)
        labelContainer.addChild(secondaryLabel)
    }

    private func updateLearningLabelSizing(primary: String, secondary: String?) {
        let base = max(12, min(22, height * 0.16))
        let primaryPenalty = max(0.55, 1.2 - CGFloat(primary.count) * 0.06)
        primaryLabel.fontSize = base * primaryPenalty

        guard let secondary, !secondary.isEmpty else { return }
        let secondaryPenalty = max(0.58, 1.1 - CGFloat(secondary.count) * 0.05)
        secondaryLabel.fontSize = base * 0.72 * secondaryPenalty
    }
}
