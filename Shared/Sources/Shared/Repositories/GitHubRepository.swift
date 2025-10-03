import Foundation

public protocol GitHubRepositoryProtocol {
    func fetchProfile(for username: String, forceRefresh: Bool) async throws -> GitHubProfile
    func clearCache() async
}

public extension GitHubRepositoryProtocol {
    func fetchProfile(for username: String) async throws -> GitHubProfile {
        try await fetchProfile(for: username, forceRefresh: false)
    }
}

public final class GitHubRepository: GitHubRepositoryProtocol {
    private let service: GitHubServiceProtocol
    private let cache: InMemoryCache<String, GitHubProfile>

    public init(service: GitHubServiceProtocol, cache: InMemoryCache<String, GitHubProfile> = InMemoryCache(configuration: .fiveMinutes)) {
        self.service = service
        self.cache = cache
    }

    public func fetchProfile(for username: String, forceRefresh: Bool = false) async throws -> GitHubProfile {
        let sanitized = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = sanitized.lowercased()

        guard forceRefresh == false, let cached = await cache.value(forKey: cacheKey) else {
            let profile = try await service.fetchProfile(for: sanitized)
            await cache.insert(profile, forKey: cacheKey)
            return profile
        }

        return cached
    }

    public func clearCache() async {
        await cache.removeAll()
    }
}
