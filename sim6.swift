import Foundation
import CoreGraphics
import SpriteKit

let tower = SKNode()
let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
child1.position = CGPoint(x: 100, y: 100)
tower.addChild(child1)

let scene = SKScene(size: CGSize(width: 500, height: 500))
scene.addChild(tower)

tower.enumerateChildNodes(withName: "//*") { node, stop in
    if let shape = node as? SKShapeNode {
        if let parent = shape.parent {
            // Is it possible parent is nil? No, enumerateChildNodes only finds nodes in the tree.
            // But if it's the scene? No, we search from tower.
            let pos = parent.convert(shape.position, to: scene)
            print("pos: \(pos)")
        }
    }
}
