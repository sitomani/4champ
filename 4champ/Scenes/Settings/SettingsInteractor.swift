//
//  SettingsInteractor.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SettingsBusinessLogic
{
  func updateSettings(request: Settings.Update.ValueBag?)
}

protocol SettingsDataStore
{
  var stereoSeparation: Int { get set }
}

class SettingsInteractor: SettingsBusinessLogic, SettingsDataStore
{
  private enum SettingKeys {
    static let domainName = "DomainName"
    static let stereoSeparation = "StereoSeparation"
  }

  
  var presenter: SettingsPresentationLogic?
  
  var stereoSeparation: Int {
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.stereoSeparation)
    }
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.stereoSeparation) as? Int {
        return value
      }
      return Constants.stereoSeparationDefault
    }
  }
  
  // MARK: Do something
  
  func updateSettings(request: Settings.Update.ValueBag?)
  {
    var response: Settings.Update.ValueBag
    if let request = request {
      response = request
      stereoSeparation = request.stereoSeparation
    } else {
      response = Settings.Update.ValueBag(stereoSeparation: stereoSeparation)
    }
    modulePlayer.setStereoSeparation(stereoSeparation)
    presenter?.presentSettings(response: response)
  }
}
