import Foundation
import CoreGraphics
import SpriteKit

let tower = SKNode()
let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
child1.position = CGPoint(x: 10, y: 10)
tower.addChild(child1)
let child2 = SKShapeNode(rectOf: CGSize(width: 5, height: 5))
child1.addChild(child2) // nested inner
let grandChild = SKShapeNode(rectOf: CGSize(width: 2, height: 2))
child2.addChild(grandChild) // double nested

let scene = SKScene(size: CGSize(width: 500, height: 500))
scene.addChild(tower)

tower.enumerateChildNodes(withName: "//*") { node, _ in
    if let shape = node as? SKShapeNode {
        // Here we want to convert shape's center to scene's coordinate system.
        // Option 1: parent.convert(shape.position, to: scene)
        if let parent = shape.parent {
            let p1 = parent.convert(shape.position, to: scene)
            // Option 2: shape.convert(CGPoint.zero, to: scene) Since shape.position IS CGPoint.zero in its own coordinates
            let p2 = shape.convert(CGPoint.zero, to: scene) // Actually scene might be scene!
            print("p1: \(p1), p2: \(p2)")
        }
    }
}
