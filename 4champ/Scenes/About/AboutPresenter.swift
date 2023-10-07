//
//  AboutPresenter.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol AboutPresentationLogic {
  func presentStatus(_ status: About.Status.Response)
}

class AboutPresenter: AboutPresentationLogic {
  weak var viewController: AboutDisplayLogic?

  // MARK: Do something

  func presentStatus(_ status: About.Status.Response) {
    let vm = About.Status.ViewModel(isPlaying: status.isPlaying)
    viewController?.displayNowPlaying(vm)
  }
}
