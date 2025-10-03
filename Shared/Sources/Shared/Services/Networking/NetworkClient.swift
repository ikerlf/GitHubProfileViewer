import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}

public struct NetworkRequest {
    public let url: URL
    public var method: HTTPMethod
    public var headers: [String: String]
    public var body: Data?
    public var timeout: TimeInterval

    public init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 15
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}

public struct NetworkResponse {
    public let data: Data
    public let response: HTTPURLResponse
}

public enum NetworkError: Error {
    case invalidResponse
    case transportError(Error)
}

public protocol NetworkClientProtocol {
    func send(_ request: NetworkRequest) async throws -> NetworkResponse
}

public final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: NetworkRequest) async throws -> NetworkResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.timeoutInterval = request.timeout
        urlRequest.httpBody = request.body

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            return NetworkResponse(data: data, response: httpResponse)
        } catch {
            throw NetworkError.transportError(error)
        }
    }
}
