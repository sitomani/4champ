//
//  AboutModels.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

enum About {
  struct Details {
    var titles: [String]
    var contents: [String]
    var images: [String]
    var licenseLinks: [String]
    var licenseNames: [String]
  }
  // MARK: Use cases
  
  enum Status {
    struct Request {
    }
    struct Response {
      var isPlaying: Bool = false
    }
    struct ViewModel {
      var isPlaying: Bool = false
    }
  }
}
