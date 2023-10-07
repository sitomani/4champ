//
//  LocalPresenter.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol LocalPresentationLogic {
  func presentModules(response: Local.SortFilter.Response)
  func presentPlayerError(_ error: PlayerError)
  func presentDeletion(_ indexPath: IndexPath)
  func presentUpdate(_ indexPath: IndexPath)
  func presentInsert(_ indexPath: IndexPath)
//  func presentImport(response: Local.Import.Response)
}

class LocalPresenter: LocalPresentationLogic {
  weak var viewController: LocalDisplayLogic?
  
  func presentModules(response: Local.SortFilter.Response) {
    let viewModel = Local.SortFilter.ViewModel()
    viewController?.displayModules(viewModel: viewModel)
  }
  
  func presentPlayerError(_ error: PlayerError) {
    DispatchQueue.main.async {
      self.viewController?.displayPlayerError(message: "Search_DownloadFailed".l13n())
    }
  }
  
  func presentDeletion(_ indexPath: IndexPath) {
    self.viewController?.displayRowDeletion(indexPath: indexPath)
  }
  
  func presentUpdate(_ indexPath: IndexPath) {
    viewController?.displayRowUpdate(indexPath: indexPath)
  }
  
  func presentInsert(_ indexPath: IndexPath) {
    viewController?.displayRowInsert(indexPath: indexPath)
  }
}
