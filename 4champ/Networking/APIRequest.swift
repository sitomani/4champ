protocol APIRequest {
  associatedtype Response: Decodable
  var endpoint: Endpoint { get }
  var parameters: [String: String]? { get }
}

extension APIRequest {
  var url: URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "4champ.net"
    components.path = endpoint.path
    
    if let parameters = parameters {
      components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    
    return components.url
  }
}

struct APILatestIdRequest: APIRequest {
  typealias Response = LatestModule
  var endpoint: Endpoint = .getLatest
  var parameters: [String: String]?
}

struct APISearchRequest: APIRequest {
  typealias Response = Data
  var endpoint: Endpoint
  var parameters: [String: String]? // Implement parameters
  
  init(type: SearchType, sought: String, position: Int) {
    endpoint = .search(type: type)
    parameters = [
      "q": sought
    ]
  }
}

struct APIListComposersRequest: APIRequest {
  typealias Response = ListComposersResponse
  var endpoint: Endpoint
  var parameters: [String: String]?
  
  init(groupId: Int) {
    endpoint = .listComposers(id: groupId)
  }
}

struct SharePage: APIRequest {
  typealias Response = Data
  var endpoint: Endpoint
  var parameters: [String: String]?
  init(moduleId: Int) {
    endpoint = .sharePage
    parameters = [
      "id": "\(moduleId)"
    ]
  }
}

struct APIListModulesRequest: APIRequest {
  typealias Response = ListModulesResponse
  var endpoint: Endpoint
  var parameters: [String: String]?
  
  init(composerId: Int) {
    endpoint = .listModules(id: composerId)
  }
}

struct APIModulePathRequest: APIRequest {
  
  typealias Response = ModulePathResponse
  var endpoint: Endpoint
  var parameters: [String: String]?
  
  init(moduleId: Int) {
    endpoint = .modulePath(id: moduleId)
  }
}

struct APIRandomModuleRequest: APIRequest {
  typealias Response = ModuleDetailsResponse
  var endpoint: Endpoint = .randomModule
  var parameters: [String: String]?
}

struct APIModuleDetailsRequest: APIRequest {
  typealias Response = ModuleDetailsResponse
  var endpoint: Endpoint
  var parameters: [String: String]?
  init(moduleId: Int) {
    endpoint = .moduleDetails(id: moduleId)
  }
}
