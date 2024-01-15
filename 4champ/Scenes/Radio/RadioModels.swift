//
//  RadioModels.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

enum RadioChannel: Int {
  case all
  case new
  case local
}

enum RadioStatus {
  case off
  case fetching(progress: Float)
  case failure
  case noModulesAvailable
  case on
}

enum Radio {
  // MARK: Use cases
  enum Control {
    struct Request {
      var powerOn: Bool
      var channel: RadioChannel
    }

    struct Response {
      var status: RadioStatus
    }

    struct ViewModel {
      var status: RadioStatus
    }
  }

  enum Playback {
    struct Response {
      var length: Int
      var elapsed: Int
    }

    struct ViewModel {
      var timeLeft: String?
      var name: String?
    }
  }

  enum ChannelBuffer {
    struct Response {
      var buffer: [MMD]
    }

    struct ViewModel {
      var nowPlaying: MMD?
      var nextUp: String?
      var historyAvailable: Bool
    }
  }

  enum LocalNotifications {
    struct Request {}
    struct Response {
      var notificationsEnabled: Bool
      var notificationsRequested: Bool
    }
    struct ViewModel {
      var imageName: String
    }
  }

  enum NewModules {
    struct Response {
      let badgeValue: Int
    }
    struct ViewModel {
      let badgeText: String?
    }
  }
}
