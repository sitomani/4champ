//
//  LocalRouter.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SwiftUI

protocol LocalRoutingLogic {
    func toPlaylistSelector(module: MMD)
}

protocol LocalDataPassing {
  var dataStore: LocalDataStore? { get }
}

class LocalRouter: NSObject, LocalRoutingLogic, LocalDataPassing {
  weak var viewController: LocalViewController?
  var dataStore: LocalDataStore?

  // MARK: Routing

    func toPlaylistSelector(module: MMD) {
        let hvc = PlaylistSelectorStore.buildPicker(module: module)
        viewController?.present(hvc, animated: true, completion: nil)
    }
}
