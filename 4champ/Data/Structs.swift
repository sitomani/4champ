//
//  Structs.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import UIKit

/// Enumeration identifying the source of a module
enum ModuleService: Int {
  case local = 0
  case amp = 1
}

struct Constants {
  static let radioBufferLen = 3 // Length of the radio buffer
  static let searchDelay = 0.3  // Type wait delay before search is triggered
  static let stereoSeparationDefault: Int = 40 // Default stereo separation value for playback (0-100)
  static let latestDummy: Int = 152506 // Initial newest module id in case update fails
  static let maxBadgeValue = 999 // maximum badge value for new mods
}

struct Notifications {
  static let badgeUpdate = Notification.Name("badge_update")
}

struct MMD: Identifiable {
  init() {
  }
  
  static let supportedTypes: [String] = Replay.supportedFormats
    
  init(cdi: ModuleInfo) {
    self.init()
    self.composer = cdi.modAuthor
    if let urlString = cdi.modURL {
      self.downloadPath = URL.init(string: urlString)
    }
    self.id = cdi.modId?.intValue ?? 0
    if let path = cdi.modLocalPath {
      self.localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(path)
    } else {
      log.error("Module \(cdi.modName ?? "noname") file not available")
    }
    self.name = cdi.modName
    self.size = cdi.modSize?.intValue
    self.type = cdi.modType
    self.serviceId = ModuleService.init(rawValue: cdi.serviceId?.intValue ?? 1) ?? .amp
    self.serviceKey = cdi.serviceKey
    self.favorite = cdi.modFavorite?.boolValue ?? false
  }
  
  init(path: String, modId: Int) {
    self.init()
    downloadPath = URL.init(string: path)

    id = modId
    let components = path.components(separatedBy: "/")
    if components.count > 1 {
      composer = components[components.count - 2].removingPercentEncoding
      if let modNameParts = components.last?.components(separatedBy: ".") {
        type = modNameParts.first ?? "MOD"
        name = modNameParts[1...modNameParts.count - 2].joined(separator: ".")
        name = name?.replacingOccurrences(of: "%", with: "%25") // replace percent signs with encoding
        name = name?.removingPercentEncoding // before removing the encoding
        localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(name!).appendingPathExtension(type!)
      }
    }
  }
  
  var id: Int?
  var name: String?
  var type: String?
  var composer: String?
  var size: Int?
  var localPath: URL?
  var downloadPath: URL?
  var favorite: Bool = false
  var note: String?
  var serviceId: ModuleService? // local | amp | nn?
  var serviceKey: String? // identifier of the module in non-amp service
  func fileExists() -> Bool {
    if let path = localPath?.path {
      return FileManager.default.fileExists(atPath: path)
    }
    return false
  }
  
  func hasBeenSaved() -> Bool {
    guard let modId = self.id else {
      return false
    }
    let saved = moduleStorage.getModuleById(modId)
    return saved != nil
  }
  
  func queueIndex() -> Int? {
    if let queueIndex = modulePlayer.playQueue.firstIndex(of: self) {
      return queueIndex
    }
    return nil
  }
  
  func supported() -> Bool {
    if MMD.supportedTypes.contains(self.type ?? "") && (self.note?.count ?? 0) == 0 {
      return true
    }
    return false
  }
}

extension MMD: Equatable {}
func ==(lhs: MMD, rhs: MMD) -> Bool {
  let eq = lhs.id == rhs.id && lhs.id != nil
  return eq
}
