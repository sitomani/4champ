//
//  RESTRoutes.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import Alamofire

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

enum RESTRoutes: URLRequestConvertible {
  //Router paths
  case latestId
  case modulePath(id: Int)
  case search(type: SearchType, text: String, position: Int)
  
  // Route builder
  var route: (path: String, parameters: [String: Any]?) {
    switch self {
    case .latestId:
      return ("/get_latest", nil)
    case .modulePath(let id):
      return("/get_module?id=\(id)", nil)
    case .search(let type, let text, let position):
      return("/search_\(type.rawValue)?", ["t": text, "s":position, "e": position + pageSize])
    }
  }
  
  //URLRequestConvertible protocol implementation
  func asURLRequest() throws -> URLRequest {
    guard let url = URL.init(string: self.route.path, relativeTo: URL.init(string: "https://4champ.net")) else {
      throw NSError.init()
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = HTTPMethod.get.rawValue
    
    let urlRequest = try Alamofire.URLEncoding.default.encode(request, with: route.parameters)
    return urlRequest
  }
}
