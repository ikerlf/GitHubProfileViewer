import Foundation
import Testing
@testable import Shared

@Suite("GitHubRepository")
struct GitHubRepositoryTests {
    @Test
    func fetchProfileReturnsCachedValueWhenAvailable() async throws {
        let profile = GitHubProfile(user: .init(username: "octocat", displayName: "Octocat", avatarURL: nil), repositories: [])
        let service = MockGitHubService(result: .success(profile))
        let dateProvider = MutableDateProvider()
        let cache = InMemoryCache<String, GitHubProfile>(configuration: CacheConfiguration(ttl: 300, dateProvider: { dateProvider.currentDate }))
        let repository = GitHubRepository(service: service, cache: cache)

        let first = try await repository.fetchProfile(for: "OctoCat")
        let second = try await repository.fetchProfile(for: "  octocat  ")

        #expect(first == profile)
        #expect(second == profile)
        #expect(service.fetchCallCount == 1)
    }

    @Test
    func fetchProfileRefreshesValueAfterExpiration() async throws {
        let profile = GitHubProfile(user: .init(username: "octocat", displayName: "Octocat", avatarURL: nil), repositories: [])
        let service = MockGitHubService(result: .success(profile))
        let dateProvider = MutableDateProvider()
        let cache = InMemoryCache<String, GitHubProfile>(configuration: CacheConfiguration(ttl: 1, dateProvider: { dateProvider.currentDate }))
        let repository = GitHubRepository(service: service, cache: cache)

        _ = try await repository.fetchProfile(for: "octocat")
        dateProvider.advance(by: 2)
        _ = try await repository.fetchProfile(for: "octocat")

        #expect(service.fetchCallCount == 2)
    }

    @Test
    func fetchProfileForceRefreshBypassesCache() async throws {
        let profile = GitHubProfile(user: .init(username: "octocat", displayName: "Octocat", avatarURL: nil), repositories: [])
        let service = MockGitHubService(result: .success(profile))
        let dateProvider = MutableDateProvider()
        let cache = InMemoryCache<String, GitHubProfile>(configuration: CacheConfiguration(ttl: 300, dateProvider: { dateProvider.currentDate }))
        let repository = GitHubRepository(service: service, cache: cache)

        _ = try await repository.fetchProfile(for: "octocat")
        _ = try await repository.fetchProfile(for: "octocat", forceRefresh: true)

        #expect(service.fetchCallCount == 2)
    }
}

private final class MockGitHubService: GitHubServiceProtocol {
    enum ResultType {
        case success(GitHubProfile)
        case failure(Error)
    }

    private let result: ResultType
    private(set) var fetchCallCount = 0

    init(result: ResultType) {
        self.result = result
    }

    func fetchProfile(for username: String) async throws -> GitHubProfile {
        fetchCallCount += 1
        switch result {
        case let .success(profile):
            return profile
        case let .failure(error):
            throw error
        }
    }
}

private final class MutableDateProvider: @unchecked Sendable {
    var currentDate: Date

    init(currentDate: Date = Date()) {
        self.currentDate = currentDate
    }

    func advance(by interval: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(interval)
    }
}
