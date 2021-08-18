//
//  PlaylistSelectorModels.swift
//  4champ
//
//  Created by Aleksi Sitomaniemi on 13.3.2020.
//  Copyright © 2020 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

struct PLMD: Identifiable {
    var id: String?
    var name: String?
    var current: Bool
    var modules: [Int]
}

enum DownloadStatus: Equatable {
    static func == (lhs: DownloadStatus, rhs: DownloadStatus) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.complete, .complete):
            return true
        case (.downloading(_), .downloading(_)):
            return true
        case (.failed(_), .failed(_)):
            return true
        default:
            return false
        }
    }
    
    case unknown
    case downloading(progress: Int)
    case complete
    case failed(error: Error)
}

enum PlaylistSelector
{
  enum PrepareSelection
  {
    struct Request
    {
        let module: MMD
    }
    struct Response
    {
        let module: MMD
        let playlistOptions: [PLMD]
    }
    struct ViewModel
    {
        var module: String
        var service: ModuleService?
        var currentPlaylistIndex: Int
        var playlistOptions: [String]
        var status: DownloadStatus
    }
  }
    
    enum Append {
        struct Request {
            let module: MMD
            let playlistIndex: Int
        }
        struct Response {
            var status: DownloadStatus
        }
        struct ViewModel {
            let status: DownloadStatus
        }
    }
    
    enum Delete {
        struct Request {
            let module: MMD
        }
    }
}
