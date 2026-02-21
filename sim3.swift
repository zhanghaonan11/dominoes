import Foundation
import CoreGraphics
import SpriteKit

let tower = SKNode()
let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
child1.position = CGPoint(x: 100, y: 100)
tower.addChild(child1)
let child2 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
child2.position = CGPoint(x: 100, y: 100)
child1.addChild(child2) // nested child

var count = 0
tower.enumerateChildNodes(withName: "//*") { node, _ in
    count += 1
}
print("nested count: \(count)")
