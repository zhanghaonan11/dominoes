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

        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.text = landmark.displayName
        label.fontSize = max(width * 0.19, 10)
        label.fontColor = SKColor(white: 0.2, alpha: 0.95)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: 0, y: -width * 0.24)
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
            return 2.43
        case .bigBen:
            return 2.71
        case .leaningTowerOfPisa:
            return 2.38
        case .sydneyOperaHouse:
            return 1.34
        case .greatPyramidOfGiza:
            return 1.38
        case .burjKhalifa:
            return 3.08
        case .tajMahal:
            return 1.29
        case .colosseum:
            return 0.78
        case .arcDeTriomphe:
            return 1.1
        case .empireStateBuilding:
            return 2.84
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
        addGroundShadow(to: node, width: width * 0.95, yOffset: -width * 0.03, alpha: 0.22)

        let base = makePolygon(
            [
                CGPoint(x: -width * 0.5, y: 0),
                CGPoint(x: -width * 0.34, y: width * 0.88),
                CGPoint(x: width * 0.34, y: width * 0.88),
                CGPoint(x: width * 0.5, y: 0)
            ],
            fill: SKColor(red: 0.38, green: 0.42, blue: 0.48, alpha: 1.0),
            lineWidth: 1.1
        )
        node.addChild(base)

        let centerPath = CGMutablePath()
        centerPath.move(to: CGPoint(x: -width * 0.08, y: width * 0.88))
        centerPath.addLine(to: CGPoint(x: -width * 0.15, y: width * 1.75))
        centerPath.addLine(to: CGPoint(x: width * 0.15, y: width * 1.75))
        centerPath.addLine(to: CGPoint(x: width * 0.08, y: width * 0.88))
        centerPath.closeSubpath()
        let center = SKShapeNode(path: centerPath)
        center.fillColor = SKColor(red: 0.34, green: 0.38, blue: 0.45, alpha: 1.0)
        center.strokeColor = Palette.stroke
        center.lineWidth = 1.0
        node.addChild(center)

        let top = makeRect(
            CGRect(x: -width * 0.1, y: width * 1.75, width: width * 0.2, height: width * 0.66),
            cornerRadius: 1.5,
            fill: SKColor(red: 0.29, green: 0.33, blue: 0.4, alpha: 1.0)
        )
        node.addChild(top)

        let firstDeck = makeRect(
            CGRect(x: -width * 0.28, y: width * 0.83, width: width * 0.56, height: width * 0.08),
            cornerRadius: 1,
            fill: SKColor(red: 0.27, green: 0.31, blue: 0.37, alpha: 1.0),
            stroke: .clear,
            lineWidth: 0
        )
        firstDeck.zPosition = 2
        node.addChild(firstDeck)

        let secondDeck = makeRect(
            CGRect(x: -width * 0.2, y: width * 1.65, width: width * 0.4, height: width * 0.06),
            cornerRadius: 1,
            fill: SKColor(red: 0.24, green: 0.28, blue: 0.34, alpha: 1.0),
            stroke: .clear,
            lineWidth: 0
        )
        secondDeck.zPosition = 2
        node.addChild(secondDeck)

        let mast = SKShapeNode(rectOf: CGSize(width: 2.6, height: width * 0.42))
        mast.position = CGPoint(x: 0, y: width * 2.28)
        mast.fillColor = SKColor(red: 0.18, green: 0.22, blue: 0.29, alpha: 1.0)
        mast.strokeColor = .clear
        mast.zPosition = 2
        node.addChild(mast)

        let flag = makeRect(
            CGRect(x: width * 0.03, y: width * 2.37, width: width * 0.16, height: width * 0.06),
            cornerRadius: 0,
            fill: SKColor(red: 0.03, green: 0.42, blue: 0.74, alpha: 1.0),
            stroke: .clear,
            lineWidth: 0
        )
        flag.zPosition = 2
        node.addChild(flag)

        let bracePath = CGMutablePath()
        bracePath.move(to: CGPoint(x: -width * 0.34, y: width * 0.18))
        bracePath.addLine(to: CGPoint(x: width * 0.34, y: width * 0.78))
        bracePath.move(to: CGPoint(x: width * 0.34, y: width * 0.18))
        bracePath.addLine(to: CGPoint(x: -width * 0.34, y: width * 0.78))
        bracePath.move(to: CGPoint(x: -width * 0.2, y: width * 1.04))
        bracePath.addLine(to: CGPoint(x: width * 0.2, y: width * 1.58))
        bracePath.move(to: CGPoint(x: width * 0.2, y: width * 1.04))
        bracePath.addLine(to: CGPoint(x: -width * 0.2, y: width * 1.58))
        let braces = SKShapeNode(path: bracePath)
        braces.strokeColor = SKColor(white: 0.12, alpha: 0.55)
        braces.lineWidth = 1
        braces.zPosition = 3
        node.addChild(braces)

        addSoftSpecularLine(to: node, from: CGPoint(x: -width * 0.36, y: width * 0.08), to: CGPoint(x: -width * 0.23, y: width * 0.8), alpha: 0.28)
        addFacadeLighting(to: node, rect: CGRect(x: -width * 0.1, y: width * 1.75, width: width * 0.2, height: width * 0.66), cornerRadius: 1)

        return node
    }

    private static func buildBigBen(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 0.7, yOffset: -width * 0.02, alpha: 0.2)

        let bodyRect = CGRect(x: -width * 0.2, y: 0, width: width * 0.4, height: width * 2.02)
        let body = makeRect(bodyRect, cornerRadius: 3, fill: SKColor(red: 0.78, green: 0.66, blue: 0.48, alpha: 1.0), lineWidth: 1.1)
        node.addChild(body)
        addFacadeLighting(to: node, rect: bodyRect, cornerRadius: 2)

        addWindowGrid(
            to: node,
            rect: CGRect(x: -width * 0.15, y: width * 0.24, width: width * 0.3, height: width * 1.14),
            columns: 2,
            rows: 6,
            insetX: width * 0.03,
            insetY: width * 0.04
        )

        let clockFrame = SKShapeNode(circleOfRadius: width * 0.115)
        clockFrame.position = CGPoint(x: 0, y: width * 1.63)
        clockFrame.fillColor = SKColor(white: 0.95, alpha: 1.0)
        clockFrame.strokeColor = SKColor(red: 0.52, green: 0.43, blue: 0.31, alpha: 1.0)
        clockFrame.lineWidth = 1.4
        clockFrame.zPosition = 4
        node.addChild(clockFrame)

        let clockFace = SKShapeNode(circleOfRadius: width * 0.085)
        clockFace.position = CGPoint(x: 0, y: width * 1.63)
        clockFace.fillColor = SKColor(white: 0.99, alpha: 1.0)
        clockFace.strokeColor = SKColor(white: 0.12, alpha: 0.35)
        clockFace.lineWidth = 0.6
        clockFace.zPosition = 5
        node.addChild(clockFace)

        let minuteHand = CGMutablePath()
        minuteHand.move(to: CGPoint(x: 0, y: width * 1.63))
        minuteHand.addLine(to: CGPoint(x: width * 0.045, y: width * 1.67))
        let minute = SKShapeNode(path: minuteHand)
        minute.strokeColor = SKColor(white: 0.2, alpha: 0.8)
        minute.lineWidth = 1.1
        minute.zPosition = 6
        node.addChild(minute)

        let hourHand = CGMutablePath()
        hourHand.move(to: CGPoint(x: 0, y: width * 1.63))
        hourHand.addLine(to: CGPoint(x: -width * 0.03, y: width * 1.6))
        let hour = SKShapeNode(path: hourHand)
        hour.strokeColor = SKColor(white: 0.2, alpha: 0.8)
        hour.lineWidth = 1.4
        hour.zPosition = 6
        node.addChild(hour)

        let roof = makePolygon(
            [
                CGPoint(x: -width * 0.24, y: width * 2.02),
                CGPoint(x: 0, y: width * 2.48),
                CGPoint(x: width * 0.24, y: width * 2.02)
            ],
            fill: SKColor(red: 0.67, green: 0.55, blue: 0.38, alpha: 1.0),
            lineWidth: 1.1
        )
        node.addChild(roof)

        let roofShade = makePolygon(
            [
                CGPoint(x: 0, y: width * 2.48),
                CGPoint(x: width * 0.24, y: width * 2.02),
                CGPoint(x: width * 0.08, y: width * 2.02)
            ],
            fill: SKColor(white: 0.0, alpha: 0.14),
            stroke: .clear,
            lineWidth: 0
        )
        roofShade.zPosition = 2
        node.addChild(roofShade)

        let spire = SKShapeNode(rectOf: CGSize(width: 3, height: width * 0.25))
        spire.position = CGPoint(x: 0, y: width * 2.58)
        spire.fillColor = SKColor(red: 0.42, green: 0.35, blue: 0.26, alpha: 1.0)
        spire.strokeColor = .clear
        spire.zPosition = 3
        node.addChild(spire)

        return node
    }

    private static func buildLeaningTowerOfPisa(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 0.8, yOffset: -width * 0.02, alpha: 0.2)

        let shaft = SKNode()
        shaft.zRotation = -.pi / 15
        node.addChild(shaft)

        let bodyRect = CGRect(x: -width * 0.13, y: 0, width: width * 0.26, height: width * 2.12)
        let body = makeRect(bodyRect, cornerRadius: width * 0.06, fill: SKColor(red: 0.91, green: 0.9, blue: 0.84, alpha: 1.0))
        shaft.addChild(body)
        addFacadeLighting(to: shaft, rect: bodyRect, cornerRadius: 2)

        for index in 0...7 {
            let y = width * 0.24 + CGFloat(index) * width * 0.24
            let band = makeRect(
                CGRect(x: -width * 0.135, y: y, width: width * 0.27, height: width * 0.028),
                cornerRadius: 1,
                fill: SKColor(red: 0.8, green: 0.78, blue: 0.72, alpha: 1.0),
                stroke: .clear,
                lineWidth: 0
            )
            band.zPosition = 3
            shaft.addChild(band)

            let ringWindows = 5
            for col in 0..<ringWindows {
                let x = -width * 0.095 + CGFloat(col) * width * 0.048
                let slit = SKShapeNode(rectOf: CGSize(width: width * 0.018, height: width * 0.03), cornerRadius: 1)
                slit.position = CGPoint(x: x, y: y + width * 0.015)
                slit.fillColor = Palette.darkWindow
                slit.strokeColor = .clear
                slit.zPosition = 4
                shaft.addChild(slit)
            }
        }

        let top = SKShapeNode(circleOfRadius: width * 0.13)
        top.position = CGPoint(x: 0, y: width * 2.16)
        top.fillColor = SKColor(red: 0.9, green: 0.88, blue: 0.82, alpha: 1.0)
        top.strokeColor = Palette.stroke
        top.lineWidth = 1
        top.zPosition = 3
        shaft.addChild(top)

        let lantern = SKShapeNode(rectOf: CGSize(width: width * 0.04, height: width * 0.11), cornerRadius: 1)
        lantern.position = CGPoint(x: 0, y: width * 2.32)
        lantern.fillColor = SKColor(red: 0.74, green: 0.72, blue: 0.66, alpha: 1.0)
        lantern.strokeColor = .clear
        lantern.zPosition = 4
        shaft.addChild(lantern)

        return node
    }

    private static func buildSydneyOperaHouse(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 1.15, yOffset: -width * 0.03, alpha: 0.18)

        let baseRect = CGRect(x: -width * 0.54, y: 0, width: width * 1.08, height: width * 0.22)
        let base = makeRect(baseRect, cornerRadius: 2, fill: SKColor(red: 0.66, green: 0.74, blue: 0.82, alpha: 1.0))
        node.addChild(base)

        let waterStrip = makeRect(
            CGRect(x: -width * 0.54, y: -width * 0.035, width: width * 1.08, height: width * 0.03),
            cornerRadius: 0,
            fill: SKColor(red: 0.34, green: 0.57, blue: 0.75, alpha: 0.55),
            stroke: .clear,
            lineWidth: 0
        )
        waterStrip.zPosition = 1
        node.addChild(waterStrip)

        let shells: [[CGPoint]] = [
            [CGPoint(x: -width * 0.43, y: width * 0.2), CGPoint(x: -width * 0.1, y: width * 1.2), CGPoint(x: width * 0.03, y: width * 0.2)],
            [CGPoint(x: -width * 0.1, y: width * 0.2), CGPoint(x: width * 0.11, y: width * 1.34), CGPoint(x: width * 0.35, y: width * 0.2)],
            [CGPoint(x: width * 0.1, y: width * 0.2), CGPoint(x: width * 0.46, y: width * 1.03), CGPoint(x: width * 0.53, y: width * 0.2)]
        ]

        for (index, points) in shells.enumerated() {
            let shell = makePolygon(points, fill: SKColor(white: 0.96 + CGFloat(index) * 0.01, alpha: 1.0), lineWidth: 1)
            shell.zPosition = 2 + CGFloat(index)
            node.addChild(shell)

            let maxX = points.map { $0.x }.max() ?? 0
            let minY = points.map { $0.y }.min() ?? 0
            let maxY = points.map { $0.y }.max() ?? 0
            let shade = makePolygon(
                [
                    CGPoint(x: maxX * 0.88, y: minY),
                    CGPoint(x: maxX, y: minY),
                    CGPoint(x: points[1].x, y: maxY)
                ],
                fill: SKColor(white: 0.0, alpha: 0.12),
                stroke: .clear,
                lineWidth: 0
            )
            shade.zPosition = shell.zPosition + 0.1
            node.addChild(shade)

            for t in 1...4 {
                let ratio = CGFloat(t) / 5
                let from = CGPoint(
                    x: points[0].x + (points[1].x - points[0].x) * ratio,
                    y: points[0].y + (points[1].y - points[0].y) * ratio
                )
                let to = CGPoint(
                    x: points[2].x + (points[1].x - points[2].x) * ratio,
                    y: points[2].y + (points[1].y - points[2].y) * ratio
                )
                addSoftSpecularLine(to: node, from: from, to: to, alpha: 0.18, lineWidth: 0.8)
            }
        }

        return node
    }

    private static func buildGreatPyramidOfGiza(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 1.05, yOffset: -width * 0.02, alpha: 0.2)

        let main = makePolygon(
            [
                CGPoint(x: -width * 0.56, y: 0),
                CGPoint(x: 0, y: width * 1.38),
                CGPoint(x: width * 0.56, y: 0)
            ],
            fill: SKColor(red: 0.85, green: 0.73, blue: 0.49, alpha: 1.0),
            lineWidth: 1.2
        )
        node.addChild(main)

        let rightFace = makePolygon(
            [
                CGPoint(x: 0, y: width * 1.38),
                CGPoint(x: width * 0.56, y: 0),
                CGPoint(x: width * 0.05, y: 0)
            ],
            fill: SKColor(red: 0.73, green: 0.6, blue: 0.38, alpha: 1.0),
            stroke: .clear,
            lineWidth: 0
        )
        rightFace.zPosition = 2
        node.addChild(rightFace)

        let small = makePolygon(
            [
                CGPoint(x: -width * 0.18, y: 0),
                CGPoint(x: -width * 0.01, y: width * 0.44),
                CGPoint(x: width * 0.12, y: 0)
            ],
            fill: SKColor(red: 0.78, green: 0.65, blue: 0.42, alpha: 1.0),
            lineWidth: 0.8
        )
        small.zPosition = 3
        node.addChild(small)

        for index in 1...10 {
            let y = width * 1.38 * CGFloat(index) / 11
            let widthFactor = 1 - CGFloat(index) / 12
            let band = SKShapeNode(rectOf: CGSize(width: width * 1.05 * widthFactor, height: 0.9))
            band.position = CGPoint(x: 0, y: y)
            band.fillColor = SKColor(white: 0.0, alpha: 0.07)
            band.strokeColor = .clear
            band.zPosition = 4
            node.addChild(band)
        }

        addSoftSpecularLine(to: node, from: CGPoint(x: -width * 0.1, y: width * 0.08), to: CGPoint(x: -width * 0.01, y: width * 1.3), alpha: 0.2)

        return node
    }

    private static func buildBurjKhalifa(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 0.8, yOffset: -width * 0.03, alpha: 0.22)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width * 0.22, y: 0))
        path.addLine(to: CGPoint(x: -width * 0.13, y: width * 1.34))
        path.addLine(to: CGPoint(x: -width * 0.085, y: width * 1.74))
        path.addLine(to: CGPoint(x: -width * 0.055, y: width * 2.15))
        path.addLine(to: CGPoint(x: -width * 0.03, y: width * 2.38))
        path.addLine(to: CGPoint(x: 0, y: width * 2.73))
        path.addLine(to: CGPoint(x: width * 0.03, y: width * 2.38))
        path.addLine(to: CGPoint(x: width * 0.055, y: width * 2.15))
        path.addLine(to: CGPoint(x: width * 0.095, y: width * 1.74))
        path.addLine(to: CGPoint(x: width * 0.14, y: width * 1.34))
        path.addLine(to: CGPoint(x: width * 0.25, y: 0))
        path.closeSubpath()

        let tower = SKShapeNode(path: path)
        tower.fillColor = SKColor(red: 0.66, green: 0.77, blue: 0.87, alpha: 1.0)
        tower.strokeColor = Palette.stroke
        tower.lineWidth = 1
        node.addChild(tower)

        let shadePath = CGMutablePath()
        shadePath.move(to: CGPoint(x: width * 0.02, y: 0))
        shadePath.addLine(to: CGPoint(x: width * 0.25, y: 0))
        shadePath.addLine(to: CGPoint(x: width * 0.14, y: width * 1.34))
        shadePath.addLine(to: CGPoint(x: width * 0.095, y: width * 1.74))
        shadePath.addLine(to: CGPoint(x: width * 0.055, y: width * 2.15))
        shadePath.addLine(to: CGPoint(x: width * 0.03, y: width * 2.38))
        shadePath.addLine(to: CGPoint(x: 0, y: width * 2.73))
        shadePath.closeSubpath()
        let shade = SKShapeNode(path: shadePath)
        shade.fillColor = SKColor(white: 0.0, alpha: 0.13)
        shade.strokeColor = .clear
        shade.zPosition = 2
        node.addChild(shade)

        let bodyRect = CGRect(x: -width * 0.11, y: width * 0.12, width: width * 0.22, height: width * 2.3)
        addWindowGrid(to: node, rect: bodyRect, columns: 3, rows: 14, insetX: width * 0.02, insetY: width * 0.03, z: 3)
        addHorizontalBands(to: node, rect: bodyRect, count: 12, color: SKColor(white: 1.0, alpha: 0.08), z: 3)

        let spire = SKShapeNode(rectOf: CGSize(width: 2.4, height: width * 0.34))
        spire.position = CGPoint(x: 0, y: width * 2.91)
        spire.fillColor = SKColor(red: 0.54, green: 0.64, blue: 0.75, alpha: 1.0)
        spire.strokeColor = .clear
        spire.zPosition = 4
        node.addChild(spire)

        return node
    }

    private static func buildTajMahal(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 1.1, yOffset: -width * 0.02, alpha: 0.2)

        let terraceRect = CGRect(x: -width * 0.5, y: 0, width: width, height: width * 0.21)
        let terrace = makeRect(terraceRect, cornerRadius: 2, fill: SKColor(white: 0.94, alpha: 1.0))
        node.addChild(terrace)
        addHorizontalBands(to: node, rect: terraceRect, count: 4, color: SKColor(white: 0.0, alpha: 0.05), z: 2)

        let centerRect = CGRect(x: -width * 0.22, y: width * 0.2, width: width * 0.44, height: width * 0.72)
        let center = makeRect(centerRect, cornerRadius: 4, fill: SKColor(white: 0.96, alpha: 1.0))
        node.addChild(center)
        addFacadeLighting(to: node, rect: centerRect, cornerRadius: 2)

        let door = SKShapeNode(
            rect: CGRect(x: -width * 0.08, y: width * 0.22, width: width * 0.16, height: width * 0.3),
            cornerRadius: width * 0.08
        )
        door.fillColor = SKColor(red: 0.38, green: 0.42, blue: 0.48, alpha: 0.6)
        door.strokeColor = .clear
        door.zPosition = 3
        node.addChild(door)

        let dome = SKShapeNode(circleOfRadius: width * 0.165)
        dome.position = CGPoint(x: 0, y: width * 1.07)
        dome.fillColor = SKColor(white: 0.97, alpha: 1.0)
        dome.strokeColor = Palette.stroke
        dome.lineWidth = 1
        dome.zPosition = 3
        node.addChild(dome)

        let domeTop = SKShapeNode(rectOf: CGSize(width: width * 0.03, height: width * 0.11), cornerRadius: 1)
        domeTop.position = CGPoint(x: 0, y: width * 1.23)
        domeTop.fillColor = SKColor(red: 0.72, green: 0.67, blue: 0.54, alpha: 1.0)
        domeTop.strokeColor = .clear
        domeTop.zPosition = 4
        node.addChild(domeTop)

        let minaretRects = [
            CGRect(x: -width * 0.44, y: width * 0.2, width: width * 0.1, height: width * 0.87),
            CGRect(x: width * 0.34, y: width * 0.2, width: width * 0.1, height: width * 0.87)
        ]

        for rect in minaretRects {
            let minaret = makeRect(rect, cornerRadius: 2, fill: SKColor(white: 0.94, alpha: 1.0))
            minaret.zPosition = 2
            node.addChild(minaret)
            addHorizontalBands(to: node, rect: rect, count: 6, color: SKColor(white: 0.0, alpha: 0.05), z: 3)

            let cap = SKShapeNode(circleOfRadius: width * 0.048)
            cap.position = CGPoint(x: rect.midX, y: rect.maxY + width * 0.03)
            cap.fillColor = SKColor(white: 0.95, alpha: 1.0)
            cap.strokeColor = Palette.stroke
            cap.lineWidth = 0.8
            cap.zPosition = 3
            node.addChild(cap)
        }

        return node
    }

    private static func buildColosseum(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 1.12, yOffset: -width * 0.03, alpha: 0.22)

        let shellRect = CGRect(x: -width * 0.5, y: 0, width: width, height: width * 0.78)
        let shell = makeRect(shellRect, cornerRadius: width * 0.17, fill: SKColor(red: 0.8, green: 0.66, blue: 0.5, alpha: 1.0))
        node.addChild(shell)
        addFacadeLighting(to: node, rect: shellRect, cornerRadius: width * 0.14)

        let rows = 3
        let cols = 7
        for row in 0..<rows {
            let yBase = width * 0.09 + CGFloat(row) * width * 0.21
            for col in 0..<cols {
                let x = -width * 0.43 + CGFloat(col) * width * 0.14
                let arch = SKShapeNode(
                    rect: CGRect(x: x, y: yBase, width: width * 0.095, height: width * 0.14),
                    cornerRadius: width * 0.035
                )
                arch.fillColor = SKColor(red: 0.47, green: 0.35, blue: 0.24, alpha: 0.85)
                arch.strokeColor = .clear
                arch.zPosition = 3
                node.addChild(arch)
            }
        }

        let topBand = makeRect(
            CGRect(x: -width * 0.5, y: width * 0.67, width: width, height: width * 0.08),
            cornerRadius: 1,
            fill: SKColor(red: 0.72, green: 0.57, blue: 0.42, alpha: 1.0),
            stroke: .clear,
            lineWidth: 0
        )
        topBand.zPosition = 2
        node.addChild(topBand)

        for crack in 0...3 {
            let x = -width * 0.35 + CGFloat(crack) * width * 0.24
            let crackPath = CGMutablePath()
            crackPath.move(to: CGPoint(x: x, y: width * 0.7))
            crackPath.addLine(to: CGPoint(x: x - width * 0.015, y: width * 0.52))
            crackPath.addLine(to: CGPoint(x: x + width * 0.008, y: width * 0.34))
            let crackLine = SKShapeNode(path: crackPath)
            crackLine.strokeColor = SKColor(white: 0.0, alpha: 0.12)
            crackLine.lineWidth = 0.9
            crackLine.zPosition = 4
            node.addChild(crackLine)
        }

        return node
    }

    private static func buildArcDeTriomphe(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 0.95, yOffset: -width * 0.02, alpha: 0.2)

        let frameRect = CGRect(x: -width * 0.45, y: 0, width: width * 0.9, height: width * 1.1)
        let frame = makeRect(frameRect, cornerRadius: 2, fill: SKColor(red: 0.88, green: 0.83, blue: 0.73, alpha: 1.0))
        node.addChild(frame)
        addFacadeLighting(to: node, rect: frameRect, cornerRadius: 2)

        let arch = SKShapeNode(
            rect: CGRect(x: -width * 0.18, y: 0, width: width * 0.36, height: width * 0.64),
            cornerRadius: width * 0.05
        )
        arch.fillColor = SKColor(red: 0.45, green: 0.49, blue: 0.53, alpha: 0.62)
        arch.strokeColor = .clear
        arch.zPosition = 3
        node.addChild(arch)

        let leftInset = makeRect(
            CGRect(x: -width * 0.36, y: width * 0.22, width: width * 0.12, height: width * 0.32),
            cornerRadius: 1,
            fill: SKColor(white: 1.0, alpha: 0.16),
            stroke: .clear,
            lineWidth: 0
        )
        leftInset.zPosition = 3
        node.addChild(leftInset)

        let rightInset = makeRect(
            CGRect(x: width * 0.24, y: width * 0.22, width: width * 0.12, height: width * 0.32),
            cornerRadius: 1,
            fill: SKColor(white: 0.0, alpha: 0.08),
            stroke: .clear,
            lineWidth: 0
        )
        rightInset.zPosition = 3
        node.addChild(rightInset)

        let topBand = makeRect(
            CGRect(x: -width * 0.45, y: width * 0.86, width: width * 0.9, height: width * 0.1),
            cornerRadius: 1,
            fill: SKColor(red: 0.78, green: 0.71, blue: 0.61, alpha: 1.0),
            stroke: .clear,
            lineWidth: 0
        )
        topBand.zPosition = 2
        node.addChild(topBand)

        let frieze = SKShapeNode(rectOf: CGSize(width: width * 0.76, height: width * 0.02))
        frieze.position = CGPoint(x: 0, y: width * 0.82)
        frieze.fillColor = SKColor(white: 0.0, alpha: 0.08)
        frieze.strokeColor = .clear
        frieze.zPosition = 3
        node.addChild(frieze)

        return node
    }

    private static func buildEmpireStateBuilding(width: CGFloat) -> SKNode {
        let node = SKNode()
        addGroundShadow(to: node, width: width * 0.9, yOffset: -width * 0.03, alpha: 0.24)

        let lowerRect = CGRect(x: -width * 0.29, y: 0, width: width * 0.58, height: width * 1.26)
        let lower = makeRect(lowerRect, cornerRadius: 2, fill: SKColor(red: 0.56, green: 0.63, blue: 0.72, alpha: 1.0))
        node.addChild(lower)
        addFacadeLighting(to: node, rect: lowerRect, cornerRadius: 2)

        let middleRect = CGRect(x: -width * 0.2, y: width * 1.26, width: width * 0.4, height: width * 0.72)
        let middle = makeRect(middleRect, cornerRadius: 1, fill: SKColor(red: 0.5, green: 0.57, blue: 0.67, alpha: 1.0))
        node.addChild(middle)
        addFacadeLighting(to: node, rect: middleRect, cornerRadius: 1)

        let upperRect = CGRect(x: -width * 0.12, y: width * 1.98, width: width * 0.24, height: width * 0.46)
        let upper = makeRect(upperRect, cornerRadius: 1, fill: SKColor(red: 0.44, green: 0.51, blue: 0.6, alpha: 1.0))
        node.addChild(upper)
        addFacadeLighting(to: node, rect: upperRect, cornerRadius: 1)

        addWindowGrid(
            to: node,
            rect: CGRect(x: -width * 0.25, y: width * 0.08, width: width * 0.5, height: width * 1.08),
            columns: 6,
            rows: 11,
            insetX: width * 0.02,
            insetY: width * 0.03
        )
        addWindowGrid(
            to: node,
            rect: CGRect(x: -width * 0.16, y: width * 1.31, width: width * 0.32, height: width * 0.61),
            columns: 4,
            rows: 7,
            insetX: width * 0.02,
            insetY: width * 0.02
        )

        let crown = makeRect(
            CGRect(x: -width * 0.09, y: width * 2.34, width: width * 0.18, height: width * 0.08),
            cornerRadius: 1,
            fill: SKColor(red: 0.36, green: 0.42, blue: 0.5, alpha: 1.0),
            stroke: .clear,
            lineWidth: 0
        )
        crown.zPosition = 4
        node.addChild(crown)

        let antenna = SKShapeNode(rectOf: CGSize(width: 2.8, height: width * 0.43))
        antenna.position = CGPoint(x: 0, y: width * 2.62)
        antenna.fillColor = SKColor(red: 0.23, green: 0.29, blue: 0.37, alpha: 1.0)
        antenna.strokeColor = .clear
        antenna.zPosition = 5
        node.addChild(antenna)

        return node
    }
}
