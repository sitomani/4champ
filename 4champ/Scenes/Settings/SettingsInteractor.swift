//
//  SettingsInteractor.swift
//  4champ
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

/**
 Search sort type identifies the sorting property. Default is name ascending
 Composer modules list sort can use id descending sort
 */
enum SortType: Int {
  case nameAscending
  case nameDescending
  case idAscending
  case idDescending
}

enum MainTabs: Int {
  case local
  case playlists
  case search
  case radio
  case about
}

protocol SettingsBusinessLogic {
  func updateSettings(request: Settings.Update.ValueBag?)
}

protocol SettingsDataStore {
  var stereoSeparation: Int { get set }
  var interpolation: SampleInterpolation { get set }
  var composerModuleListSort: SortType { get set }
}

class SettingsInteractor: SettingsBusinessLogic, SettingsDataStore {

  private enum SettingKeys {
    static let domainName = "DomainName"
    static let stereoSeparation = "StereoSeparation"
    static let collectionSize = "collectionSize"
    static let newestPlayed = "newestPlayed"
    static let prevCollectionSize = "prevCollectionSize"
    static let interpolation = "interpolation"
    static let amigaResampler = "amigaResampler"
    static let moduleSortKey = "moduleSortKey"
    static let radioCustomSelection = "radioCustomSelection"
    static let lastActiveTab = "lastActiveTab"
    static let lastActivePlaylist = "lastActivePlaylist"
    static let lastSearch = "lastSearch"
    static let lastRadioChannel = "lastRadioChannel"
    static let lastSortFilter = "lastSortFilter"
    static let sessionHistory = "sessionHistory"
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
  
  var amigaResampler: Bool {
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.amigaResampler) as? Bool {
        return value
      }
      return Constants.amigaResamplerDefault
    }
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.amigaResampler)
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
  
  var composerModuleListSort: SortType {
    get {
      if let value = UserDefaults.standard.value(forKey: SettingKeys.moduleSortKey) as? Int {
        return SortType(rawValue: value) ?? .nameAscending
      }
      return .nameAscending
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: SettingKeys.moduleSortKey)
    }
  }
  
  var radioCustomSelection: Radio.CustomSelection {
    get {
      if let data = UserDefaults.standard.string(forKey: SettingKeys.radioCustomSelection),
         let value = try? JSONDecoder().decode(Radio.CustomSelection.self, from: data.data(using: .utf8)!) {
        return value
      }
      return Radio.CustomSelection(name: "Radio_Custom".l13n(), ids: [])
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "", forKey: SettingKeys.radioCustomSelection)
      }
    }
  }
  
  var sessionHistory: [MMD] {
    get {
      if let data = UserDefaults.standard.string(forKey: SettingKeys.sessionHistory),
         let value = try? JSONDecoder().decode([MMD].self, from: data.data(using: .utf8)!) {
        return value
      }
      return []
    }
    set {
      if let data = try? JSONEncoder().encode(Array(newValue.prefix(20))) {
        UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "", forKey: SettingKeys.sessionHistory)
      }
    }
  }
  
  var lastActiveTab: MainTabs {
    get {
      if let lastActive = UserDefaults.standard.value(forKey: SettingKeys.lastActiveTab) as? Int {
        return MainTabs(rawValue: lastActive) ?? .radio
      }
      return MainTabs.radio
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: SettingKeys.lastActiveTab)
    }
  }
  
  var lastActivePlaylist: String {
    get {
      if let lastActive = UserDefaults.standard.value(forKey: SettingKeys.lastActivePlaylist) as? String {
        return lastActive
      }
      return "default"
    }
    set {
      UserDefaults.standard.set(newValue, forKey: SettingKeys.lastActivePlaylist)
    }
  }
  
  var lastSearchRequest: Search.Request {
    get {
      if let data = UserDefaults.standard.string(forKey: SettingKeys.lastSearch),
         let value = try? JSONDecoder().decode(Search.Request.self, from: data.data(using: .utf8)!) {
        return value
      }
      return Search.Request(text: "", type: .composer)
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "", forKey: SettingKeys.lastSearch)
      }
    }
  }
  
  var lastSortFilter: Local.SortFilter.Request {
    get {
      if let data = UserDefaults.standard.string(forKey: SettingKeys.lastSortFilter),
         let value = try? JSONDecoder().decode(Local.SortFilter.Request.self, from: data.data(using: .utf8)!) {
        return value
      }
      return Local.SortFilter.Request(sortKey: .module, filterText: nil, ascending: true)
    }
    set {
      if let data = try? JSONEncoder().encode(newValue) {
        UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "", forKey: SettingKeys.lastSortFilter)
      }
    }
  }
  
  var lastRadioChannel: RadioChannel {
    get {
      if let channel = UserDefaults.standard.value(forKey: SettingKeys.lastRadioChannel) as? Int {
        return RadioChannel(rawValue: channel) ?? .all
      }
      return .all
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: SettingKeys.lastRadioChannel)
    }
  }
  
  

  // MARK: Do something

  func updateSettings(request: Settings.Update.ValueBag?) {
    var response: Settings.Update.ValueBag
    if let request = request {
      response = request
      stereoSeparation = request.stereoSeparation
      interpolation = request.interpolation
      amigaResampler = request.amigaResampler
    } else {
      response = Settings.Update.ValueBag(stereoSeparation: stereoSeparation, interpolation: interpolation, amigaResampler: amigaResampler)
    }
    modulePlayer.setStereoSeparation(stereoSeparation)
    modulePlayer.setInterpolation(interpolation)
    modulePlayer.setAmigaResampler(amigaResampler)
    presenter?.presentSettings(response: response)
  }

  private func updateBadge() {
    DispatchQueue.main.async {
      UNUserNotificationCenter.current().setBadgeCount(self.badgeCount)
    }
  }
}
