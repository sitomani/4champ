//
//  Structs.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation

struct Constants {
  static let radioBufferLen = 3 // Length of the radio buffer
  static let searchDelay = 0.3  // Type wait delay before search is triggered
  static let stereoSeparationDefault: Float = 0.25 // Default stereo separation value for playback (0.0-1.0)
}

struct MMD {
  init() {
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
        name = modNameParts[1...modNameParts.count - 2].joined()
        name = name?.replacingOccurrences(of: "%", with: "%25") //replace percent signs with encoding
        name = name?.removingPercentEncoding //before removing the encoding
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
}

extension MMD: Equatable {}
func ==(lhs: MMD, rhs: MMD) -> Bool {
  let eq = lhs.id == rhs.id && lhs.id != nil
  return eq
}
