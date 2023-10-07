//
//  RadioRouter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SwiftUI

protocol RadioRoutingLogic {
  func toPlaylistSelector(module: MMD)
}

protocol RadioDataPassing {
  var dataStore: RadioDataStore? { get }
}

class RadioRouter: NSObject, RadioRoutingLogic, RadioDataPassing {
  weak var viewController: RadioViewController?
  var dataStore: RadioDataStore?
    
    func toPlaylistSelector(module: MMD) {
        let hvc = PlaylistSelectorStore.buildPicker(module: module)
        viewController?.present(hvc, animated: true, completion: nil)
    }
}
