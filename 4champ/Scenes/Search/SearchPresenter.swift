//
//  SearchPresenter.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SearchPresentationLogic
{
  func presentSomething(response: Search.ModuleQuery.Response)
}

class SearchPresenter: SearchPresentationLogic
{
  weak var viewController: SearchDisplayLogic?
  
  // MARK: Do something
  
  func presentSomething(response: Search.ModuleQuery.Response)
  {
//    let viewModel = Search.Something.ViewModel()
//    viewController?.displaySomething(viewModel: viewModel)
  }
}
