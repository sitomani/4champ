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
enum SearchType: String, Encodable, Decodable {
  case modules
  case groups
  case composers
  case meta
  
  /**
   Returns the localized name for the search type (shown on search view)
   */
  func l13n() -> String {
    switch self {
    case .modules: return "G_Module".l13n()
    case .groups: return "G_Group".l13n()
    case .composers: return "SearchView_Composer".l13n()
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
  case listComposers(id: Int)
  case listModules(id: Int)
  case modulePath(id: Int)
  case moduleDetails(id: Int)
  case randomModule
  case sharePage
  
  var path: String {
    switch self {
    case .getLatest:
      return "/api/v2/amp/modules/latest"
    case .search(let type):
      return "/api/v2/amp/\(type.rawValue)"
    case .listModules(let id):
      return "/api/v2/amp/composers/\(id)/modules"
    case .listComposers(let id):
      return "/api/v2/amp/groups/\(id)/composers"
    case .modulePath(let id):
      return "/api/v2/amp/modules/\(id)/download"
    case .moduleDetails(let id):
      return "/api/v2/amp/modules/\(id)"
    case .randomModule:
      return "/api/v2/amp/modules/random"
    case .sharePage:
      return "/mod"
    }
  }
  
  var method: HTTPMethod {
    switch self {
    case .getLatest, .search:
      return .GET
    case .listModules, .listComposers, .modulePath, .moduleDetails, .randomModule, .sharePage:
      return .GET
    }
  }
}
