import Foundation

public protocol GitHubServiceProtocol {
    func fetchProfile(for username: String) async throws -> GitHubProfile
}

public enum GitHubServiceError: Error, Equatable {
    case userNotFound
    case networkFailure
    case invalidResponse
}

public final class GitHubService: GitHubServiceProtocol {
    private let client: NetworkClientProtocol
    private let decoder: JSONDecoder

    public init(
        client: NetworkClientProtocol = NetworkClient(),
        decoder: JSONDecoder = GitHubService.makeDecoder()
    ) {
        self.client = client
        self.decoder = decoder
    }

    @usableFromInline
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }

    public func fetchProfile(for username: String) async throws -> GitHubProfile {
        let sanitized = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitized.isEmpty else { throw GitHubServiceError.userNotFound }
        let repositories = try await fetchRepositories(for: sanitized)
        let user = await fetchUser(for: sanitized, fallbackOwner: repositories.first?.owner)
        let sortedRepos = repositories.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        return GitHubProfile(user: user, repositories: sortedRepos)
    }
}

private extension GitHubService {
    private var defaultHeaders: [String: String] {
        ["Accept": "application/vnd.github+json"]
    }
    
    private func fetchRepositories(for username: String) async throws -> [Repository] {
        guard let url = URL(string: "https://api.github.com/users/\(username)/repos") else {
            throw GitHubServiceError.invalidResponse
        }

        do {
            let response = try await client.send(NetworkRequest(url: url, method: .get, headers: defaultHeaders))

            switch response.response.statusCode {
            case 200 ... 299:
                break
            case 404:
                throw GitHubServiceError.userNotFound
            default:
                throw GitHubServiceError.networkFailure
            }

            do {
                let dtos = try decoder.decode([RepositoryDTO].self, from: response.data)
                return GitHubMapper.mapRepositories(dtos)
            } catch {
                throw GitHubServiceError.invalidResponse
            }
        } catch {
            throw mapError(error)
        }
    }

    private func fetchUser(for username: String, fallbackOwner: Repository.Owner?) async -> GitHubProfile.User {
        guard let url = URL(string: "https://api.github.com/users/\(username)") else {
            return fallbackProfile(username: username, owner: fallbackOwner)
        }

        do {
            let response = try await client.send(NetworkRequest(url: url, method: .get, headers: defaultHeaders))
            guard (200 ... 299).contains(response.response.statusCode) else {
                return fallbackProfile(username: username, owner: fallbackOwner)
            }

            if let user = try? decoder.decode(GitHubUserDTO.self, from: response.data) {
                return GitHubMapper.mapUser(user)
            }
        } catch {
            return fallbackProfile(username: username, owner: fallbackOwner)
        }

        return fallbackProfile(username: username, owner: fallbackOwner)
    }

    private func fallbackProfile(username: String, owner: Repository.Owner?) -> GitHubProfile.User {
        if let owner {
            return GitHubProfile.User(
                username: owner.login,
                displayName: owner.login,
                avatarURL: owner.avatarURL
            )
        }

        return GitHubProfile.User(
            username: username,
            displayName: username,
            avatarURL: nil
        )
    }

    private func mapError(_ error: Error) -> GitHubServiceError {
        if let serviceError = error as? GitHubServiceError {
            return serviceError
        }

        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidResponse:
                return .invalidResponse
            case .transportError:
                return .networkFailure
            }
        }

        return .networkFailure
    }
}
