//
//  RESTRoutes.swift
//  ampplayer
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import Alamofire

enum RESTRoutes: URLRequestConvertible {
  //Router paths
  case latestId
  case modulePath(id: Int)
  
  // Route builder
  var route: (path: String, parameters: [String: Any]?) {
    switch self {
    case .latestId:
      return ("/get_latest", nil)
    case .modulePath(let id):
      return("/get_module?id=\(id)", nil)
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
