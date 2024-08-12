//
//  RadioModels.swift
//  4champ Amiga Music Player
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

enum RadioChannel: Equatable {
  static func == (lhs: RadioChannel, rhs: RadioChannel) -> Bool {
    switch (lhs, rhs) {
    case (.all, .all):
      return true
    case (.new, .new):
      return true
    case (.local, .local):
      return true
    case (.selection, .selection):
      return true
    default:
      return false
    }
  }

  case all
  case new
  case local
  case selection
}

enum RadioStatus {
  case off
  case fetching(progress: Float)
  case failure
  case noModulesAvailable
  case noSelectionAvailable
  case on
}

enum Radio {
  struct CustomSelection {
    let name: String
    let ids: [Int]
  }
  // MARK: Use cases

  enum Control {
    enum State {
      case on
      case off
      case append
    }

    struct Request {
      var state: Radio.Control.State
      var channel: RadioChannel
      var selection: CustomSelection?
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
