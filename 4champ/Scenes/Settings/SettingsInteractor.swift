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
  var domain: String { get set }
  var stereoSeparation: Float { get set }
}

class SettingsInteractor: SettingsBusinessLogic, SettingsDataStore
{
  private enum SettingKeys {
    static let domainName = "DomainName"
    static let stereoSeparation = "StereoSeparation"
  }

  
  var presenter: SettingsPresentationLogic?
  
  var domain: String {
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.domainName)
    }
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.domainName) as? String {
        return value
      }
      return ""
    }
  }
  var stereoSeparation: Float {
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.stereoSeparation)
    }
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.stereoSeparation) as? Float {
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
      domain = request.domainName
      stereoSeparation = request.stereoSeparation
    } else {
      response = Settings.Update.ValueBag(domainName: domain, stereoSeparation: stereoSeparation)
    }
    modulePlayer.setStereoSeparation(stereoSeparation)
    presenter?.presentSettings(response: response)
  }
}
