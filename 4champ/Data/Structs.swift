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
  static let amigaResamplerDefault: Bool = false // Emulate Amiga resampler for Amiga modules
  static let latestDummy: Int = 152506 // Initial newest module id in case update fails
  static let maxBadgeValue = 999 // maximum badge value for new mods
}

struct Notifications {
  static let badgeUpdate = Notification.Name("badge_update")
}

struct MMD: Identifiable, NameComparable, IdComparable {

  init() {
    name = ""
    loop = 0
  }

  static let supportedTypes: [String] = Replay.supportedFormats

  var id: Int?
  var name: String
  var type: String?
  var composer: String?
  var size: Int?
  var localPath: URL?
  var downloadPath: URL?
  var favorite: Bool = false
  var note: String?
  var serviceId: ModuleService? // local | amp | nn?
  var serviceKey: String? // identifier of the module in non-amp service
  var loop: Int // if >0, the song is looped
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
func == (lhs: MMD, rhs: MMD) -> Bool {
  let eq = lhs.id == rhs.id && lhs.id != nil
  return eq
}

protocol MMDInstantiable {
  /// Instantiate from CoreData `ModuleInfo` object
  init(cdi: ModuleInfo)
  /// Instantiate from 4champ.net search response `ModuleResult`
  init(searchResult: ModuleResult)
  /// Instantiate from remote URL and moduleID
  init(path: String, modId: Int)
  /// Instantiate from local file name  (path will be determined after instantiation)
  init?(localFilename: String)
}

extension MMD: MMDInstantiable {
  init(cdi: ModuleInfo) {
    self.init()
    composer = cdi.modAuthor
    if let urlString = cdi.modURL {
      downloadPath = URL.init(string: urlString)
    }
    id = cdi.modId?.intValue ?? 0
    if let path = cdi.modLocalPath {
      localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(path)
    } else {
      log.error("Module \(cdi.modName ?? "") file not available")
    }
    name = cdi.modName ?? ""
    size = cdi.modSize?.intValue
    type = cdi.modType
    serviceId = ModuleService.init(rawValue: cdi.serviceId?.intValue ?? 1) ?? .amp
    serviceKey = cdi.serviceKey
    favorite = cdi.modFavorite?.boolValue ?? false
    loop = cdi.loop?.intValue ?? 0
  }
  
  init(searchResult: ModuleResult) {
    self.init()
    id = searchResult.id
    downloadPath = URL.init(string: searchResult.nameBlock.href)
    name = searchResult.nameBlock.label
    size = Int(searchResult.size.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    type = searchResult.format
    composer = searchResult.composer.label
    serviceId = .amp
    note = searchResult.note
    if let localCopy = moduleStorage.getModuleById(id ?? 0) {
      localPath = localCopy.localPath
    }
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
        name = name.replacingOccurrences(of: "%", with: "%25") // replace percent signs with encoding
        name = name.removingPercentEncoding ?? "" // before removing the encoding
        localPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent(name).appendingPathExtension(type!)
      }
    }
  }
  
  init?(localFilename: String) {
    guard let suffix = localFilename.split(separator: ".").last else {
      return nil
    }

    let filetype = String(suffix).uppercased()
    guard MMD.supportedTypes.contains(filetype) else {
      return nil
    }
    
    downloadPath = nil
    name = localFilename
    type = filetype
    composer = ""
    serviceId = .local
    serviceKey = localFilename
    loop = 0
  }
}
