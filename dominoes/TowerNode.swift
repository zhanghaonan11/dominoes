//
//  TowerNode.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import SpriteKit
import UIKit

final class TowerNode: SKNode {
    enum Landmark: CaseIterable {
        case eiffelTower
        case bigBen
        case leaningTowerOfPisa
        case sydneyOperaHouse
        case greatPyramidOfGiza
        case burjKhalifa
        case tajMahal
        case colosseum
        case arcDeTriomphe
        case empireStateBuilding

        var thumbnailIcon: String {
            switch self {
            case .eiffelTower:
                return "🗼"
            case .bigBen:
                return "🕰️"
            case .leaningTowerOfPisa:
                return "🗼"
            case .sydneyOperaHouse:
                return "🎭"
            case .greatPyramidOfGiza:
                return "🔺"
            case .burjKhalifa:
                return "🏙️"
            case .tajMahal:
                return "🕌"
            case .colosseum:
                return "🏟️"
            case .arcDeTriomphe:
                return "🏛️"
            case .empireStateBuilding:
                return "🌆"
            }
        }

        var englishName: String {
            switch self {
            case .eiffelTower:
                return "Eiffel Tower"
            case .bigBen:
                return "Big Ben"
            case .leaningTowerOfPisa:
                return "Leaning Tower of Pisa"
            case .sydneyOperaHouse:
                return "Sydney Opera House"
            case .greatPyramidOfGiza:
                return "Great Pyramid of Giza"
            case .burjKhalifa:
                return "Burj Khalifa"
            case .tajMahal:
                return "Taj Mahal"
            case .colosseum:
                return "Colosseum"
            case .arcDeTriomphe:
                return "Arc de Triomphe"
            case .empireStateBuilding:
                return "Empire State Building"
            }
        }

        var displayName: String {
            switch self {
            case .eiffelTower:
                return "埃菲尔铁塔"
            case .bigBen:
                return "大本钟"
            case .leaningTowerOfPisa:
                return "比萨斜塔"
            case .sydneyOperaHouse:
                return "悉尼歌剧院"
            case .greatPyramidOfGiza:
                return "吉萨大金字塔"
            case .burjKhalifa:
                return "哈利法塔"
            case .tajMahal:
                return "泰姬陵"
            case .colosseum:
                return "罗马斗兽场"
            case .arcDeTriomphe:
                return "凯旋门"
            case .empireStateBuilding:
                return "帝国大厦"
            }
        }
    }

    private struct Palette {
        static let stroke = SKColor(white: 0.13, alpha: 0.5)
        static let deepShadow = SKColor(white: 0.0, alpha: 0.2)
        static let facadeHighlight = SKColor(white: 1.0, alpha: 0.2)
        static let facadeShade = SKColor(white: 0.0, alpha: 0.14)
        static let glass = SKColor(red: 0.68, green: 0.82, blue: 0.95, alpha: 1.0)
        static let warmLight = SKColor(red: 1.0, green: 0.87, blue: 0.65, alpha: 1.0)
        static let darkWindow = SKColor(red: 0.22, green: 0.27, blue: 0.34, alpha: 0.85)
        static let stone = SKColor(red: 0.88, green: 0.82, blue: 0.72, alpha: 1.0)
        static let steel = SKColor(red: 0.53, green: 0.60, blue: 0.69, alpha: 1.0)
    }

    private struct LandmarkTextureCacheKey: Hashable {
        let landmark: Landmark
        let pixelWidth: Int
    }

    private struct CachedLandmarkTexture {
        let texture: SKTexture
        let spriteSize: CGSize
        let spritePosition: CGPoint
    }

    private static let texturePadding: CGFloat = 2
    private static var landmarkTextureCache: [LandmarkTextureCacheKey: CachedLandmarkTexture] = [:]
    private static let textureRenderView = SKView()

    static func build(width: CGFloat, landmark: Landmark) -> SKNode {
        let node = SKNode()

        if let rendered = renderedLandmarkTexture(width: width, landmark: landmark) {
            let sprite = SKSpriteNode(texture: rendered.texture, size: rendered.spriteSize)
            sprite.position = rendered.spritePosition
            sprite.zPosition = 1
            node.addChild(sprite)
        } else {
            node.addChild(buildLandmarkVector(width: width, landmark: landmark))
        }

        let towerFrame = node.calculateAccumulatedFrame()

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.name = "towerNameLabel"
        label.text = landmark.displayName
        label.fontSize = max(width * 0.15, 10)
        label.fontColor = SKColor(white: 0.2, alpha: 0.95)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .bottom
        label.position = CGPoint(x: 0, y: towerFrame.maxY + max(8, width * 0.05))
        label.zPosition = 20
        node.addChild(label)

        return node
    }

    private static func buildLandmarkVector(width: CGFloat, landmark: Landmark) -> SKNode {
        switch landmark {
        case .eiffelTower:
            return buildEiffelTower(width: width)
        case .bigBen:
            return buildBigBen(width: width)
        case .leaningTowerOfPisa:
            return buildLeaningTowerOfPisa(width: width)
        case .sydneyOperaHouse:
            return buildSydneyOperaHouse(width: width)
        case .greatPyramidOfGiza:
            return buildGreatPyramidOfGiza(width: width)
        case .burjKhalifa:
            return buildBurjKhalifa(width: width)
        case .tajMahal:
            return buildTajMahal(width: width)
        case .colosseum:
            return buildColosseum(width: width)
        case .arcDeTriomphe:
            return buildArcDeTriomphe(width: width)
        case .empireStateBuilding:
            return buildEmpireStateBuilding(width: width)
        }
    }

    private static func renderedLandmarkTexture(width: CGFloat, landmark: Landmark) -> CachedLandmarkTexture? {
        let scale = max(UIScreen.main.scale, 1)
        let pixelWidth = max(1, Int((width * scale).rounded()))
        let key = LandmarkTextureCacheKey(landmark: landmark, pixelWidth: pixelWidth)

        if let cached = landmarkTextureCache[key] {
            return cached
        }

        let vectorNode = buildLandmarkVector(width: width, landmark: landmark)
        let frame = vectorNode.calculateAccumulatedFrame()
        guard !frame.isNull, frame.width > 0, frame.height > 0 else { return nil }

        let paddedFrame = frame.insetBy(dx: -texturePadding, dy: -texturePadding)
        let croppedTexture = textureRenderView.texture(from: vectorNode, crop: paddedFrame)
        let texture = croppedTexture ?? textureRenderView.texture(from: vectorNode)
        guard let texture else { return nil }

        texture.filteringMode = .linear

        let cachedTexture = CachedLandmarkTexture(
            texture: texture,
            spriteSize: croppedTexture == nil ? texture.size() : paddedFrame.size,
            spritePosition: croppedTexture == nil
                ? CGPoint(x: frame.midX, y: frame.midY)
                : CGPoint(x: paddedFrame.midX, y: paddedFrame.midY)
        )
        landmarkTextureCache[key] = cachedTexture
        return cachedTexture
    }

    static func heightFactor(for landmark: Landmark) -> CGFloat {
        switch landmark {
        case .eiffelTower:
            return 2.51
        case .bigBen:
            return 2.76
        case .leaningTowerOfPisa:
            return 2.26
        case .sydneyOperaHouse:
            return 1.46
        case .greatPyramidOfGiza:
            return 1.40
        case .burjKhalifa:
            return 3.08
        case .tajMahal:
            return 1.28
        case .colosseum:
            return 0.82
        case .arcDeTriomphe:
            return 1.15
        case .empireStateBuilding:
            return 2.88
        }
    }

    // MARK: - Shared Rendering Helpers

