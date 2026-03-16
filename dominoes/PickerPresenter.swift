import UIKit
import SpriteKit

enum PickerPresenter {
    struct Option {
        let title: String
        let isSelected: Bool
    }

    static func presentActionSheet(
        title: String,
        message: String?,
        options: [Option],
        anchor: CGPoint,
        scene: SKScene,
        onSelect: @escaping (Int) -> Void
    ) {
        guard let presenter = findViewController(from: scene.view) else { return }

        let style: UIAlertController.Style = {
#if os(tvOS)
            return .alert
#else
            return .actionSheet
#endif
        }()
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)

        for (index, option) in options.enumerated() {
            let displayTitle = option.isSelected ? "\(option.title) ✓" : option.title
            alert.addAction(UIAlertAction(title: displayTitle, style: .default) { _ in
                onSelect(index)
            })
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

#if !os(tvOS)
        if let popover = alert.popoverPresentationController, let sceneView = scene.view {
            popover.sourceView = sceneView
            let anchorInView = scene.convertPoint(toView: anchor)
            popover.sourceRect = CGRect(x: anchorInView.x, y: anchorInView.y, width: 1, height: 1)
            popover.permittedArrowDirections = [.up, .down]
        }
#endif

        presenter.present(alert, animated: true)
    }

    private static func findViewController(from view: UIView?) -> UIViewController? {
        var responder: UIResponder? = view
        while let current = responder {
            if let controller = current as? UIViewController { return controller }
            responder = current.next
        }
        return nil
    }
}
