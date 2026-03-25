//
//  CPListTemplate+playlists.swift
//  ampplayer
//
//  Copyright © 2026 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import CarPlay

enum ListTemplateType {
  case playlists // tab list
  case currentPlaylist // selected playlist
  case playQueue // upcoming queue
}

extension CPListTemplate {
  convenience init(type: ListTemplateType) {
    switch type {
    case .playlists:
      self.init(title: "PlaylistView_Playlists".l13n(), sections: [])
    case .currentPlaylist:
      self.init(title: "TabBar_Playlist".l13n(), sections: [])
    case .playQueue:
      self.init(title: "Carplay_Queue".l13n(), sections: [])
    }
    self.userInfo = ["type": "\(type)"]
  }
}
