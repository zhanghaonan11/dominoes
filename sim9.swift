import Foundation
import CoreGraphics
import SpriteKit

let scene = SKScene(size: CGSize(width: 500, height: 500))
let tower = SKNode()
scene.addChild(tower)
for _ in 0..<300 {
    let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
    tower.addChild(child1)
}


var emitters = [SKEmitterNode]()
tower.enumerateChildNodes(withName: "//*") { node, _ in
    if let shape = node as? SKShapeNode {
        shape.isHidden = true
        if let parent = shape.parent {
            let pos = parent.convert(shape.position, to: scene)
            let emitter = SKEmitterNode()
            emitter.particleTexture = SKTexture()
            emitter.particleBirthRate = 500
            emitter.numParticlesToEmit = Int.random(in: 12...24)
            emitter.particleColor = .red
            emitter.position = pos
            scene.addChild(emitter)
            emitters.append(emitter)
        }
    }
}
print("Emitters added: \(emitters.count)")
