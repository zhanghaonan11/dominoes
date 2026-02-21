import Foundation
import CoreGraphics
import SpriteKit

let tower = SKNode()
for _ in 0..<3 {
    let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
    tower.addChild(child1)
}

let scene = SKScene(size: CGSize(width: 500, height: 500))
scene.addChild(tower)

var count = 0
tower.enumerateChildNodes(withName: "//*") { node, _ in
    if let shape = node as? SKShapeNode {
        shape.isHidden = true
        if Bool.random() && Bool.random() {
            if let parent = shape.parent {
                let positionInScene = parent.convert(shape.position, to: scene)
                print("pos: \(positionInScene)")
            }
        }
    }
}
