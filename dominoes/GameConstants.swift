//
//  GameConstants.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import UIKit
import SpriteKit

struct GameConstants {
    struct Physics {
        // Bitmasks
        static let domino: UInt32 = 1 << 0
        static let ball: UInt32 = 1 << 1
        static let ground: UInt32 = 1 << 2
        static let tower: UInt32 = 1 << 3
        
        // World (A: realistic-ish, but still stable)
        static let gravity = CGVector(dx: 0, dy: -9.2)
        
        // Domino tuning (A: more natural fall, less "sticky")
        static let dominoMass: CGFloat = 0.25
        static let dominoFriction: CGFloat = 0.80
        static let dominoRestitution: CGFloat = 0.07
        static let dominoLinearDamping: CGFloat = 0.20
        static let dominoAngularDamping: CGFloat = 0.65
        
        // Ball tuning
        static let ballFriction: CGFloat = 0.35
        static let ballRestitution: CGFloat = 0.12
        static let ballLinearDamping: CGFloat = 0.12
        static let ballAngularDamping: CGFloat = 0.08
        
        // Fallback nudger (anti-stall) — Option 2: keep it subtle and rare
        static let stallTimeout: TimeInterval = 1.6
        static let stallCheckInterval: TimeInterval = 0.6
        static let maxNudges = 1
        static let nudgeAngularImpulse: CGFloat = -0.03
        static let nudgeLinearImpulseX: CGFloat = -0.10
        
        // Fallen detection
        static let fallenAngleThreshold: CGFloat = 38 * .pi / 180
    }

    struct Colors {
        static let backgroundGradients = [
            // 0: 蓝天白云 (Blue Sky)
            (UIColor(red: 0.53, green: 0.80, blue: 0.98, alpha: 1.0), UIColor(red: 0.88, green: 0.96, blue: 1.0, alpha: 1.0)),
            // 1: 微妙紫霞 (Dawn)
            (UIColor(red: 0.85, green: 0.73, blue: 0.96, alpha: 1.0), UIColor(red: 0.98, green: 0.89, blue: 0.89, alpha: 1.0)),
            // 2: 温暖日落 (Sunset)
            (UIColor(red: 0.98, green: 0.61, blue: 0.45, alpha: 1.0), UIColor(red: 1.0, green: 0.85, blue: 0.65, alpha: 1.0)),
            // 3: 暮光幽蓝 (Twilight)
            (UIColor(red: 0.22, green: 0.26, blue: 0.44, alpha: 1.0), UIColor(red: 0.46, green: 0.35, blue: 0.55, alpha: 1.0)),
            // 4: 明亮薄荷 (Minty)
            (UIColor(red: 0.60, green: 0.89, blue: 0.81, alpha: 1.0), UIColor(red: 0.89, green: 0.98, blue: 0.87, alpha: 1.0))
        ]
        
        static let backgroundGradientStart = backgroundGradients[0].0
        static let backgroundGradientEnd = backgroundGradients[0].1
        static let groundMain = SKColor(red: 0.29, green: 0.85, blue: 0.51, alpha: 1.0)
        static let groundStrip = SKColor(red: 0.13, green: 0.77, blue: 0.37, alpha: 1.0)
        
        static let ballFill = SKColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0)
        static let ballStroke = SKColor(red: 0.12, green: 0.28, blue: 0.64, alpha: 1.0)
        
        static let textTitle = SKColor(white: 0.2, alpha: 1.0)
        static let textSubtitle = SKColor(white: 0.45, alpha: 1.0)
        static let textCountdown = SKColor(white: 0.35, alpha: 1.0)
        
        static let buttonBlueFill = SKColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0)
        static let buttonBlueText = SKColor.white
        static let buttonGrayFill = SKColor(white: 0.9, alpha: 1.0)
        static let buttonGrayText = SKColor(white: 0.25, alpha: 1.0)
        
        static let dominos = [
            SKColor(red: 0.93, green: 0.27, blue: 0.27, alpha: 1.0),
            SKColor(red: 0.97, green: 0.51, blue: 0.19, alpha: 1.0),
            SKColor(red: 0.91, green: 0.74, blue: 0.22, alpha: 1.0),
            SKColor(red: 0.17, green: 0.77, blue: 0.37, alpha: 1.0),
            SKColor(red: 0.13, green: 0.71, blue: 0.77, alpha: 1.0),
            SKColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0),
            SKColor(red: 0.66, green: 0.33, blue: 0.97, alpha: 1.0),
            SKColor(red: 0.92, green: 0.27, blue: 0.60, alpha: 1.0)
        ]
        
        // Tower Colors
        static let towerBase = SKColor(red: 0.33, green: 0.38, blue: 0.45, alpha: 1.0)
        static let towerMid = SKColor(red: 0.30, green: 0.35, blue: 0.43, alpha: 1.0)
        static let towerTop = SKColor(red: 0.26, green: 0.31, blue: 0.39, alpha: 1.0)
        static let towerMast = SKColor(red: 0.14, green: 0.18, blue: 0.26, alpha: 1.0)
        static let towerFlag = SKColor(red: 0.0, green: 0.36, blue: 0.7, alpha: 1.0)
        static let towerStroke = SKColor(white: 0.15, alpha: 0.5)
        static let towerHighlight = SKColor(white: 1.0, alpha: 0.25)
        static let towerShadow = SKColor(white: 0.0, alpha: 0.18)
    }
    
    struct Geometry {
        static let numDominos = 14
        static let autoResetDelay: Int = 3
    }
    
    static let autoResetActionKey = "autoResetCountdown"
}
