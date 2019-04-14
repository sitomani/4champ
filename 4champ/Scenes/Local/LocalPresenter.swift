//
//  LocalPresenter.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol LocalPresentationLogic
{
  func presentSomething(response: Local.Something.Response)
}

class LocalPresenter: LocalPresentationLogic
{
  weak var viewController: LocalDisplayLogic?
  
  // MARK: Do something
  
  func presentSomething(response: Local.Something.Response)
  {
    let viewModel = Local.Something.ViewModel()
    viewController?.displaySomething(viewModel: viewModel)
  }
}
