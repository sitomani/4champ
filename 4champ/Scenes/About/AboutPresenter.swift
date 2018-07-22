//
//  AboutPresenter.swift
//  4champ
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol AboutPresentationLogic
{
  func presentStatus(_ status: About.Status.Response)
}

class AboutPresenter: AboutPresentationLogic
{
  weak var viewController: AboutDisplayLogic?
  
  // MARK: Do something
  
  func presentStatus(_ status: About.Status.Response) {
    let vm = About.Status.ViewModel(isPlaying: status.isPlaying)
    viewController?.displayNowPlaying(vm)
  }
}
