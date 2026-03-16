//
//  AppDelegate.swift
//  dominoes
//
//  Created by shan on 2026/2/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
#if os(tvOS)
        configureRootWindowIfNeeded()
#endif
        return true
    }

    #if os(tvOS)
    private func configureRootWindowIfNeeded() {
        guard window == nil else { return }
        let gameViewController = GameViewController()
        let gameWindow = UIWindow(frame: UIScreen.main.bounds)
        gameWindow.rootViewController = gameViewController
        gameWindow.makeKeyAndVisible()
        window = gameWindow
    }
    #endif

}
