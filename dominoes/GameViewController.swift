//
//  GameViewController.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    private var gameScene: GameScene?

    override func viewDidLoad() {
        super.viewDidLoad()
        if !(view is SKView) {
            view = SKView(frame: UIScreen.main.bounds)
        }
        guard let view = self.view as? SKView else { return }
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let view = self.view as? SKView else { return }
        guard view.bounds.width > 0, view.bounds.height > 0 else { return }

        if gameScene == nil {
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            gameScene = scene
        }

        guard let gameScene else { return }

        if gameScene.size != view.bounds.size {
            gameScene.size = view.bounds.size
        }

        if view.scene !== gameScene {
            view.presentScene(gameScene)
        }

        gameScene.refreshLayoutForSafeAreaIfNeeded()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        gameScene?.refreshLayoutForSafeAreaIfNeeded()
    }

#if os(iOS)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
#endif
}
