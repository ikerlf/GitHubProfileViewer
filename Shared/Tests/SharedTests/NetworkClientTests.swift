import Foundation
import Testing
@testable import Shared

@Suite("NetworkClient", .serialized)
struct NetworkClientTests {
    @Test
    func sendPerformsGETRequestAndReturnsResponse() async throws {
        MockURLProtocol.reset()
        let expectedData = Data("response".utf8)
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == HTTPMethod.get.rawValue)
            #expect(request.httpBody == nil)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, expectedData)
        }

        let client = makeClient()
        let request = NetworkRequest(url: URL(string: "https://example.com/resource")!)

        defer { MockURLProtocol.reset() }

        let response = try await client.send(request)

        #expect(response.data == expectedData)
        #expect(response.response.statusCode == 200)
    }

    @Test
    func sendPropagatesTransportErrors() async {
        MockURLProtocol.reset()
        MockURLProtocol.error = URLError(.notConnectedToInternet)
        let client = makeClient()
        let request = NetworkRequest(url: URL(string: "https://example.com/resource")!)

        defer { MockURLProtocol.reset() }

        do {
            _ = try await client.send(request)
            Issue.record("Expected transport error")
        } catch let error as NetworkError {
            switch error {
            case .transportError(let underlying):
                #expect(underlying is URLError)
            default:
                Issue.record("Expected transportError, received: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Helpers

    private func makeClient() -> NetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return NetworkClient(session: session)
    }
}

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var error: Error?

    static func reset() {
        requestHandler = nil
        error = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = MockURLProtocol.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
