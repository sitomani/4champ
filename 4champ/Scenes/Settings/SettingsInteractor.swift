//
//  SettingsInteractor.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

protocol SettingsBusinessLogic {
  func updateSettings(request: Settings.Update.ValueBag?)
}

protocol SettingsDataStore {
  var stereoSeparation: Int { get set }
  var interpolation: SampleInterpolation { get set }
}

class SettingsInteractor: SettingsBusinessLogic, SettingsDataStore {

  private enum SettingKeys {
    static let domainName = "DomainName"
    static let stereoSeparation = "StereoSeparation"
    static let collectionSize = "collectionSize"
    static let newestPlayed = "newestPlayed"
    static let prevCollectionSize = "prevCollectionSize"
    static let interpolation = "interpolation"
  }

  var presenter: SettingsPresentationLogic?

  var stereoSeparation: Int {
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.stereoSeparation) as? Int {
        return value
      }
      return Constants.stereoSeparationDefault
    }
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.stereoSeparation)
    }
  }

  var interpolation: SampleInterpolation {
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.interpolation) as? Int {
        return SampleInterpolation(rawValue: value) ?? .libraryDefault
      }
      return SampleInterpolation.libraryDefault
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: SettingKeys.interpolation)
    }
  }

  var collectionSize: Int {
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.collectionSize) as? Int {
        return value
      }
      return Constants.latestDummy
    }
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.collectionSize)
      updateBadge()
      NotificationCenter.default.post(Notification.init(name: Notifications.badgeUpdate))
    }
  }

  var newestPlayed: Int {
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.newestPlayed) as? Int {
        return value
      }
      return 0
    }
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.newestPlayed)
      updateBadge()
      NotificationCenter.default.post(Notification.init(name: Notifications.badgeUpdate))
    }
  }

  var prevCollectionSize: Int {
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.prevCollectionSize) as? Int {
        return value
      }
      return 0
    }
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.prevCollectionSize)
    }
  }

  var badgeCount: Int {
    if newestPlayed < collectionSize {
      var diff = collectionSize - newestPlayed
      diff = diff > Constants.maxBadgeValue ? Constants.maxBadgeValue : diff
      return diff
    }
    return 0
  }

  // MARK: Do something

  func updateSettings(request: Settings.Update.ValueBag?) {
    var response: Settings.Update.ValueBag
    if let request = request {
      response = request
      stereoSeparation = request.stereoSeparation
      interpolation = request.interpolation
    } else {
      response = Settings.Update.ValueBag(stereoSeparation: stereoSeparation, interpolation: interpolation)
    }
    modulePlayer.setStereoSeparation(stereoSeparation)
    modulePlayer.setInterpolation(interpolation)
    presenter?.presentSettings(response: response)
  }

  private func updateBadge() {
    UIApplication.shared.applicationIconBadgeNumber = badgeCount
  }
}
