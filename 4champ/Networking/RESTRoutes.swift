//
//  RESTRoutes.swift
//  4champ Amiga Music Player
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import Alamofire

/// Page size for search requests. Because of the nature of amp.dascene.net
/// server implementation, this variable cannot actually be modified without
/// breaking the paging in search.
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

/**
 Enumeration for the available endpoints at 4champ backend
 */
enum RESTRoutes: URLRequestConvertible {
  //Router paths
  case latestId
  case modulePath(id: Int)
  case search(type: SearchType, text: String, position: Int)
  case listComposers(groupId: Int)
  case listModules(composerId: Int)
  
  /// network route tuple variable
  var route: (path: String, parameters: [String: Any]?) {
    switch self {
    case .latestId:
      return ("/get_latest", nil)
    case .modulePath(let id):
      return("/get_module?id=\(id)", nil)
    case .search(let type, let text, let position):
      return("/search_\(type.rawValue)?", ["t": text, "s":position, "e": position + pageSize-1])
    case .listComposers(let groupId):
      return("list_composers", ["t": groupId])
    case .listModules(let composerId):
      return("list_modules", ["t": composerId])
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
