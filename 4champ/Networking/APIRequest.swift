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
    typealias Response = String
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
            "t": sought,
            "s": "\(position)",
            "e": "\(position + pageSize)"
        ]
    }
}

struct APIListComposersRequest: APIRequest {
    typealias Response = [ComposerResult]
    var endpoint: Endpoint = .listComposers
    var parameters: [String: String]?

    init(groupId: Int) {
        parameters = ["t": String(groupId)]
    }
}

struct APIListModulesRequest: APIRequest {
    typealias Response = [ModuleResult]
    var endpoint: Endpoint = .listModules
    var parameters: [String: String]?

    init(composerId: Int) {
        parameters = ["t": String(composerId)]
    }
}

struct APIModulePathRequest: APIRequest {
    typealias Response = String
    var endpoint: Endpoint
    var parameters: [String: String]?

    init(moduleId: Int) {
        endpoint = .modulePath
        parameters = ["id": String(moduleId)]
    }
}
