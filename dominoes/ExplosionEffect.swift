import SpriteKit
import UIKit

final class ExplosionEffect {
    private weak var scene: SKScene?
    private var particleTexture: SKTexture?
    private var baseDominoHeight: CGFloat = 40

    init(scene: SKScene) {
        self.scene = scene
    }

    func explode(dominos: [DominoNode], tower: SKNode?, sceneSize: CGSize, baseDominoHeight: CGFloat) {
        guard let scene else { return }
        self.baseDominoHeight = baseDominoHeight

        scene.run(SKAction.playSoundFileNamed("explode.wav", waitForCompletion: false))

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

        for domino in dominos {
            domino.isHidden = true
            createExplosion(
                at: domino.position,
                color: domino.color,
                particleCount: Int.random(in: budget.particlesPerBurst),
                particleSpeed: budget.particleSpeed,
                includeSmoke: Int.random(in: 0...4) == 0,
                sceneSize: sceneSize
            )
        }

        if let tower {
            let points = towerExplosionPoints(for: tower, limit: budget.maxTowerEmitters)
            tower.isHidden = true
            for point in points {
                let randomColor = colors.randomElement() ?? GameConstants.Colors.towerBase
                createExplosion(
                    at: point,
                    color: randomColor,
                    particleCount: Int.random(in: budget.particlesPerBurst),
                    particleSpeed: budget.particleSpeed,
                    includeSmoke: true,
                    sceneSize: sceneSize
                )
            }
        }
    }

    private func createExplosion(at position: CGPoint, color: SKColor, particleCount: Int, particleSpeed: CGFloat, includeSmoke: Bool, sceneSize: CGSize) {
        guard let scene else { return }
        addExplosionFlash(at: position, color: color)

        let texture = resolvedParticleTexture()
        let lowHeight = sceneSize.height * 0.32
        let verticalLift = position.y < lowHeight ? max(sceneSize.height * 0.08, 26) : 0
        let elevatedPosition = CGPoint(x: position.x, y: min(position.y + verticalLift, sceneSize.height * 0.92))
        let burstHeight = max(baseDominoHeight * 0.65, sceneSize.height * 0.08)
        let burstOrigin = CGPoint(x: 0, y: burstHeight / 2)
        let burstRange = CGVector(dx: 18, dy: burstHeight * 1.1)

        let coreEmitter = SKEmitterNode()
        coreEmitter.name = "explosionEmitter"
        coreEmitter.targetNode = scene
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
        scene.addChild(coreEmitter)

        let debrisEmitter = SKEmitterNode()
        debrisEmitter.name = "explosionEmitter"
        debrisEmitter.targetNode = scene
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
        scene.addChild(debrisEmitter)

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
        guard let scene else { return }
        let flash = SKShapeNode(circleOfRadius: 12)
        flash.name = "explosionEmitter"
        flash.fillColor = color.withAlphaComponent(0.9)
        flash.strokeColor = SKColor.white.withAlphaComponent(0.9)
        flash.lineWidth = 1.8
        flash.glowWidth = 8.0
        flash.alpha = 0
        flash.position = position
        flash.zPosition = 35
        scene.addChild(flash)

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
        guard let scene else { return }
        let smoke = SKEmitterNode()
        smoke.name = "explosionEmitter"
        smoke.targetNode = scene
        smoke.particleTexture = resolvedParticleTexture()

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
        scene.addChild(smoke)

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
                if points.count >= limit { return points }
                let u = (CGFloat(column) + 0.5) / CGFloat(columns)
                let v = (CGFloat(row) + 0.5) / CGFloat(rows)
                let jitterX = CGFloat.random(in: -frame.width * 0.07...frame.width * 0.07)
                let jitterY = CGFloat.random(in: -frame.height * 0.04...frame.height * 0.04)
                points.append(CGPoint(
                    x: frame.minX + frame.width * u + jitterX,
                    y: frame.minY + frame.height * v + jitterY
                ))
            }
        }
        return points
    }

    private func resolvedParticleTexture() -> SKTexture {
        if let cached = particleTexture { return cached }

        if let sparkImage = UIImage(named: "spark") {
            let texture = SKTexture(image: sparkImage)
            texture.filteringMode = .linear
            particleTexture = texture
            return texture
        }

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
                    gradient, startCenter: center, startRadius: 1,
                    endCenter: center, endRadius: rect.width * 0.5,
                    options: [.drawsAfterEndLocation]
                )
            } else {
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fillEllipse(in: rect)
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        particleTexture = texture
        return texture
    }
}
