//
//  StaircaseNode.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import SpriteKit

final class StaircaseNode: SKNode {
    
    struct StairPathPoint {
        let position: CGPoint
        let zPosition: CGFloat
        let scale: CGFloat
    }
    
    private(set) var rollPath: [StairPathPoint] = []
    private weak var guideGlowNode: SKShapeNode?
    private weak var guideLineNode: SKShapeNode?
    
    static func build(startX: CGFloat, groundY: CGFloat, height: CGFloat, ballRadius: CGFloat, guideColor: SKColor) -> StaircaseNode {
        let node = StaircaseNode()
        
        let pathSegments = 10
        let stepDrop = height / CGFloat(pathSegments)
        let maxOffset: CGFloat = 98
        let minOffset: CGFloat = 28
        
        var guidePoints: [CGPoint] = []
        
        let sagDepth = height * 0.08
        
        for i in 0...pathSegments {
            let phase = CGFloat(i) / CGFloat(pathSegments)
            let eased = pow(phase, 1.35)
            let xOffset = lerp(from: maxOffset, to: minOffset, t: eased)
            let bend = sin(.pi * phase) * 12.0
            let depth = 0.35 + sin(.pi * phase) * 0.65
            let sag = sin(.pi * phase) * sagDepth
            
            let point = CGPoint(
                x: startX - xOffset + bend,
                y: groundY + height - CGFloat(i) * stepDrop + ballRadius * 0.16 - sag
            )
            guidePoints.append(point)
            
            node.rollPath.append(
                StairPathPoint(
                    position: point,
                    zPosition: depth > 0.52 ? 3.6 : 1.2,
                    scale: 0.9 + depth * 0.16
                )
            )
        }
        
        if let last = node.rollPath.last {
            // Keep the endpoint slightly lower than the last stair point so the guide ends cleanly
            // without the upward hook near the ground.
            let exitY = max(groundY + ballRadius * 0.1, last.position.y - ballRadius * 0.18)
            let exitPoint = CGPoint(
                x: (last.position.x + startX) * 0.56,
                y: exitY
            )
            guidePoints.append(exitPoint)
            node.rollPath.append(StairPathPoint(position: exitPoint, zPosition: 3.35, scale: 1.03))
        }
        
        let smoothPath = makeSmoothPath(points: guidePoints)
        
        let guideGlow = SKShapeNode(path: smoothPath)
        guideGlow.name = "guideLineTarget"
        guideGlow.strokeColor = guideColor.withAlphaComponent(0.18)
        guideGlow.lineWidth = 10
        guideGlow.lineCap = .round
        guideGlow.lineJoin = .round
        guideGlow.zPosition = 0.2
        node.addChild(guideGlow)
        node.guideGlowNode = guideGlow
        
        let guideLine = SKShapeNode(path: smoothPath)
        guideLine.name = "guideLineTarget"
        guideLine.strokeColor = guideColor.withAlphaComponent(0.95)
        guideLine.lineWidth = 3.2
        guideLine.lineCap = .round
        guideLine.lineJoin = .round
        guideLine.glowWidth = 0.9
        guideLine.zPosition = 0.3
        node.addChild(guideLine)
        node.guideLineNode = guideLine
        
        return node
    }

    func updateGuideColor(_ color: SKColor) {
        guideGlowNode?.strokeColor = color.withAlphaComponent(0.18)
        guideLineNode?.strokeColor = color.withAlphaComponent(0.95)
    }
    
    private static func makeSmoothPath(points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = points.first else { return path }
        path.move(to: first)
        
        guard points.count > 1 else { return path }
        
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midpoint = CGPoint(x: (previous.x + current.x) * 0.5, y: (previous.y + current.y) * 0.5)
            
            if index == 1 {
                path.addLine(to: midpoint)
            } else {
                path.addQuadCurve(to: midpoint, control: previous)
            }
            
            if index == points.count - 1 {
                path.addLine(to: current)
            }
        }
        
        return path
    }
    
    private static func normalizedDepth(for angle: CGFloat) -> CGFloat {
        let depth = (sin(angle) + 1) * 0.5
        return max(0, min(1, depth))
    }
    
    private static func lerp(from start: CGFloat, to end: CGFloat, t: CGFloat) -> CGFloat {
        start + (end - start) * t
    }
}
