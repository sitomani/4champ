//
//  SettingsPresenter.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SettingsPresentationLogic {
  func presentSettings(response: Settings.Update.ValueBag)
}

class SettingsPresenter: SettingsPresentationLogic {
  weak var viewController: SettingsDisplayLogic?

  func presentSettings(response: Settings.Update.ValueBag) {
    viewController?.displaySettings(viewModel: response)
  }
}
