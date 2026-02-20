//
//  DominoNode.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import SpriteKit

final class DominoNode: SKNode {
    private(set) var color: SKColor
    private(set) var colorOptionIndex: Int
    let xPosition: CGFloat
    let height: CGFloat
    let width: CGFloat
    
    private let sprite: SKSpriteNode

    // Physics / state
    var hasFallen = false
    var hasPlayedHitSound = false

    init(color: SKColor, colorOptionIndex: Int, xPosition: CGFloat, width: CGFloat, height: CGFloat, texture: SKTexture?) {
        self.color = color
        self.colorOptionIndex = colorOptionIndex
        self.xPosition = xPosition
        self.height = height
        self.width = width
        
        // Use a sprite node for rendering performance
        if let tex = texture {
            sprite = SKSpriteNode(texture: tex, size: CGSize(width: width, height: height))
        } else {
            // Fallback to solid color if texture generation failed
            sprite = SKSpriteNode(color: color, size: CGSize(width: width, height: height))
        }
        
        super.init()
        
        sprite.anchorPoint = CGPoint(x: 1.0, y: 0) // Anchor at bottom-right equivalent to shape (-width to 0)
        sprite.color = color // Color blend
        sprite.colorBlendFactor = 1.0
        
        self.addChild(sprite)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configurePhysics() {
        // Visual anchor is bottom-right (x: 1, y: 0) so the local rect is [-width, 0] x [0, height].
        // Set a matching physics body so rotation feels natural around the base.
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
    
    // Class helper to generate a reusable texture for all dominos
    static func createBaseTexture(width: CGFloat, height: CGFloat) -> SKTexture? {
        // Create a representative shape node just for texture generation
        let rect = CGPath(rect: CGRect(x: -width, y: 0, width: width, height: height), transform: nil)
        let domino = SKShapeNode(path: rect)
        domino.fillColor = .white // White base to allow color blending
        domino.strokeColor = SKColor(white: 0.2, alpha: 0.25)
        domino.lineWidth = 1
        
        let highlightRect = CGPath(roundedRect: CGRect(x: -width + 2, y: 2, width: 3, height: height - 4), cornerWidth: 1, cornerHeight: 1, transform: nil)
        let highlight = SKShapeNode(path: highlightRect)
        highlight.fillColor = SKColor(white: 1.0, alpha: 0.25)
        highlight.strokeColor = .clear
        
        let container = SKNode()
        container.addChild(domino)
        container.addChild(highlight)
        
        // Use a dummy SKView to render the texture
        let view = SKView()
        return view.texture(from: container)
    }
}
