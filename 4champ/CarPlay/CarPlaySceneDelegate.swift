//
//  CarPlaySceneDelegate.swift
//  4champ Amiga Music Player
//
//  Copyright © 2026 Aleksi Sitomaniemi. All rights reserved.
//

import CarPlay
import UIKit

/// Implements `CPTemplateApplicationSceneDelegate` for the CarPlay scene.
/// Note: CPSearchTemplate was removed in iOS 26. Discovery uses CPListTemplate instead.
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    private var carPlayController: CarPlayController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        let controller = CarPlayController(interfaceController: interfaceController)
        carPlayController = controller
        interfaceController.setRootTemplate(controller.makeRootTemplate(),
                                            animated: false,
                                            completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        carPlayController = nil
    }
}
