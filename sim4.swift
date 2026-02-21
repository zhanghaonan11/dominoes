import Foundation
import CoreGraphics
import SpriteKit

let tower = SKNode()
let child1 = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
child1.position = CGPoint(x: 100, y: 100)
tower.addChild(child1)

let scene = SKScene(size: CGSize(width: 500, height: 500))
scene.addChild(tower)

tower.enumerateChildNodes(withName: "//*") { node, _ in
    if let shape = node as? SKShapeNode {
        let pos = tower.convert(shape.position, to: scene) // The crash might be here since shape is already in tower? Or maybe `convert` is used wrong: shape.position is in tower's coordinate space? wait, shape.position IS in tower's coordinate space. No, `shape.position` is in its parent's coordinate space.
        print("pos: \(pos)")
    }
}