    private static func addGroundShadow(to node: SKNode, width: CGFloat, yOffset: CGFloat = 0, alpha: CGFloat = 0.2) {
        let shadow = SKShapeNode(ellipseOf: CGSize(width: width, height: width * 0.2))
        shadow.fillColor = SKColor(white: 0.0, alpha: alpha)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: yOffset)
        shadow.zPosition = -30
        node.addChild(shadow)
    }

    private static func makeRect(_ rect: CGRect, cornerRadius: CGFloat, fill: SKColor, stroke: SKColor = Palette.stroke, lineWidth: CGFloat = 1) -> SKShapeNode {
        let shape = SKShapeNode(rect: rect, cornerRadius: cornerRadius)
        shape.fillColor = fill
        shape.strokeColor = stroke
        shape.lineWidth = lineWidth
        return shape
    }

    private static func makePolygon(_ points: [CGPoint], fill: SKColor, stroke: SKColor = Palette.stroke, lineWidth: CGFloat = 1) -> SKShapeNode {
        let path = CGMutablePath()
        guard let first = points.first else {
            return SKShapeNode()
        }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        let shape = SKShapeNode(path: path)
        shape.fillColor = fill
        shape.strokeColor = stroke
        shape.lineWidth = lineWidth
        return shape
    }

    private static func addFacadeLighting(to node: SKNode, rect: CGRect, cornerRadius: CGFloat = 1) {
        let highlight = SKShapeNode(
            rect: CGRect(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.02, width: rect.width * 0.18, height: rect.height * 0.95),
            cornerRadius: cornerRadius
        )
        highlight.fillColor = Palette.facadeHighlight
        highlight.strokeColor = .clear
        highlight.zPosition = 2
        node.addChild(highlight)

        let shade = SKShapeNode(
            rect: CGRect(x: rect.maxX - rect.width * 0.22, y: rect.minY + rect.height * 0.01, width: rect.width * 0.2, height: rect.height * 0.96),
            cornerRadius: cornerRadius
        )
        shade.fillColor = Palette.facadeShade
        shade.strokeColor = .clear
        shade.zPosition = 2
        node.addChild(shade)
    }

    private static func addWindowGrid(
        to node: SKNode,
        rect: CGRect,
        columns: Int,
        rows: Int,
        insetX: CGFloat,
        insetY: CGFloat,
        z: CGFloat = 3
    ) {
        guard columns > 0, rows > 0 else { return }
        let availableWidth = rect.width - insetX * 2
        let availableHeight = rect.height - insetY * 2
        guard availableWidth > 0, availableHeight > 0 else { return }

        let slotW = availableWidth / CGFloat(columns)
        let slotH = availableHeight / CGFloat(rows)
        let windowSize = CGSize(width: slotW * 0.42, height: slotH * 0.46)

        for row in 0..<rows {
            for col in 0..<columns {
                let x = rect.minX + insetX + slotW * (CGFloat(col) + 0.5)
                let y = rect.minY + insetY + slotH * (CGFloat(row) + 0.5)
                let window = SKShapeNode(rectOf: windowSize, cornerRadius: 0.5)
                let lit = (row * 5 + col * 3) % 7 == 0
                window.fillColor = lit ? Palette.warmLight.withAlphaComponent(0.65) : Palette.darkWindow
                window.strokeColor = .clear
                window.position = CGPoint(x: x, y: y)
                window.zPosition = z
                node.addChild(window)
            }
        }
    }

    private static func addHorizontalBands(to node: SKNode, rect: CGRect, count: Int, color: SKColor, z: CGFloat = 3) {
        guard count > 0 else { return }
        for index in 1..<count {
            let y = rect.minY + rect.height * CGFloat(index) / CGFloat(count)
            let band = SKShapeNode(rectOf: CGSize(width: rect.width * 0.96, height: 1.2))
            band.position = CGPoint(x: rect.midX, y: y)
            band.fillColor = color
            band.strokeColor = .clear
            band.zPosition = z
            node.addChild(band)
        }
    }

    /// Creates a filled arch shape: a rectangle topped with a semicircular arc.
    /// The rect's origin is at (x, y) with given width/height; the semicircle sits on top.
    private static func makeArch(x: CGFloat, y: CGFloat, width: CGFloat, rectHeight: CGFloat, fill: SKColor, stroke: SKColor = .clear, lineWidth: CGFloat = 0) -> SKShapeNode {
        let path = CGMutablePath()
        let halfW = width / 2
        let cx = x + halfW
        // Start bottom-left, go up left side, arc across top, down right side
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x, y: y + rectHeight))
        path.addArc(center: CGPoint(x: cx, y: y + rectHeight), radius: halfW, startAngle: .pi, endAngle: 0, clockwise: false)
        path.addLine(to: CGPoint(x: x + width, y: y))
        path.closeSubpath()
        let shape = SKShapeNode(path: path)
        shape.fillColor = fill
        shape.strokeColor = stroke
        shape.lineWidth = lineWidth
        return shape
    }

    private static func addSoftSpecularLine(to node: SKNode, from: CGPoint, to: CGPoint, alpha: CGFloat = 0.25, lineWidth: CGFloat = 1) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor(white: 1.0, alpha: alpha)
        line.lineWidth = lineWidth
        line.zPosition = 3
        node.addChild(line)
    }

    // MARK: - Landmarks

    private static func buildEiffelTower(width: CGFloat) -> SKNode {
        let node = SKNode()
        let ironDark = SKColor(red: 0.30, green: 0.33, blue: 0.38, alpha: 1.0)
        let ironMid  = SKColor(red: 0.36, green: 0.40, blue: 0.46, alpha: 1.0)
        let ironLite = SKColor(red: 0.42, green: 0.46, blue: 0.52, alpha: 1.0)
        let deckColor = SKColor(red: 0.27, green: 0.31, blue: 0.37, alpha: 1.0)
        addGroundShadow(to: node, width: width * 0.95, yOffset: -width * 0.03, alpha: 0.22)

        // --- Left leg (curved) ---
        let leftLeg = CGMutablePath()
        leftLeg.move(to: CGPoint(x: -width * 0.50, y: 0))
        leftLeg.addQuadCurve(to: CGPoint(x: -width * 0.14, y: width * 0.88),
                             control: CGPoint(x: -width * 0.42, y: width * 0.55))
        leftLeg.addLine(to: CGPoint(x: -width * 0.06, y: width * 0.88))
        leftLeg.addQuadCurve(to: CGPoint(x: -width * 0.22, y: 0),
                             control: CGPoint(x: -width * 0.18, y: width * 0.45))
        leftLeg.closeSubpath()
        let leftLegNode = SKShapeNode(path: leftLeg)
        leftLegNode.fillColor = ironMid
        leftLegNode.strokeColor = Palette.stroke
        leftLegNode.lineWidth = 1
        node.addChild(leftLegNode)

        // --- Right leg (curved) ---
        let rightLeg = CGMutablePath()
        rightLeg.move(to: CGPoint(x: width * 0.50, y: 0))
        rightLeg.addQuadCurve(to: CGPoint(x: width * 0.14, y: width * 0.88),
                              control: CGPoint(x: width * 0.42, y: width * 0.55))
        rightLeg.addLine(to: CGPoint(x: width * 0.06, y: width * 0.88))
        rightLeg.addQuadCurve(to: CGPoint(x: width * 0.22, y: 0),
                              control: CGPoint(x: width * 0.18, y: width * 0.45))
        rightLeg.closeSubpath()
        let rightLegNode = SKShapeNode(path: rightLeg)
        rightLegNode.fillColor = ironMid
        rightLegNode.strokeColor = Palette.stroke
        rightLegNode.lineWidth = 1
        node.addChild(rightLegNode)

        // --- Base arch opening between legs ---
        let archPath = CGMutablePath()
        archPath.move(to: CGPoint(x: -width * 0.22, y: 0))
        archPath.addQuadCurve(to: CGPoint(x: width * 0.22, y: 0),
                              control: CGPoint(x: 0, y: width * 0.42))
        let archLine = SKShapeNode(path: archPath)
        archLine.strokeColor = ironDark
        archLine.lineWidth = 1.2
        archLine.fillColor = .clear
        archLine.zPosition = 2
        node.addChild(archLine)

        // --- First observation deck ---
        let firstDeck = makeRect(
            CGRect(x: -width * 0.30, y: width * 0.83, width: width * 0.60, height: width * 0.08),
            cornerRadius: 1, fill: deckColor, stroke: .clear, lineWidth: 0
        )
        firstDeck.zPosition = 3
        node.addChild(firstDeck)

        // Arch under first deck
        let deckArchPath = CGMutablePath()
        deckArchPath.move(to: CGPoint(x: -width * 0.14, y: width * 0.72))
        deckArchPath.addQuadCurve(to: CGPoint(x: width * 0.14, y: width * 0.72),
                                  control: CGPoint(x: 0, y: width * 0.86))
        let deckArch = SKShapeNode(path: deckArchPath)
        deckArch.strokeColor = ironDark.withAlphaComponent(0.6)
        deckArch.lineWidth = 1
        deckArch.fillColor = .clear
        deckArch.zPosition = 2
        node.addChild(deckArch)

        // --- Middle section (tapered) ---
        let midPath = CGMutablePath()
        midPath.move(to: CGPoint(x: -width * 0.14, y: width * 0.91))
        midPath.addQuadCurve(to: CGPoint(x: -width * 0.06, y: width * 1.72),
                             control: CGPoint(x: -width * 0.12, y: width * 1.3))
        midPath.addLine(to: CGPoint(x: width * 0.06, y: width * 1.72))
        midPath.addQuadCurve(to: CGPoint(x: width * 0.14, y: width * 0.91),
                             control: CGPoint(x: width * 0.12, y: width * 1.3))
        midPath.closeSubpath()
        let midNode = SKShapeNode(path: midPath)
        midNode.fillColor = ironLite
        midNode.strokeColor = Palette.stroke
        midNode.lineWidth = 1
        node.addChild(midNode)

        // --- Second observation deck ---
        let secondDeck = makeRect(
            CGRect(x: -width * 0.18, y: width * 1.68, width: width * 0.36, height: width * 0.06),
            cornerRadius: 1, fill: deckColor, stroke: .clear, lineWidth: 0
        )
        secondDeck.zPosition = 3
        node.addChild(secondDeck)

        // --- Top section ---
        let topPath = CGMutablePath()
        topPath.move(to: CGPoint(x: -width * 0.06, y: width * 1.74))
        topPath.addLine(to: CGPoint(x: -width * 0.035, y: width * 2.18))
        topPath.addLine(to: CGPoint(x: width * 0.035, y: width * 2.18))
        topPath.addLine(to: CGPoint(x: width * 0.06, y: width * 1.74))
        topPath.closeSubpath()
        let topNode = SKShapeNode(path: topPath)
        topNode.fillColor = ironDark
        topNode.strokeColor = Palette.stroke
        topNode.lineWidth = 1
        node.addChild(topNode)

        // --- Mast / antenna ---
        let mast = SKShapeNode(rectOf: CGSize(width: 2.2, height: width * 0.32))
        mast.position = CGPoint(x: 0, y: width * 2.35)
        mast.fillColor = SKColor(red: 0.18, green: 0.22, blue: 0.29, alpha: 1.0)
        mast.strokeColor = .clear
        mast.zPosition = 4
        node.addChild(mast)

        // --- Lattice cross-braces (dense) ---
        let bracePath = CGMutablePath()
        // Lower section cross-braces
        for i in 0..<5 {
            let t = CGFloat(i) / 5
            let y0 = width * (0.10 + t * 0.72)
            let y1 = width * (0.10 + (t + 0.2) * 0.72)
            let xL0 = -width * (0.44 - t * 0.36) * 0.7
            let xR0 =  width * (0.44 - t * 0.36) * 0.7
            let xL1 = -width * (0.44 - (t + 0.2) * 0.36) * 0.7
            let xR1 =  width * (0.44 - (t + 0.2) * 0.36) * 0.7
            bracePath.move(to: CGPoint(x: xL0, y: y0))
            bracePath.addLine(to: CGPoint(x: xR1, y: y1))
            bracePath.move(to: CGPoint(x: xR0, y: y0))
            bracePath.addLine(to: CGPoint(x: xL1, y: y1))
        }
        // Middle section cross-braces
        for i in 0..<4 {
            let t = CGFloat(i) / 4
            let y0 = width * (0.95 + t * 0.72)
            let y1 = width * (0.95 + (t + 0.25) * 0.72)
            let xL0 = -width * (0.12 - t * 0.06)
            let xR0 =  width * (0.12 - t * 0.06)
            let xL1 = -width * (0.12 - (t + 0.25) * 0.06)
            let xR1 =  width * (0.12 - (t + 0.25) * 0.06)
            bracePath.move(to: CGPoint(x: xL0, y: y0))
            bracePath.addLine(to: CGPoint(x: xR1, y: y1))
            bracePath.move(to: CGPoint(x: xR0, y: y0))
            bracePath.addLine(to: CGPoint(x: xL1, y: y1))
        }
        let braces = SKShapeNode(path: bracePath)
        braces.strokeColor = SKColor(white: 0.12, alpha: 0.45)
        braces.lineWidth = 0.8
        braces.zPosition = 4
        node.addChild(braces)

        // --- Horizontal bands ---
        let bandPath = CGMutablePath()
        let bandYs: [CGFloat] = [0.20, 0.40, 0.60, 1.05, 1.25, 1.45, 1.85, 2.0]
        for by in bandYs {
            let y = width * by
            // Approximate half-width at this height
            let hw: CGFloat
            if by < 0.88 {
                hw = width * (0.44 - by * 0.36) * 0.72
            } else if by < 1.72 {
                let t = (by - 0.88) / 0.84
                hw = width * (0.13 - t * 0.07)
            } else {
                let t = (by - 1.74) / 0.44
                hw = width * (0.055 - t * 0.02)
            }
            bandPath.move(to: CGPoint(x: -hw, y: y))
            bandPath.addLine(to: CGPoint(x: hw, y: y))
        }
        let bands = SKShapeNode(path: bandPath)
        bands.strokeColor = SKColor(white: 0.15, alpha: 0.35)
        bands.lineWidth = 1
        bands.zPosition = 5
        node.addChild(bands)

        // --- Specular highlight on left leg ---
        addSoftSpecularLine(to: node,
                            from: CGPoint(x: -width * 0.40, y: width * 0.08),
                            to: CGPoint(x: -width * 0.20, y: width * 0.80), alpha: 0.22)

        return node
    }

    private static func buildBigBen(width: CGFloat) -> SKNode {
        let node = SKNode()
        let sandstone = SKColor(red: 0.78, green: 0.66, blue: 0.48, alpha: 1.0)
        let sandstoneDark = SKColor(red: 0.67, green: 0.55, blue: 0.38, alpha: 1.0)
        let roofColor = SKColor(red: 0.58, green: 0.48, blue: 0.33, alpha: 1.0)
        addGroundShadow(to: node, width: width * 0.85, yOffset: -width * 0.02, alpha: 0.2)

        // --- Parliament base building (low, wide) ---
        let parlRect = CGRect(x: -width * 0.42, y: 0, width: width * 0.84, height: width * 0.52)
        let parl = makeRect(parlRect, cornerRadius: 2, fill: sandstone, lineWidth: 0.8)
        node.addChild(parl)
        addFacadeLighting(to: node, rect: parlRect, cornerRadius: 2)
        // Parliament windows
        addWindowGrid(to: node, rect: CGRect(x: -width * 0.38, y: width * 0.06, width: width * 0.76, height: width * 0.38), columns: 6, rows: 3, insetX: width * 0.03, insetY: width * 0.03)
        // Parliament roof line
        let parlRoof = makeRect(CGRect(x: -width * 0.44, y: width * 0.48, width: width * 0.88, height: width * 0.04), cornerRadius: 1, fill: sandstoneDark, stroke: .clear, lineWidth: 0)
        parlRoof.zPosition = 2
        node.addChild(parlRoof)

        // --- Main tower body (4 tiers) ---
        let towerX = -width * 0.18
        let towerW = width * 0.36
        let tier1 = CGRect(x: towerX, y: width * 0.52, width: towerW, height: width * 0.42)
        let tier1Node = makeRect(tier1, cornerRadius: 2, fill: sandstone, lineWidth: 0.9)
        node.addChild(tier1Node)
        // Gothic pointed arch windows on tier 1
        for i in 0..<3 {
            let ax = towerX + width * 0.05 + CGFloat(i) * width * 0.11
            let archNode = makeArch(x: ax, y: width * 0.58, width: width * 0.07, rectHeight: width * 0.18, fill: Palette.darkWindow)
            archNode.zPosition = 3
            node.addChild(archNode)
        }
        // Decorative band between tier 1 and 2
        let band1 = makeRect(CGRect(x: towerX - width * 0.02, y: width * 0.92, width: towerW + width * 0.04, height: width * 0.03), cornerRadius: 1, fill: sandstoneDark, stroke: .clear, lineWidth: 0)
        band1.zPosition = 2
        node.addChild(band1)

        let tier2 = CGRect(x: towerX, y: width * 0.95, width: towerW, height: width * 0.42)
        let tier2Node = makeRect(tier2, cornerRadius: 2, fill: sandstone, lineWidth: 0.9)
        node.addChild(tier2Node)
        // Gothic windows on tier 2
        for i in 0..<3 {
            let ax = towerX + width * 0.05 + CGFloat(i) * width * 0.11
            let archNode = makeArch(x: ax, y: width * 1.01, width: width * 0.07, rectHeight: width * 0.18, fill: Palette.darkWindow)
            archNode.zPosition = 3
            node.addChild(archNode)
        }
        // Band between tier 2 and 3
        let band2 = makeRect(CGRect(x: towerX - width * 0.02, y: width * 1.35, width: towerW + width * 0.04, height: width * 0.03), cornerRadius: 1, fill: sandstoneDark, stroke: .clear, lineWidth: 0)
        band2.zPosition = 2
        node.addChild(band2)

        // Tier 3 — clock level
        let tier3 = CGRect(x: towerX, y: width * 1.38, width: towerW, height: width * 0.42)
        let tier3Node = makeRect(tier3, cornerRadius: 2, fill: sandstone, lineWidth: 0.9)
        node.addChild(tier3Node)
        addFacadeLighting(to: node, rect: tier3, cornerRadius: 2)

        // Clock face
        let clockFrame = SKShapeNode(circleOfRadius: width * 0.12)
        clockFrame.position = CGPoint(x: 0, y: width * 1.60)
        clockFrame.fillColor = SKColor(white: 0.95, alpha: 1.0)
        clockFrame.strokeColor = SKColor(red: 0.52, green: 0.43, blue: 0.31, alpha: 1.0)
        clockFrame.lineWidth = 1.6
        clockFrame.zPosition = 4
        node.addChild(clockFrame)
        let clockFace = SKShapeNode(circleOfRadius: width * 0.09)
        clockFace.position = CGPoint(x: 0, y: width * 1.60)
        clockFace.fillColor = SKColor(white: 0.99, alpha: 1.0)
        clockFace.strokeColor = SKColor(white: 0.12, alpha: 0.35)
        clockFace.lineWidth = 0.6
        clockFace.zPosition = 5
        node.addChild(clockFace)
        // Clock hands
        let handPath = CGMutablePath()
        handPath.move(to: CGPoint(x: 0, y: width * 1.60))
        handPath.addLine(to: CGPoint(x: width * 0.05, y: width * 1.64))
        handPath.move(to: CGPoint(x: 0, y: width * 1.60))
        handPath.addLine(to: CGPoint(x: -width * 0.03, y: width * 1.57))
        let hands = SKShapeNode(path: handPath)
        hands.strokeColor = SKColor(white: 0.2, alpha: 0.8)
        hands.lineWidth = 1.2
        hands.zPosition = 6
        node.addChild(hands)

        // Band between tier 3 and 4
        let band3 = makeRect(CGRect(x: towerX - width * 0.02, y: width * 1.78, width: towerW + width * 0.04, height: width * 0.03), cornerRadius: 1, fill: sandstoneDark, stroke: .clear, lineWidth: 0)
        band3.zPosition = 2
        node.addChild(band3)

        // Tier 4 — belfry
        let tier4 = CGRect(x: towerX + width * 0.02, y: width * 1.81, width: towerW - width * 0.04, height: width * 0.28)
        let tier4Node = makeRect(tier4, cornerRadius: 2, fill: sandstone, lineWidth: 0.9)
        node.addChild(tier4Node)
        // Belfry arched openings
        for i in 0..<2 {
            let ax = towerX + width * 0.06 + CGFloat(i) * width * 0.14
            let archNode = makeArch(x: ax, y: width * 1.84, width: width * 0.1, rectHeight: width * 0.12, fill: Palette.darkWindow.withAlphaComponent(0.6))
            archNode.zPosition = 3
            node.addChild(archNode)
        }

        // --- Steep pyramidal roof ---
        let roof = makePolygon(
            [
                CGPoint(x: -width * 0.22, y: width * 2.09),
                CGPoint(x: 0, y: width * 2.58),
                CGPoint(x: width * 0.22, y: width * 2.09)
            ],
            fill: roofColor, lineWidth: 1
        )
        roof.zPosition = 2
        node.addChild(roof)
        // Roof shade on right
        let roofShade = makePolygon(
            [
                CGPoint(x: 0, y: width * 2.58),
                CGPoint(x: width * 0.22, y: width * 2.09),
                CGPoint(x: width * 0.06, y: width * 2.09)
            ],
            fill: SKColor(white: 0.0, alpha: 0.16), stroke: .clear, lineWidth: 0
        )
        roofShade.zPosition = 3
        node.addChild(roofShade)

        // --- Corner pinnacles ---
        for xSign: CGFloat in [-1, 1] {
            let px = xSign * width * 0.20
            let pinnacle = SKShapeNode(rectOf: CGSize(width: width * 0.04, height: width * 0.22), cornerRadius: 1)
            pinnacle.position = CGPoint(x: px, y: width * 2.18)
            pinnacle.fillColor = sandstoneDark
            pinnacle.strokeColor = .clear
            pinnacle.zPosition = 4
            node.addChild(pinnacle)
            // Pinnacle tip
            let tip = makePolygon(
                [
                    CGPoint(x: px - width * 0.02, y: width * 2.29),
                    CGPoint(x: px, y: width * 2.38),
                    CGPoint(x: px + width * 0.02, y: width * 2.29)
                ],
                fill: sandstoneDark, stroke: .clear, lineWidth: 0
            )
            tip.zPosition = 5
            node.addChild(tip)
        }

        // --- Spire ---
        let spire = SKShapeNode(rectOf: CGSize(width: 2.5, height: width * 0.2))
        spire.position = CGPoint(x: 0, y: width * 2.66)
        spire.fillColor = SKColor(red: 0.42, green: 0.35, blue: 0.26, alpha: 1.0)
        spire.strokeColor = .clear
        spire.zPosition = 5
        node.addChild(spire)

        return node
    }

    private static func buildLeaningTowerOfPisa(width: CGFloat) -> SKNode {
        let node = SKNode()
        let marble = SKColor(red: 0.92, green: 0.91, blue: 0.86, alpha: 1.0)
        let marbleDark = SKColor(red: 0.80, green: 0.78, blue: 0.72, alpha: 1.0)
        let colonnadeShade = SKColor(red: 0.55, green: 0.53, blue: 0.48, alpha: 0.45)
        addGroundShadow(to: node, width: width * 0.8, yOffset: -width * 0.02, alpha: 0.2)

        let shaft = SKNode()
        shaft.zRotation = -.pi / 15
        node.addChild(shaft)

        let towerW = width * 0.28
        let halfW = towerW / 2
        let floorH = width * 0.26
        let totalFloors = 8  // ground + 6 colonnade + belfry

        // --- Ground floor (solid wall, no columns) ---
        let groundRect = CGRect(x: -halfW, y: 0, width: towerW, height: floorH)
        let groundFloor = makeRect(groundRect, cornerRadius: width * 0.04, fill: marble, lineWidth: 0.9)
        shaft.addChild(groundFloor)
        addFacadeLighting(to: shaft, rect: groundRect, cornerRadius: 2)
        // Blind arches on ground floor
        for i in 0..<4 {
            let ax = -halfW + width * 0.03 + CGFloat(i) * width * 0.06
            let archNode = makeArch(x: ax, y: width * 0.04, width: width * 0.045, rectHeight: width * 0.08, fill: marbleDark.withAlphaComponent(0.3))
            archNode.zPosition = 3
            shaft.addChild(archNode)
        }
        // Ground floor cornice
        let cornice0 = makeRect(CGRect(x: -halfW - width * 0.01, y: floorH - width * 0.02, width: towerW + width * 0.02, height: width * 0.025), cornerRadius: 1, fill: marbleDark, stroke: .clear, lineWidth: 0)
        cornice0.zPosition = 3
        shaft.addChild(cornice0)

        // --- 6 colonnade floors ---
        for floor in 1...6 {
            let yBase = CGFloat(floor) * floorH
            let floorRect = CGRect(x: -halfW, y: yBase, width: towerW, height: floorH)
            let floorBg = makeRect(floorRect, cornerRadius: 1, fill: marble.withAlphaComponent(0.5), stroke: .clear, lineWidth: 0)
            shaft.addChild(floorBg)

            // Colonnade: vertical columns with dark gaps
            let colCount = 6
            let colSpacing = towerW / CGFloat(colCount + 1)
            for c in 1...colCount {
                let cx = -halfW + colSpacing * CGFloat(c)
                let col = SKShapeNode(rectOf: CGSize(width: width * 0.016, height: floorH * 0.78), cornerRadius: 1)
                col.position = CGPoint(x: cx, y: yBase + floorH * 0.45)
                col.fillColor = marble
                col.strokeColor = .clear
                col.zPosition = 4
                shaft.addChild(col)
            }
            // Dark colonnade interior
            let interior = makeRect(CGRect(x: -halfW + width * 0.02, y: yBase + width * 0.02, width: towerW - width * 0.04, height: floorH * 0.78), cornerRadius: 1, fill: colonnadeShade, stroke: .clear, lineWidth: 0)
            interior.zPosition = 2
            shaft.addChild(interior)

            // Cornice at top of each floor
            let cornice = makeRect(CGRect(x: -halfW - width * 0.008, y: yBase + floorH - width * 0.018, width: towerW + width * 0.016, height: width * 0.02), cornerRadius: 0.5, fill: marbleDark, stroke: .clear, lineWidth: 0)
            cornice.zPosition = 5
            shaft.addChild(cornice)
        }

        // --- Belfry (top floor, slightly narrower) ---
        let belfryY = CGFloat(7) * floorH
        let belfryW = towerW * 0.78
        let belfryH = floorH * 0.72
        let belfryRect = CGRect(x: -belfryW / 2, y: belfryY, width: belfryW, height: belfryH)
        let belfry = makeRect(belfryRect, cornerRadius: width * 0.03, fill: marble, lineWidth: 0.8)
        belfry.zPosition = 3
        shaft.addChild(belfry)
        // Belfry columns
        let bColCount = 4
        let bColSpacing = belfryW / CGFloat(bColCount + 1)
        for c in 1...bColCount {
            let cx = -belfryW / 2 + bColSpacing * CGFloat(c)
            let col = SKShapeNode(rectOf: CGSize(width: width * 0.014, height: belfryH * 0.75), cornerRadius: 1)
            col.position = CGPoint(x: cx, y: belfryY + belfryH * 0.44)
            col.fillColor = marble
            col.strokeColor = .clear
            col.zPosition = 5
            shaft.addChild(col)
        }
        let belfryInterior = makeRect(CGRect(x: -belfryW / 2 + width * 0.015, y: belfryY + width * 0.015, width: belfryW - width * 0.03, height: belfryH * 0.75), cornerRadius: 1, fill: colonnadeShade, stroke: .clear, lineWidth: 0)
        belfryInterior.zPosition = 3
        shaft.addChild(belfryInterior)

        // Belfry dome cap
        let capPath = CGMutablePath()
        capPath.move(to: CGPoint(x: -belfryW / 2, y: belfryY + belfryH))
        capPath.addQuadCurve(to: CGPoint(x: belfryW / 2, y: belfryY + belfryH),
                             control: CGPoint(x: 0, y: belfryY + belfryH + width * 0.08))
        capPath.closeSubpath()
        let cap = SKShapeNode(path: capPath)
        cap.fillColor = marbleDark
        cap.strokeColor = Palette.stroke
        cap.lineWidth = 0.8
        cap.zPosition = 6
        shaft.addChild(cap)

        // Outer wall stroke for the whole tower
        let outerPath = CGMutablePath()
        outerPath.move(to: CGPoint(x: -halfW, y: 0))
        outerPath.addLine(to: CGPoint(x: -halfW, y: CGFloat(totalFloors - 1) * floorH))
        outerPath.move(to: CGPoint(x: halfW, y: 0))
        outerPath.addLine(to: CGPoint(x: halfW, y: CGFloat(totalFloors - 1) * floorH))
        let outerStroke = SKShapeNode(path: outerPath)
        outerStroke.strokeColor = Palette.stroke
        outerStroke.lineWidth = 0.9
        outerStroke.zPosition = 6
        shaft.addChild(outerStroke)

        // Specular highlight
        addSoftSpecularLine(to: shaft, from: CGPoint(x: -halfW + width * 0.03, y: width * 0.1), to: CGPoint(x: -halfW + width * 0.03, y: belfryY + belfryH), alpha: 0.18)

        return node
    }

    private static func buildSydneyOperaHouse(width: CGFloat) -> SKNode {
        let node = SKNode()
        let shellWhite = SKColor(white: 0.97, alpha: 1.0)
        let shellCream = SKColor(white: 0.94, alpha: 1.0)
        addGroundShadow(to: node, width: width * 1.15, yOffset: -width * 0.03, alpha: 0.18)

        // --- Water strip ---
        let waterStrip = makeRect(
            CGRect(x: -width * 0.56, y: -width * 0.04, width: width * 1.12, height: width * 0.035),
            cornerRadius: 0, fill: SKColor(red: 0.34, green: 0.57, blue: 0.75, alpha: 0.55), stroke: .clear, lineWidth: 0
        )
        waterStrip.zPosition = 0
        node.addChild(waterStrip)

        // --- Stepped base / podium ---
        let baseStep1 = makeRect(CGRect(x: -width * 0.56, y: 0, width: width * 1.12, height: width * 0.10), cornerRadius: 1, fill: SKColor(red: 0.62, green: 0.70, blue: 0.78, alpha: 1.0), lineWidth: 0.6)
        node.addChild(baseStep1)
        let baseStep2 = makeRect(CGRect(x: -width * 0.53, y: width * 0.10, width: width * 1.06, height: width * 0.08), cornerRadius: 1, fill: SKColor(red: 0.66, green: 0.74, blue: 0.82, alpha: 1.0), lineWidth: 0.5)
        baseStep2.zPosition = 1
        node.addChild(baseStep2)
        let baseStep3 = makeRect(CGRect(x: -width * 0.50, y: width * 0.18, width: width * 1.00, height: width * 0.06), cornerRadius: 1, fill: SKColor(red: 0.70, green: 0.78, blue: 0.85, alpha: 1.0), stroke: .clear, lineWidth: 0)
        baseStep3.zPosition = 1
        node.addChild(baseStep3)

        let baseTop = width * 0.24

        // --- Shell definitions: (baseLeft, peakX, peakY, baseRight) ---
        struct ShellDef {
            let bL: CGFloat; let pX: CGFloat; let pY: CGFloat; let bR: CGFloat
        }
        let defs = [
            ShellDef(bL: -0.48, pX: -0.12, pY: 1.28, bR: 0.02),
            ShellDef(bL: -0.14, pX: 0.10, pY: 1.42, bR: 0.34),
            ShellDef(bL: 0.08, pX: 0.44, pY: 1.08, bR: 0.54)
        ]

        for (index, d) in defs.enumerated() {
            let bL = width * d.bL
            let pX = width * d.pX
            let pY = width * d.pY
            let bR = width * d.bR
            let bY = baseTop

            // Main sail shape using quad curves
            let sailPath = CGMutablePath()
            sailPath.move(to: CGPoint(x: bL, y: bY))
            // Left rising curve to peak
            sailPath.addQuadCurve(to: CGPoint(x: pX, y: pY),
                                  control: CGPoint(x: bL + (pX - bL) * 0.3, y: pY * 0.75))
            // Right descending curve from peak
            sailPath.addQuadCurve(to: CGPoint(x: bR, y: bY),
                                  control: CGPoint(x: pX + (bR - pX) * 0.7, y: pY * 0.75))
            sailPath.closeSubpath()

            let sail = SKShapeNode(path: sailPath)
            sail.fillColor = index == 0 ? shellCream : shellWhite
            sail.strokeColor = Palette.stroke
            sail.lineWidth = 0.8
            sail.zPosition = CGFloat(2 + index)
            node.addChild(sail)

            // Right-side shade on each shell
            let shadePath = CGMutablePath()
            let shadeX = pX + (bR - pX) * 0.4
            shadePath.move(to: CGPoint(x: shadeX, y: bY))
            shadePath.addQuadCurve(to: CGPoint(x: pX, y: pY),
                                   control: CGPoint(x: shadeX + (pX - shadeX) * 0.3, y: pY * 0.6))
            shadePath.addQuadCurve(to: CGPoint(x: bR, y: bY),
                                   control: CGPoint(x: pX + (bR - pX) * 0.7, y: pY * 0.75))
            shadePath.closeSubpath()
            let shade = SKShapeNode(path: shadePath)
            shade.fillColor = SKColor(white: 0.0, alpha: 0.10)
            shade.strokeColor = .clear
            shade.zPosition = CGFloat(2 + index) + 0.1
            node.addChild(shade)

            // Curved ribs on each shell
            for t in 1...5 {
                let ratio = CGFloat(t) / 6
                let ribPath = CGMutablePath()
                // Interpolate along left curve
                let lx = bL + (pX - bL) * ratio
                let ly = bY + (pY - bY) * ratio
                // Interpolate along right curve
                let rx = bR + (pX - bR) * ratio
                let ry = bY + (pY - bY) * ratio
                ribPath.move(to: CGPoint(x: lx, y: ly))
                let cpY = max(ly, ry) + (pY - max(ly, ry)) * 0.15
                ribPath.addQuadCurve(to: CGPoint(x: rx, y: ry),
                                     control: CGPoint(x: (lx + rx) / 2, y: cpY))
                let rib = SKShapeNode(path: ribPath)
                rib.strokeColor = SKColor(white: 1.0, alpha: 0.22)
                rib.lineWidth = 0.7
                rib.zPosition = CGFloat(2 + index) + 0.2
                node.addChild(rib)
            }
        }

        return node
    }

    private static func buildGreatPyramidOfGiza(width: CGFloat) -> SKNode {
        let node = SKNode()
        let sandLight = SKColor(red: 0.88, green: 0.78, blue: 0.55, alpha: 1.0)
        let sandMid   = SKColor(red: 0.85, green: 0.73, blue: 0.49, alpha: 1.0)
        let sandDark  = SKColor(red: 0.73, green: 0.60, blue: 0.38, alpha: 1.0)
        let goldCap   = SKColor(red: 0.92, green: 0.82, blue: 0.42, alpha: 1.0)
        addGroundShadow(to: node, width: width * 1.05, yOffset: -width * 0.02, alpha: 0.2)

        // --- Desert ground color band ---
        let desert = makeRect(
            CGRect(x: -width * 0.62, y: -width * 0.06, width: width * 1.24, height: width * 0.06),
            cornerRadius: 0, fill: SKColor(red: 0.90, green: 0.82, blue: 0.62, alpha: 0.5), stroke: .clear, lineWidth: 0
        )
        desert.zPosition = -1
        node.addChild(desert)

        // --- Main pyramid ---
        let pH = width * 1.38
        let main = makePolygon(
            [CGPoint(x: -width * 0.56, y: 0), CGPoint(x: 0, y: pH), CGPoint(x: width * 0.56, y: 0)],
            fill: sandMid, lineWidth: 1.2
        )
        node.addChild(main)

        // Right face shading
        let rightFace = makePolygon(
            [CGPoint(x: 0, y: pH), CGPoint(x: width * 0.56, y: 0), CGPoint(x: width * 0.05, y: 0)],
            fill: sandDark, stroke: .clear, lineWidth: 0
        )
        rightFace.zPosition = 2
        node.addChild(rightFace)

        // --- Stone block texture: horizontal bands + vertical joints ---
        let blockRows = 12
        for row in 1...blockRows {
            let y = pH * CGFloat(row) / CGFloat(blockRows + 1)
            let halfWAtY = width * 0.56 * (1 - y / pH)
            // Horizontal joint
            let hLine = CGMutablePath()
            hLine.move(to: CGPoint(x: -halfWAtY, y: y))
            hLine.addLine(to: CGPoint(x: halfWAtY, y: y))
            let hNode = SKShapeNode(path: hLine)
            hNode.strokeColor = SKColor(white: 0.0, alpha: 0.08)
            hNode.lineWidth = 0.7
            hNode.zPosition = 4
            node.addChild(hNode)

            // Vertical joints (staggered)
            let blockCount = max(2, Int(halfWAtY * 2 / (width * 0.09)))
            let blockW = halfWAtY * 2 / CGFloat(blockCount)
            let offset: CGFloat = row % 2 == 0 ? blockW * 0.5 : 0
            let yBot = pH * CGFloat(row - 1) / CGFloat(blockRows + 1)
            for b in 1..<blockCount {
                let bx = -halfWAtY + CGFloat(b) * blockW + offset
                if bx > -halfWAtY && bx < halfWAtY {
                    let vLine = CGMutablePath()
                    vLine.move(to: CGPoint(x: bx, y: yBot))
                    vLine.addLine(to: CGPoint(x: bx, y: y))
                    let vNode = SKShapeNode(path: vLine)
                    vNode.strokeColor = SKColor(white: 0.0, alpha: 0.05)
                    vNode.lineWidth = 0.5
                    vNode.zPosition = 4
                    node.addChild(vNode)
                }
            }
        }

        // --- Gold capstone ---
        let capH = pH * 0.06
        let capW = width * 0.56 * capH / pH
        let capstone = makePolygon(
            [CGPoint(x: -capW, y: pH - capH), CGPoint(x: 0, y: pH + width * 0.02), CGPoint(x: capW, y: pH - capH)],
            fill: goldCap, stroke: SKColor(red: 0.80, green: 0.70, blue: 0.30, alpha: 0.6), lineWidth: 0.8
        )
        capstone.zPosition = 5
        node.addChild(capstone)

        // --- Small pyramid (right foreground) ---
        let smallH = width * 0.40
        let smallCX = width * 0.38
        let small = makePolygon(
            [CGPoint(x: smallCX - width * 0.16, y: 0), CGPoint(x: smallCX, y: smallH), CGPoint(x: smallCX + width * 0.16, y: 0)],
            fill: sandLight, lineWidth: 0.8
        )
        small.zPosition = 5
        node.addChild(small)
        // Small pyramid right shade
        let smallShade = makePolygon(
            [CGPoint(x: smallCX, y: smallH), CGPoint(x: smallCX + width * 0.16, y: 0), CGPoint(x: smallCX + width * 0.02, y: 0)],
            fill: SKColor(white: 0.0, alpha: 0.12), stroke: .clear, lineWidth: 0
        )
        smallShade.zPosition = 6
        node.addChild(smallShade)

        // Specular on main pyramid left edge
        addSoftSpecularLine(to: node, from: CGPoint(x: -width * 0.12, y: width * 0.08), to: CGPoint(x: -width * 0.01, y: pH - width * 0.1), alpha: 0.18)

        return node
    }

    private static func buildBurjKhalifa(width: CGFloat) -> SKNode {
        let node = SKNode()
        let glassLight = SKColor(red: 0.66, green: 0.77, blue: 0.87, alpha: 1.0)
        let glassDark  = SKColor(red: 0.52, green: 0.62, blue: 0.74, alpha: 1.0)
        addGroundShadow(to: node, width: width * 0.8, yOffset: -width * 0.03, alpha: 0.22)

        // --- Main central spine ---
        let mainPath = CGMutablePath()
        mainPath.move(to: CGPoint(x: -width * 0.18, y: 0))
        mainPath.addLine(to: CGPoint(x: -width * 0.12, y: width * 1.20))
        mainPath.addLine(to: CGPoint(x: -width * 0.08, y: width * 1.65))
        mainPath.addLine(to: CGPoint(x: -width * 0.05, y: width * 2.05))
        mainPath.addLine(to: CGPoint(x: -width * 0.028, y: width * 2.35))
        mainPath.addLine(to: CGPoint(x: 0, y: width * 2.70))
        mainPath.addLine(to: CGPoint(x: width * 0.028, y: width * 2.35))
        mainPath.addLine(to: CGPoint(x: width * 0.05, y: width * 2.05))
        mainPath.addLine(to: CGPoint(x: width * 0.08, y: width * 1.65))
        mainPath.addLine(to: CGPoint(x: width * 0.12, y: width * 1.20))
        mainPath.addLine(to: CGPoint(x: width * 0.18, y: 0))
        mainPath.closeSubpath()
        let mainTower = SKShapeNode(path: mainPath)
        mainTower.fillColor = glassLight
        mainTower.strokeColor = Palette.stroke
        mainTower.lineWidth = 1
        node.addChild(mainTower)

        // --- Left wing (Y-shape arm) ---
        let leftWing = CGMutablePath()
        leftWing.move(to: CGPoint(x: -width * 0.18, y: 0))
        leftWing.addLine(to: CGPoint(x: -width * 0.30, y: 0))
        leftWing.addLine(to: CGPoint(x: -width * 0.20, y: width * 1.00))
        leftWing.addLine(to: CGPoint(x: -width * 0.15, y: width * 1.40))
        leftWing.addLine(to: CGPoint(x: -width * 0.12, y: width * 1.20))
        leftWing.addLine(to: CGPoint(x: -width * 0.18, y: 0))
        leftWing.closeSubpath()
        let leftWingNode = SKShapeNode(path: leftWing)
        leftWingNode.fillColor = glassDark
        leftWingNode.strokeColor = Palette.stroke
        leftWingNode.lineWidth = 0.8
        leftWingNode.zPosition = -1
        node.addChild(leftWingNode)

        // --- Right wing (Y-shape arm) ---
        let rightWing = CGMutablePath()
        rightWing.move(to: CGPoint(x: width * 0.18, y: 0))
        rightWing.addLine(to: CGPoint(x: width * 0.30, y: 0))
        rightWing.addLine(to: CGPoint(x: width * 0.20, y: width * 1.00))
        rightWing.addLine(to: CGPoint(x: width * 0.15, y: width * 1.40))
        rightWing.addLine(to: CGPoint(x: width * 0.12, y: width * 1.20))
        rightWing.addLine(to: CGPoint(x: width * 0.18, y: 0))
        rightWing.closeSubpath()
        let rightWingNode = SKShapeNode(path: rightWing)
        rightWingNode.fillColor = glassDark
        rightWingNode.strokeColor = Palette.stroke
        rightWingNode.lineWidth = 0.8
        rightWingNode.zPosition = -1
        node.addChild(rightWingNode)

        // --- Right side shade on main tower ---
        let shadePath = CGMutablePath()
        shadePath.move(to: CGPoint(x: width * 0.02, y: 0))
        shadePath.addLine(to: CGPoint(x: width * 0.18, y: 0))
        shadePath.addLine(to: CGPoint(x: width * 0.12, y: width * 1.20))
        shadePath.addLine(to: CGPoint(x: width * 0.08, y: width * 1.65))
        shadePath.addLine(to: CGPoint(x: width * 0.05, y: width * 2.05))
        shadePath.addLine(to: CGPoint(x: width * 0.028, y: width * 2.35))
        shadePath.addLine(to: CGPoint(x: 0, y: width * 2.70))
        shadePath.closeSubpath()
        let shade = SKShapeNode(path: shadePath)
        shade.fillColor = SKColor(white: 0.0, alpha: 0.12)
        shade.strokeColor = .clear
        shade.zPosition = 2
        node.addChild(shade)

        // --- Setback horizontal lines ---
        let setbackYs: [CGFloat] = [1.20, 1.65, 2.05, 2.35]
        for sy in setbackYs {
            let y = width * sy
            // Approximate half-width at this height
            let t = sy / 2.70
            let hw = width * (0.18 * (1 - t) + 0.005)
            let bandPath = CGMutablePath()
            bandPath.move(to: CGPoint(x: -hw, y: y))
            bandPath.addLine(to: CGPoint(x: hw, y: y))
            let band = SKShapeNode(path: bandPath)
            band.strokeColor = SKColor(white: 0.0, alpha: 0.18)
            band.lineWidth = 1.2
            band.zPosition = 3
            node.addChild(band)
        }

        // --- Vertical glass curtain wall lines ---
        let vLinePath = CGMutablePath()
        for i in -3...3 {
            let xFrac = CGFloat(i) * 0.04
            let topY = width * 2.70 * max(0, 1 - abs(CGFloat(i)) * 0.22)
            vLinePath.move(to: CGPoint(x: width * xFrac, y: width * 0.05))
            vLinePath.addLine(to: CGPoint(x: width * xFrac * 0.15, y: topY))
        }
        let vLines = SKShapeNode(path: vLinePath)
        vLines.strokeColor = SKColor(white: 0.0, alpha: 0.08)
        vLines.lineWidth = 0.6
        vLines.zPosition = 3
        node.addChild(vLines)

        // --- Windows on main body ---
        let bodyRect = CGRect(x: -width * 0.10, y: width * 0.10, width: width * 0.20, height: width * 1.05)
        addWindowGrid(to: node, rect: bodyRect, columns: 3, rows: 10, insetX: width * 0.01, insetY: width * 0.02, z: 4)

        // --- Spire (thinner, taller) ---
        let spirePath = CGMutablePath()
        spirePath.move(to: CGPoint(x: -width * 0.008, y: width * 2.70))
        spirePath.addLine(to: CGPoint(x: 0, y: width * 3.08))
        spirePath.addLine(to: CGPoint(x: width * 0.008, y: width * 2.70))
        spirePath.closeSubpath()
        let spire = SKShapeNode(path: spirePath)
        spire.fillColor = SKColor(red: 0.54, green: 0.64, blue: 0.75, alpha: 1.0)
        spire.strokeColor = Palette.stroke
        spire.lineWidth = 0.6
        spire.zPosition = 5
        node.addChild(spire)

        return node
    }

    private static func buildTajMahal(width: CGFloat) -> SKNode {
        let node = SKNode()
        let marble = SKColor(white: 0.96, alpha: 1.0)
        let marbleLite = SKColor(white: 0.98, alpha: 1.0)
        let marbleDark = SKColor(white: 0.88, alpha: 1.0)
        let goldFinial = SKColor(red: 0.78, green: 0.72, blue: 0.48, alpha: 1.0)
        addGroundShadow(to: node, width: width * 1.1, yOffset: -width * 0.02, alpha: 0.2)

        // --- Terrace / platform ---
        let terraceRect = CGRect(x: -width * 0.50, y: 0, width: width, height: width * 0.18)
        let terrace = makeRect(terraceRect, cornerRadius: 2, fill: marbleDark)
        node.addChild(terrace)
        addHorizontalBands(to: node, rect: terraceRect, count: 3, color: SKColor(white: 0.0, alpha: 0.04), z: 2)

        let baseY = width * 0.18

        // --- Main central building ---
        let centerRect = CGRect(x: -width * 0.24, y: baseY, width: width * 0.48, height: width * 0.68)
        let center = makeRect(centerRect, cornerRadius: 3, fill: marble)
        node.addChild(center)
        addFacadeLighting(to: node, rect: centerRect, cornerRadius: 2)

        // --- Decorative niches (symmetric) ---
        for xSign: CGFloat in [-1, 1] {
            let nx = xSign * width * 0.14
            let niche = makeArch(x: nx - width * 0.035, y: baseY + width * 0.10, width: width * 0.07, rectHeight: width * 0.18, fill: SKColor(white: 0.0, alpha: 0.06))
            niche.zPosition = 3
            node.addChild(niche)
        }

        // --- Main entrance: Islamic pointed arch (iwan) ---
        let iwanPath = CGMutablePath()
        let iwanW = width * 0.16
        let iwanH = width * 0.34
        iwanPath.move(to: CGPoint(x: -iwanW / 2, y: baseY))
        iwanPath.addLine(to: CGPoint(x: -iwanW / 2, y: baseY + iwanH * 0.65))
        // Pointed arch top (two quad curves meeting at a point)
        iwanPath.addQuadCurve(to: CGPoint(x: 0, y: baseY + iwanH),
                              control: CGPoint(x: -iwanW * 0.35, y: baseY + iwanH * 0.95))
        iwanPath.addQuadCurve(to: CGPoint(x: iwanW / 2, y: baseY + iwanH * 0.65),
                              control: CGPoint(x: iwanW * 0.35, y: baseY + iwanH * 0.95))
        iwanPath.addLine(to: CGPoint(x: iwanW / 2, y: baseY))
        iwanPath.closeSubpath()
        let iwan = SKShapeNode(path: iwanPath)
        iwan.fillColor = SKColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 0.55)
        iwan.strokeColor = Palette.stroke
        iwan.lineWidth = 0.8
        iwan.zPosition = 3
        node.addChild(iwan)

        // --- Onion dome ---
        let domeBaseY = baseY + width * 0.68
        let domeW = width * 0.20
        let domeH = width * 0.28
        let domePath = CGMutablePath()
        // Start at bottom-left of dome base
        domePath.move(to: CGPoint(x: -domeW / 2, y: domeBaseY))
        // Left side: bulge out then narrow (onion shape)
        domePath.addCurve(to: CGPoint(x: 0, y: domeBaseY + domeH),
                          control1: CGPoint(x: -domeW * 0.65, y: domeBaseY + domeH * 0.45),
                          control2: CGPoint(x: -domeW * 0.12, y: domeBaseY + domeH * 0.88))
        // Right side: mirror
        domePath.addCurve(to: CGPoint(x: domeW / 2, y: domeBaseY),
                          control1: CGPoint(x: domeW * 0.12, y: domeBaseY + domeH * 0.88),
                          control2: CGPoint(x: domeW * 0.65, y: domeBaseY + domeH * 0.45))
        domePath.closeSubpath()
        let dome = SKShapeNode(path: domePath)
        dome.fillColor = marbleLite
        dome.strokeColor = Palette.stroke
        dome.lineWidth = 1
        dome.zPosition = 3
        node.addChild(dome)

        // Dome right shade
        let domeShade = CGMutablePath()
        domeShade.move(to: CGPoint(x: width * 0.02, y: domeBaseY))
        domeShade.addCurve(to: CGPoint(x: 0, y: domeBaseY + domeH),
                           control1: CGPoint(x: domeW * 0.35, y: domeBaseY + domeH * 0.35),
                           control2: CGPoint(x: domeW * 0.10, y: domeBaseY + domeH * 0.85))
        domeShade.addCurve(to: CGPoint(x: domeW / 2, y: domeBaseY),
                           control1: CGPoint(x: domeW * 0.12, y: domeBaseY + domeH * 0.88),
                           control2: CGPoint(x: domeW * 0.65, y: domeBaseY + domeH * 0.45))
        domeShade.closeSubpath()
        let dShade = SKShapeNode(path: domeShade)
        dShade.fillColor = SKColor(white: 0.0, alpha: 0.08)
        dShade.strokeColor = .clear
        dShade.zPosition = 4
        node.addChild(dShade)

        // --- Lotus base under dome ---
        let lotusPath = CGMutablePath()
        lotusPath.move(to: CGPoint(x: -domeW / 2 - width * 0.02, y: domeBaseY))
        lotusPath.addQuadCurve(to: CGPoint(x: domeW / 2 + width * 0.02, y: domeBaseY),
                               control: CGPoint(x: 0, y: domeBaseY + width * 0.04))
        lotusPath.addLine(to: CGPoint(x: domeW / 2 + width * 0.02, y: domeBaseY - width * 0.02))
        lotusPath.addLine(to: CGPoint(x: -domeW / 2 - width * 0.02, y: domeBaseY - width * 0.02))
        lotusPath.closeSubpath()
        let lotus = SKShapeNode(path: lotusPath)
        lotus.fillColor = marbleDark
        lotus.strokeColor = .clear
        lotus.zPosition = 3
        node.addChild(lotus)

        // --- Finial (gold spire on top of dome) ---
        let finial = SKShapeNode(rectOf: CGSize(width: width * 0.02, height: width * 0.10), cornerRadius: 1)
        finial.position = CGPoint(x: 0, y: domeBaseY + domeH + width * 0.04)
        finial.fillColor = goldFinial
        finial.strokeColor = .clear
        finial.zPosition = 5
        node.addChild(finial)

        // --- Four minarets ---
        let minaretPositions: [CGFloat] = [-width * 0.43, -width * 0.34, width * 0.34, width * 0.43]
        let minaretHeights: [CGFloat] = [width * 0.82, width * 0.90, width * 0.90, width * 0.82]
        for (i, mx) in minaretPositions.enumerated() {
            let mH = minaretHeights[i]
            let mW = width * 0.055
            let mRect = CGRect(x: mx - mW / 2, y: baseY, width: mW, height: mH)
            let minaret = makeRect(mRect, cornerRadius: 1.5, fill: marble, lineWidth: 0.7)
            minaret.zPosition = 1
            node.addChild(minaret)
            addHorizontalBands(to: node, rect: mRect, count: 5, color: SKColor(white: 0.0, alpha: 0.04), z: 2)

            // Small onion dome on top of minaret
            let mDomeY = baseY + mH
            let mDomeR = mW * 0.55
            let mDomePath = CGMutablePath()
            mDomePath.move(to: CGPoint(x: mx - mDomeR, y: mDomeY))
            mDomePath.addCurve(to: CGPoint(x: mx, y: mDomeY + mDomeR * 1.5),
                               control1: CGPoint(x: mx - mDomeR * 1.2, y: mDomeY + mDomeR * 0.6),
                               control2: CGPoint(x: mx - mDomeR * 0.2, y: mDomeY + mDomeR * 1.3))
            mDomePath.addCurve(to: CGPoint(x: mx + mDomeR, y: mDomeY),
                               control1: CGPoint(x: mx + mDomeR * 0.2, y: mDomeY + mDomeR * 1.3),
                               control2: CGPoint(x: mx + mDomeR * 1.2, y: mDomeY + mDomeR * 0.6))
            mDomePath.closeSubpath()
            let mDome = SKShapeNode(path: mDomePath)
            mDome.fillColor = marbleLite
            mDome.strokeColor = Palette.stroke
            mDome.lineWidth = 0.6
            mDome.zPosition = 2
            node.addChild(mDome)

            // Minaret finial
            let mFinial = SKShapeNode(rectOf: CGSize(width: 1.5, height: width * 0.04), cornerRadius: 0.5)
            mFinial.position = CGPoint(x: mx, y: mDomeY + mDomeR * 1.5 + width * 0.02)
            mFinial.fillColor = goldFinial
            mFinial.strokeColor = .clear
            mFinial.zPosition = 3
            node.addChild(mFinial)
        }

        return node
    }

    private static func buildColosseum(width: CGFloat) -> SKNode {
        let node = SKNode()
        let travertine = SKColor(red: 0.82, green: 0.70, blue: 0.54, alpha: 1.0)
        let travertineDark = SKColor(red: 0.72, green: 0.58, blue: 0.42, alpha: 1.0)
        let archDark = SKColor(red: 0.42, green: 0.32, blue: 0.22, alpha: 0.80)
        addGroundShadow(to: node, width: width * 1.12, yOffset: -width * 0.03, alpha: 0.22)

        let totalH = width * 0.82

        // --- Elliptical outer wall shape (front view with right-side ruin) ---
        // Left side full height, right side decreasing to simulate ruins
        let wallPath = CGMutablePath()
        let segments = 20
        // Bottom edge left to right
        wallPath.move(to: CGPoint(x: -width * 0.52, y: 0))
        wallPath.addLine(to: CGPoint(x: width * 0.52, y: 0))
        // Right side going up — ruined, height decreases
        for i in stride(from: segments, through: 0, by: -1) {
            let t = CGFloat(i) / CGFloat(segments)
            let x = -width * 0.52 + t * width * 1.04
            // Full height on left, decreasing on right side (past 60%)
            let ruinFactor: CGFloat
            if t < 0.6 {
                ruinFactor = 1.0
            } else {
                ruinFactor = 1.0 - (t - 0.6) * 1.2  // drops to ~0.52 at right edge
            }
            // Slight elliptical curve (taller in center)
            let ellipseFactor = 1.0 - pow((t - 0.5) * 1.6, 2) * 0.08
            let y = totalH * ruinFactor * ellipseFactor
            wallPath.addLine(to: CGPoint(x: x, y: max(0, y)))
        }
        wallPath.closeSubpath()
        let wall = SKShapeNode(path: wallPath)
        wall.fillColor = travertine
        wall.strokeColor = Palette.stroke
        wall.lineWidth = 1
        node.addChild(wall)

        // --- Three tiers of arches (bottom largest, top smallest) ---
        struct TierDef {
            let yBase: CGFloat; let archH: CGFloat; let archW: CGFloat; let cols: Int
        }
        let tiers = [
            TierDef(yBase: width * 0.04, archH: width * 0.18, archW: width * 0.10, cols: 8),
            TierDef(yBase: width * 0.26, archH: width * 0.15, archW: width * 0.09, cols: 8),
            TierDef(yBase: width * 0.45, archH: width * 0.12, archW: width * 0.08, cols: 8)
        ]

        for (tierIdx, tier) in tiers.enumerated() {
            // Horizontal cornice between tiers
            if tierIdx > 0 {
                let corniceY = tier.yBase - width * 0.02
                let cornice = makeRect(
                    CGRect(x: -width * 0.50, y: corniceY, width: width * 1.00, height: width * 0.025),
                    cornerRadius: 0.5, fill: travertineDark, stroke: .clear, lineWidth: 0
                )
                cornice.zPosition = 2
                node.addChild(cornice)
            }

            let spacing = width * 0.96 / CGFloat(tier.cols)
            for col in 0..<tier.cols {
                let cx = -width * 0.48 + spacing * (CGFloat(col) + 0.5)
                // Check if this arch is within the ruined area
                let t = (cx + width * 0.52) / (width * 1.04)
                let ruinFactor: CGFloat = t < 0.6 ? 1.0 : max(0, 1.0 - (t - 0.6) * 1.2)
                let maxYHere = totalH * ruinFactor
                if tier.yBase + tier.archH > maxYHere { continue }

                let archNode = makeArch(
                    x: cx - tier.archW / 2,
                    y: tier.yBase,
                    width: tier.archW,
                    rectHeight: tier.archH * 0.55,
                    fill: archDark
                )
                archNode.zPosition = 3
                node.addChild(archNode)
            }
        }

        // --- Top cornice ---
        let topCornice = makeRect(
            CGRect(x: -width * 0.50, y: width * 0.60, width: width * 0.66, height: width * 0.03),
            cornerRadius: 0.5, fill: travertineDark, stroke: .clear, lineWidth: 0
        )
        topCornice.zPosition = 2
        node.addChild(topCornice)

        // --- Remaining pillar stubs on top (ruined section) ---
        for i in 0..<4 {
            let px = -width * 0.42 + CGFloat(i) * width * 0.24
            let stubH = width * (0.06 + CGFloat(i % 2) * 0.03)
            let stub = makeRect(
                CGRect(x: px - width * 0.02, y: totalH * 0.92 - stubH, width: width * 0.04, height: stubH),
                cornerRadius: 0.5, fill: travertineDark, stroke: .clear, lineWidth: 0
            )
            stub.zPosition = 4
            // Only show stubs in the non-ruined area
            if px < width * 0.1 {
                node.addChild(stub)
            }
        }

        // --- Facade lighting ---
        addFacadeLighting(to: node, rect: CGRect(x: -width * 0.50, y: 0, width: width * 0.50, height: totalH), cornerRadius: 2)

        // --- Cracks for weathering ---
        for crack in 0...2 {
            let x = -width * 0.30 + CGFloat(crack) * width * 0.22
            let crackPath = CGMutablePath()
            crackPath.move(to: CGPoint(x: x, y: totalH * 0.85))
            crackPath.addLine(to: CGPoint(x: x - width * 0.012, y: totalH * 0.55))
            crackPath.addLine(to: CGPoint(x: x + width * 0.006, y: totalH * 0.30))
            let crackLine = SKShapeNode(path: crackPath)
            crackLine.strokeColor = SKColor(white: 0.0, alpha: 0.10)
            crackLine.lineWidth = 0.8
            crackLine.zPosition = 5
            node.addChild(crackLine)
        }

        return node
    }

    private static func buildArcDeTriomphe(width: CGFloat) -> SKNode {
        let node = SKNode()
        let limestone = SKColor(red: 0.88, green: 0.83, blue: 0.73, alpha: 1.0)
        let limestoneDark = SKColor(red: 0.78, green: 0.71, blue: 0.61, alpha: 1.0)
        let limestoneLight = SKColor(red: 0.92, green: 0.88, blue: 0.80, alpha: 1.0)
        addGroundShadow(to: node, width: width * 0.95, yOffset: -width * 0.02, alpha: 0.2)

        let totalH = width * 1.12

        // --- Main body ---
        let frameRect = CGRect(x: -width * 0.46, y: 0, width: width * 0.92, height: totalH)
        let frame = makeRect(frameRect, cornerRadius: 2, fill: limestone)
        node.addChild(frame)
        addFacadeLighting(to: node, rect: frameRect, cornerRadius: 2)

        // --- Main semicircular arch (center) ---
        let mainArchW = width * 0.34
        let mainArchRectH = width * 0.30
        let mainArch = makeArch(x: -mainArchW / 2, y: 0, width: mainArchW, rectHeight: mainArchRectH, fill: SKColor(red: 0.40, green: 0.44, blue: 0.48, alpha: 0.60), stroke: Palette.stroke, lineWidth: 0.8)
        mainArch.zPosition = 3
        node.addChild(mainArch)

        // Arch inner ring highlight
        let innerRingPath = CGMutablePath()
        innerRingPath.addArc(center: CGPoint(x: 0, y: mainArchRectH), radius: mainArchW / 2 - width * 0.02, startAngle: .pi, endAngle: 0, clockwise: false)
        let innerRing = SKShapeNode(path: innerRingPath)
        innerRing.strokeColor = SKColor(white: 1.0, alpha: 0.15)
        innerRing.lineWidth = 1.5
        innerRing.zPosition = 4
        node.addChild(innerRing)

        // --- Small side arches ---
        for xSign: CGFloat in [-1, 1] {
            let sideX = xSign * width * 0.34
            let sideArchW = width * 0.10
            let sideArchRectH = width * 0.12
            let sideArch = makeArch(x: sideX - sideArchW / 2, y: 0, width: sideArchW, rectHeight: sideArchRectH, fill: SKColor(red: 0.40, green: 0.44, blue: 0.48, alpha: 0.45))
            sideArch.zPosition = 3
            node.addChild(sideArch)
        }

        // --- Relief panels (dark rectangles on pillars) ---
        for xSign: CGFloat in [-1, 1] {
            let panelX = xSign * width * 0.28
            let panel = makeRect(
                CGRect(x: panelX - width * 0.08, y: width * 0.08, width: width * 0.16, height: width * 0.38),
                cornerRadius: 1.5, fill: limestoneDark.withAlphaComponent(0.4), stroke: SKColor(white: 0.0, alpha: 0.08), lineWidth: 0.6
            )
            panel.zPosition = 3
            node.addChild(panel)
        }

        // --- Horizontal entablature / cornice bands ---
        // Lower frieze
        let frieze1 = makeRect(
            CGRect(x: -width * 0.46, y: width * 0.62, width: width * 0.92, height: width * 0.025),
            cornerRadius: 0.5, fill: limestoneDark, stroke: .clear, lineWidth: 0
        )
        frieze1.zPosition = 4
        node.addChild(frieze1)

        // Main cornice band
        let corniceBand = makeRect(
            CGRect(x: -width * 0.48, y: width * 0.86, width: width * 0.96, height: width * 0.10),
            cornerRadius: 1, fill: limestoneDark, stroke: .clear, lineWidth: 0
        )
        corniceBand.zPosition = 2
        node.addChild(corniceBand)

        // Inscription area between frieze and cornice
        let inscriptionRect = makeRect(
            CGRect(x: -width * 0.38, y: width * 0.66, width: width * 0.76, height: width * 0.16),
            cornerRadius: 1, fill: limestoneLight.withAlphaComponent(0.5), stroke: .clear, lineWidth: 0
        )
        inscriptionRect.zPosition = 3
        node.addChild(inscriptionRect)

        // Thin molding lines
        for my: CGFloat in [0.64, 0.84, 0.96, 1.08] {
            let moldPath = CGMutablePath()
            moldPath.move(to: CGPoint(x: -width * 0.46, y: width * my))
            moldPath.addLine(to: CGPoint(x: width * 0.46, y: width * my))
            let mold = SKShapeNode(path: moldPath)
            mold.strokeColor = SKColor(white: 0.0, alpha: 0.08)
            mold.lineWidth = 0.8
            mold.zPosition = 5
            node.addChild(mold)
        }

        // --- Attic / parapet wall with sculpture silhouettes ---
        let atticRect = CGRect(x: -width * 0.44, y: width * 0.96, width: width * 0.88, height: width * 0.16)
        let attic = makeRect(atticRect, cornerRadius: 1, fill: limestone, stroke: .clear, lineWidth: 0)
        attic.zPosition = 2
        node.addChild(attic)

        // Sculpture bumps on top
        let sculpturePath = CGMutablePath()
        let sculptureCount = 5
        let sSpacing = width * 0.76 / CGFloat(sculptureCount)
        for i in 0..<sculptureCount {
            let sx = -width * 0.38 + sSpacing * (CGFloat(i) + 0.5)
            let sh = width * (0.03 + (i == 2 ? 0.02 : 0))  // center one taller
            sculpturePath.move(to: CGPoint(x: sx - width * 0.03, y: totalH))
            sculpturePath.addQuadCurve(to: CGPoint(x: sx + width * 0.03, y: totalH),
                                       control: CGPoint(x: sx, y: totalH + sh))
        }
        let sculptures = SKShapeNode(path: sculpturePath)
        sculptures.strokeColor = limestoneDark
        sculptures.lineWidth = 1.5
        sculptures.fillColor = .clear
        sculptures.zPosition = 5
        node.addChild(sculptures)

        return node
    }

    private static func buildEmpireStateBuilding(width: CGFloat) -> SKNode {
        let node = SKNode()
        let steelLight = SKColor(red: 0.58, green: 0.65, blue: 0.74, alpha: 1.0)
        let steelMid   = SKColor(red: 0.52, green: 0.59, blue: 0.68, alpha: 1.0)
        let steelDark  = SKColor(red: 0.44, green: 0.51, blue: 0.60, alpha: 1.0)
        let steelDeep  = SKColor(red: 0.36, green: 0.42, blue: 0.50, alpha: 1.0)
        let decoGold   = SKColor(red: 0.72, green: 0.62, blue: 0.38, alpha: 0.35)
        addGroundShadow(to: node, width: width * 0.9, yOffset: -width * 0.03, alpha: 0.24)

        // --- Entrance lobby (Art Deco base) ---
        let lobbyRect = CGRect(x: -width * 0.34, y: 0, width: width * 0.68, height: width * 0.22)
        let lobby = makeRect(lobbyRect, cornerRadius: 2, fill: steelLight, lineWidth: 0.8)
        node.addChild(lobby)
        // Art Deco vertical lines on lobby
        let decoPath = CGMutablePath()
        for i in 0..<8 {
            let dx = -width * 0.28 + CGFloat(i) * width * 0.08
            decoPath.move(to: CGPoint(x: dx, y: width * 0.02))
            decoPath.addLine(to: CGPoint(x: dx, y: width * 0.20))
        }
        let decoLines = SKShapeNode(path: decoPath)
        decoLines.strokeColor = decoGold
        decoLines.lineWidth = 1.2
        decoLines.zPosition = 3
        node.addChild(decoLines)
        // Entrance arch
        let entrance = makeArch(x: -width * 0.06, y: 0, width: width * 0.12, rectHeight: width * 0.06, fill: Palette.darkWindow.withAlphaComponent(0.6))
        entrance.zPosition = 3
        node.addChild(entrance)

        // --- Lower section (widest) ---
        let lowerRect = CGRect(x: -width * 0.30, y: width * 0.22, width: width * 0.60, height: width * 1.04)
        let lower = makeRect(lowerRect, cornerRadius: 2, fill: steelLight, lineWidth: 0.9)
        node.addChild(lower)
        addFacadeLighting(to: node, rect: lowerRect, cornerRadius: 2)
        addWindowGrid(to: node, rect: CGRect(x: -width * 0.26, y: width * 0.28, width: width * 0.52, height: width * 0.92), columns: 6, rows: 10, insetX: width * 0.02, insetY: width * 0.02)
        // Art Deco vertical accent lines
        let lowerDecoPath = CGMutablePath()
        for i in 0..<4 {
            let dx = -width * 0.18 + CGFloat(i) * width * 0.12
            lowerDecoPath.move(to: CGPoint(x: dx, y: width * 0.24))
            lowerDecoPath.addLine(to: CGPoint(x: dx, y: width * 1.24))
        }
        let lowerDeco = SKShapeNode(path: lowerDecoPath)
        lowerDeco.strokeColor = decoGold
        lowerDeco.lineWidth = 0.8
        lowerDeco.zPosition = 5
        node.addChild(lowerDeco)

        // --- Setback ledge 1 ---
        let ledge1 = makeRect(
            CGRect(x: -width * 0.32, y: width * 1.22, width: width * 0.64, height: width * 0.04),
            cornerRadius: 1, fill: steelDeep, stroke: .clear, lineWidth: 0
        )
        ledge1.zPosition = 4
        node.addChild(ledge1)

        // --- Middle section ---
        let middleRect = CGRect(x: -width * 0.21, y: width * 1.26, width: width * 0.42, height: width * 0.72)
        let middle = makeRect(middleRect, cornerRadius: 1, fill: steelMid, lineWidth: 0.9)
        node.addChild(middle)
        addFacadeLighting(to: node, rect: middleRect, cornerRadius: 1)
        addWindowGrid(to: node, rect: CGRect(x: -width * 0.17, y: width * 1.32, width: width * 0.34, height: width * 0.60), columns: 4, rows: 7, insetX: width * 0.02, insetY: width * 0.02)
        // Middle vertical accents
        let midDecoPath = CGMutablePath()
        for i in 0..<3 {
            let dx = -width * 0.10 + CGFloat(i) * width * 0.10
            midDecoPath.move(to: CGPoint(x: dx, y: width * 1.28))
            midDecoPath.addLine(to: CGPoint(x: dx, y: width * 1.96))
        }
        let midDeco = SKShapeNode(path: midDecoPath)
        midDeco.strokeColor = decoGold
        midDeco.lineWidth = 0.7
        midDeco.zPosition = 5
        node.addChild(midDeco)

        // --- Setback ledge 2 ---
        let ledge2 = makeRect(
            CGRect(x: -width * 0.23, y: width * 1.94, width: width * 0.46, height: width * 0.04),
            cornerRadius: 1, fill: steelDeep, stroke: .clear, lineWidth: 0
        )
        ledge2.zPosition = 4
        node.addChild(ledge2)

        // --- Upper section ---
        let upperRect = CGRect(x: -width * 0.13, y: width * 1.98, width: width * 0.26, height: width * 0.44)
        let upper = makeRect(upperRect, cornerRadius: 1, fill: steelDark, lineWidth: 0.9)
        node.addChild(upper)
        addFacadeLighting(to: node, rect: upperRect, cornerRadius: 1)
        addWindowGrid(to: node, rect: CGRect(x: -width * 0.10, y: width * 2.02, width: width * 0.20, height: width * 0.34), columns: 2, rows: 4, insetX: width * 0.01, insetY: width * 0.01)

        // --- Observation deck with railing ---
        let obsDeck = makeRect(
            CGRect(x: -width * 0.15, y: width * 2.38, width: width * 0.30, height: width * 0.04),
            cornerRadius: 1, fill: steelDeep, stroke: .clear, lineWidth: 0
        )
        obsDeck.zPosition = 4
        node.addChild(obsDeck)
        // Railing posts
        let railPath = CGMutablePath()
        for i in 0..<5 {
            let rx = -width * 0.12 + CGFloat(i) * width * 0.06
            railPath.move(to: CGPoint(x: rx, y: width * 2.42))
            railPath.addLine(to: CGPoint(x: rx, y: width * 2.46))
        }
        // Railing top bar
        railPath.move(to: CGPoint(x: -width * 0.12, y: width * 2.46))
        railPath.addLine(to: CGPoint(x: width * 0.12, y: width * 2.46))
        let rail = SKShapeNode(path: railPath)
        rail.strokeColor = steelDeep
        rail.lineWidth = 0.8
        rail.zPosition = 5
        node.addChild(rail)

        // --- Crown / top cap ---
        let crown = makeRect(
            CGRect(x: -width * 0.09, y: width * 2.42, width: width * 0.18, height: width * 0.08),
            cornerRadius: 1, fill: steelDeep, stroke: .clear, lineWidth: 0
        )
        crown.zPosition = 5
        node.addChild(crown)

        // --- Antenna (thin, tapered with lightning rod tip) ---
        let antennaPath = CGMutablePath()
        antennaPath.move(to: CGPoint(x: -width * 0.015, y: width * 2.50))
        antennaPath.addLine(to: CGPoint(x: -width * 0.004, y: width * 2.82))
        antennaPath.addLine(to: CGPoint(x: 0, y: width * 2.88))  // lightning rod tip
        antennaPath.addLine(to: CGPoint(x: width * 0.004, y: width * 2.82))
        antennaPath.addLine(to: CGPoint(x: width * 0.015, y: width * 2.50))
        antennaPath.closeSubpath()
        let antenna = SKShapeNode(path: antennaPath)
        antenna.fillColor = SKColor(red: 0.23, green: 0.29, blue: 0.37, alpha: 1.0)
        antenna.strokeColor = Palette.stroke
        antenna.lineWidth = 0.6
        antenna.zPosition = 6
        node.addChild(antenna)

        return node
    }
}
