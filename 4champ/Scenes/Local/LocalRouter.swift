//
//  LocalRouter.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//


import UIKit
import SwiftUI

protocol LocalRoutingLogic
{
    func routeToPlaylistSelector(module: MMD)
}

protocol LocalDataPassing
{
  var dataStore: LocalDataStore? { get }
}

class LocalRouter: NSObject, LocalRoutingLogic, LocalDataPassing
{
  weak var viewController: LocalViewController?
  var dataStore: LocalDataStore?
  
  // MARK: Routing
  
    func routeToPlaylistSelector(module: MMD) {
        let pls = PlaylistSelectorStore()
        var contentView = PlaylistPickerView(dismissAction: { self.viewController?.dismiss(animated: true, completion: nil)}, store: pls)
        pls.setup()
        pls.doPrepare(mod: module)
        contentView.addToPlaylistAction = { b in
            pls.addToPlaylist(playlistIndex: b)
        }
        let hvc = UIHostingController(rootView: contentView)
        viewController?.present(hvc, animated: true, completion: nil)
    }
}
