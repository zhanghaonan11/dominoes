import Foundation
import CoreGraphics
import SpriteKit

let tower = SKNode()
let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
child1.position = CGPoint(x: 100, y: 100)
tower.addChild(child1)

let child2 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
child2.position = CGPoint(x: 10, y: 10)
child1.addChild(child2) // Nested

let scene = SKScene(size: CGSize(width: 500, height: 500))
scene.addChild(tower)

tower.enumerateChildNodes(withName: "//*") { node, _ in
    if let shape = node as? SKShapeNode {
        // node is nested. For child2, parent is child1.
        // Convert node position (which is in parent's coordinate space) to scene's space
        if let parent = node.parent {
            let pos = parent.convert(node.position, to: scene)
            print("pos: \(pos)")
        }
    }
}
