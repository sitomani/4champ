//
//  SearchPresenter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SearchPresentationLogic
{
  func presentModules(response: Search.ModuleResponse)
  func presentGroups(response: Search.GroupResponse)
  func presentComposers(response: Search.ComposerResponse)
  func presentDownloadProgress(response: Search.ProgressResponse)
}

/// Search result presentation class. Presenter wraps the json originating
/// objects into presentable structs for `SearchViewController`
class SearchPresenter: SearchPresentationLogic
{
  weak var viewController: SearchDisplayLogic?
  
  func presentGroups(response: Search.GroupResponse) {
    let groups: [GroupInfo] = response.result.compactMap { g in
      guard let gUri = URL.init(string: g.href),
        let idString = gUri.query?.split(separator: "=").last else { return nil }
      return GroupInfo(id: Int(idString) ?? 0, name: g.label)
    }
    viewController?.displayResult(viewModel: Search.ViewModel(modules: [],
                                                              composers: [],
                                                              groups: groups))
  }
  
  func presentComposers(response: Search.ComposerResponse) {
    let composers: [ComposerInfo] = response.result.compactMap { c in
      guard let cUri = URL.init(string: c.handle.href) else { return nil }
      guard let idString  = cUri.query?.split(separator: "=").last else { return nil }
      return ComposerInfo(id: Int(idString) ?? 0, name: c.handle.label, realName: c.realname, groups: c.groups)
    }
    viewController?.displayResult(viewModel: Search.ViewModel(modules: [],
                                                              composers: composers,
                                                              groups: []))
  }
  
  func presentModules(response: Search.ModuleResponse) {
    let mods: [MMD] = response.result.map {
      let modUri = URL.init(string: $0.name.href)
      var id: Int = 0
      if let idString = modUri?.query?.split(separator: "=").last {
          id = Int(idString) ?? 0
      }
      var mmd = MMD()
      mmd.id = id
      mmd.downloadPath = modUri
      mmd.name = $0.name.label
      mmd.size = Int($0.size.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
      mmd.type = $0.format
      mmd.composer = $0.composer.label
      return mmd
    }
    
    viewController?.displayResult(viewModel: Search.ViewModel(modules: mods,
                                                              composers: [],
                                                              groups: []))
  }
  
  func presentDownloadProgress(response: Search.ProgressResponse) {
    let vm = Search.ProgressResponse.ViewModel(progress: response.progress)
    viewController?.displayDownloadProgress(viewModel: vm)
  }
}