import Foundation
import CoreGraphics
import SpriteKit

let tower = SKNode()
for _ in 0..<100 {
    let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
    tower.addChild(child1)
}

let scene = SKScene(size: CGSize(width: 500, height: 500))
scene.addChild(tower)

var count = 0
tower.enumerateChildNodes(withName: "//*") { node, _ in
    if let shape = node as? SKShapeNode {
        shape.isHidden = true
        count += 1
    }
}
print("count: \(count)")

