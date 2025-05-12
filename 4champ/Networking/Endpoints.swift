//
//  Endpoints.swift
//  4champ
//
//  Copyright © 2025 Aleksi Sitomaniemi. All rights reserved.
//
import Foundation

let pageSize = 50

/**
 Search type enumeration identifies the target context for search
 */
enum SearchType: String {
  case module
  case group
  case composer
  case meta

  /**
   Returns the localized name for the search type (shown on search view)
  */
  func l13n() -> String {
    switch self {
    case .module: return "G_Module".l13n()
    case .group: return "G_Group".l13n()
    case .composer: return "SearchView_Composer".l13n()
    case .meta: return "G_Texts".l13n()
    }
  }
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

enum Endpoint {
    case getLatest
    case search(type: SearchType)
    case listComposers
    case listModules
    case modulePath

    var path: String {
        switch self {
        case .getLatest:
            return "/get_latest"
        case .search(let type):
            return "/search_\(type.rawValue)"
        case .listModules:
            return "/list_modules"
        case .listComposers:
            return "/list_composers"
        case .modulePath:
            return "/get_module"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getLatest, .search:
            return .GET
        case .listModules, .listComposers, .modulePath:
            return .GET
        }
    }
}
