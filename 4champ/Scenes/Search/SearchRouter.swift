//
//  SearchRouter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import SwiftUI

protocol SearchRoutingLogic
{
  func toComposerList(title: String, groupId: Int)
  func toModulesList(title: String, composerId: Int)
  func toPlaylistSelector(module: MMD)
}

protocol SearchDataPassing
{
  var dataStore: SearchDataStore? { get }
}

class SearchRouter: NSObject, SearchRoutingLogic, SearchDataPassing
{
  weak var viewController: SearchViewController?
  var dataStore: SearchDataStore?
  
  // MARK: Routing
  func toComposerList(title: String, groupId: Int) {
    spawnSearch(title: title, type: .group, id: groupId)
  }
  func toModulesList(title: String, composerId: Int) {
    spawnSearch(title: title, type: .composer, id: composerId)
  }
  
  func toPlaylistSelector(module: MMD) {
    let pls = PlaylistSelectorStore()
    var contentView = PlaylistPickerView(dismissAction: { self.viewController?.dismiss(animated: true, completion: nil)}, store: pls)
    pls.setup()
    pls.doPrepare(mod: module)
    contentView.addToPlaylistAction = { b in
      pls.addToPlaylist(playlistIndex: b)
    }
    let hvc = UIHostingController(rootView: contentView)
    pls.hostingController = hvc
    viewController?.present(hvc, animated: true, completion: nil)
  }
  
  /// Instantiate another SearchViewController and prepare it for
  /// composer/group list display by setting the autoList parameters
  private func spawnSearch(title: String, type: SearchType, id: Int) {
    if let vc = viewController?.storyboard?.instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController {
      vc.shouldDisplaySearchBar = false
      if var ds = vc.router?.dataStore {
        ds.autoListType = type
        ds.autoListTitle = title
        ds.autoListId = id
      }
      viewController?.navigationController?.pushViewController(vc, animated: true)
    }
  }
}
