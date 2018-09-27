//
//  SearchPresenter.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SearchPresentationLogic
{
  func presentModules(response: Search.ModuleResponse)
  func presentGroups(response: Search.GroupResponse)
  func presentComposers(response: Search.ComposerResponse)
}

class SearchPresenter: SearchPresentationLogic
{
  weak var viewController: SearchDisplayLogic?
  
  func presentGroups(response: Search.GroupResponse) {
  }
  
  func presentComposers(response: Search.ComposerResponse) {
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
    
    viewController?.displayModules(viewModel: Search.ViewModel(modules: mods, composers: [], groups: []))
  }
}
