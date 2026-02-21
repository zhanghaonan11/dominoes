import Foundation
import CoreGraphics
import SpriteKit

let tower = SKNode()
for _ in 0..<3 {
    let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
    tower.addChild(child1)
}


for node in tower.children {
    print("child: \(node)")
}

var count = 0
tower.enumerateChildNodes(withName: "//*") { node, _ in
    count += 1
    if count > 1000 { return }
}
print("total nodes: \(count)")

