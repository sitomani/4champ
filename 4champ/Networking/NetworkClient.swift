//
//  NetworkClient.swift
//  4champ
//
//  Copyright © 2025 Aleksi Sitomaniemi. All rights reserved.
//

enum NetworkError: Error {
    case invalidURL
    case decodingError
    case serverError(statusCode: Int)
    case unknown(Error)
}

/*
 Minimal networking client for sending `APIRequest`
 */
final class NetworkClient {
    func send<T: APIRequest>(_ request: T) async throws -> T.Response {
        guard let url = request.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.endpoint.method.rawValue

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw NetworkError.unknown(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "Invalid response", code: 0))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }

        if T.Response.self == String.self {
            guard let stringResponse = String(data: data, encoding: .utf8) else {
                throw NetworkError.decodingError
            }
            // swiftlint:disable:next force_cast
            return stringResponse as! T.Response
        }

        if T.Response.self == Data.self {
            // swiftlint:disable:next force_cast
            return data as! T.Response
        }

        do {
            return try JSONDecoder().decode(T.Response.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    static func cancelAllDataTasks() {
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
}
