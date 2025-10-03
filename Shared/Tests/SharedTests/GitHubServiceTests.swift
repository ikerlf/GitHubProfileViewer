import Foundation
import Testing
@testable import Shared

@Suite("GitHubService")
struct GitHubServiceTests {
    @Test
    func fetchProfileReturnsSortedRepositories() async throws {
        let repositoriesURL = URL(string: "https://api.github.com/users/octocat/repos")!
        let userURL = URL(string: "https://api.github.com/users/octocat")!
        let repositoriesData = Data(
            """
            [
                {
                    "id": 2,
                    "name": "beta",
                    "description": null,
                    "language": "Swift",
                    "html_url": "https://github.com/octocat/Beta",
                    "owner": { "login": "octocat", "avatar_url": "https://example.com/avatar.png" }
                },
                {
                    "id": 1,
                    "name": "Alpha",
                    "description": null,
                    "language": "Swift",
                    "html_url": "https://github.com/octocat/Alpha",
                    "owner": { "login": "octocat", "avatar_url": "https://example.com/avatar.png" }
                }
            ]
            """.utf8
        )
        let userData = Data(
            """
            {
                "login": "octocat",
                "name": "The Octocat",
                "avatar_url": "https://example.com/avatar.png"
            }
            """.utf8
        )

        let client = MockNetworkClient(responses: [
            repositoriesURL: .success(NetworkResponse(data: repositoriesData, response: HTTPURLResponse.makeSuccess(url: repositoriesURL))),
            userURL: .success(NetworkResponse(data: userData, response: HTTPURLResponse.makeSuccess(url: userURL)))
        ])

        let service = GitHubService(client: client)
        let profile = try await service.fetchProfile(for: "octocat")

        #expect(client.recordedRequests.count == 2)
        #expect(profile.repositories.map(\.name) == ["Alpha", "beta"])
        #expect(profile.user.displayName == "The Octocat")
    }

    @Test
    func fetchProfileThrowsUserNotFoundWhenRepositoriesReturn404() async {
        let repositoriesURL = URL(string: "https://api.github.com/users/missing/repos")!
        let client = MockNetworkClient(responses: [
            repositoriesURL: .success(NetworkResponse(data: Data(), response: HTTPURLResponse.make(url: repositoriesURL, statusCode: 404)))
        ])

        let service = GitHubService(client: client)

        do {
            _ = try await service.fetchProfile(for: "missing")
            Issue.record("Expected userNotFound error")
        } catch let error as GitHubServiceError {
            #expect(error == .userNotFound)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func fetchProfileThrowsNetworkFailureWhenTransportFails() async {
        let repositoriesURL = URL(string: "https://api.github.com/users/octocat/repos")!
        let client = MockNetworkClient(responses: [
            repositoriesURL: .failure(NetworkError.transportError(URLError(.timedOut)))
        ])

        let service = GitHubService(client: client)

        do {
            _ = try await service.fetchProfile(for: "octocat")
            Issue.record("Expected networkFailure error")
        } catch let error as GitHubServiceError {
            #expect(error == .networkFailure)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func fetchProfileFallsBackToRepositoryOwnerWhenUserRequestFails() async throws {
        let repositoriesURL = URL(string: "https://api.github.com/users/octocat/repos")!
        let userURL = URL(string: "https://api.github.com/users/octocat")!
        let repositoriesData = Data(
            """
            [
                {
                    "id": 99,
                    "name": "Sample",
                    "description": null,
                    "language": "Swift",
                    "html_url": "https://github.com/octocat/Sample",
                    "owner": { "login": "fallback", "avatar_url": "https://example.com/avatar.png" }
                }
            ]
            """.utf8
        )

        let client = MockNetworkClient(responses: [
            repositoriesURL: .success(NetworkResponse(data: repositoriesData, response: HTTPURLResponse.makeSuccess(url: repositoriesURL))),
            userURL: .failure(NetworkError.transportError(URLError(.notConnectedToInternet)))
        ])

        let service = GitHubService(client: client)
        let profile = try await service.fetchProfile(for: "octocat")

        #expect(profile.user.username == "fallback")
        #expect(profile.user.displayName == "fallback")
    }
}

private final class MockNetworkClient: NetworkClientProtocol {
    enum Response {
        case success(NetworkResponse)
        case failure(Error)
    }

    private var responses: [URL: Response]
    private(set) var recordedRequests: [NetworkRequest] = []

    init(responses: [URL: Response]) {
        self.responses = responses
    }

    func send(_ request: NetworkRequest) async throws -> NetworkResponse {
        recordedRequests.append(request)
        guard let response = responses.removeValue(forKey: request.url) else {
            throw NetworkError.invalidResponse
        }

        switch response {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}

private extension HTTPURLResponse {
    static func makeSuccess(url: URL) -> HTTPURLResponse {
        make(url: url, statusCode: 200)
    }

    static func make(url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
