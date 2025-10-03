import Foundation
import Testing
@testable import Shared

@MainActor
@Suite("GitHubProfileViewModel")
struct GitHubProfileViewModelTests {
    @Test
    func initialStateIsIdle() {
        let viewModel = GitHubProfileViewModel(repository: MockRepository(result: .failure(MockError())))
        #expect(viewModel.state == .idle)
        #expect(viewModel.isSearchDisabled)
    }

    @Test
    func searchWithEmptyUsernameDoesNotInvokeRepository() async {
        let repository = MockRepository(result: .failure(MockError()))
        let viewModel = GitHubProfileViewModel(repository: repository)

        await viewModel.search()

        #expect(viewModel.state == .idle)
        #expect(repository.fetchCallCount == 0)
    }

    @Test
    func successfulSearchTransitionsToLoaded() async {
        let profile = GitHubProfile(user: .init(username: "octocat", displayName: "The Octocat", avatarURL: nil), repositories: [])
        let repository = MockRepository(result: .success(profile))
        let viewModel = GitHubProfileViewModel(repository: repository)
        viewModel.username = "octocat"

        await viewModel.search()

        #expect(viewModel.state == .loaded(profile))
        #expect(viewModel.currentProfile == profile)
        #expect(viewModel.isDetailVisible)
        #expect(viewModel.alertContent == nil)
        #expect(repository.fetchCallCount == 1)
    }

    @Test
    func searchFailureTransitionsToError() async throws {
        let repository = MockRepository(result: .failure(GitHubServiceError.userNotFound))
        let viewModel = GitHubProfileViewModel(repository: repository)
        viewModel.username = "unknown"

        await viewModel.search()

        let alert = try #require({ () -> AlertContent? in
            if case let .error(alert) = viewModel.state { return alert }
            return nil
        }())
        #expect(alert.title == "User not found")
        #expect(!viewModel.isDetailVisible)
    }

    @Test
    func clearErrorResetsToIdle() async {
        let repository = MockRepository(result: .failure(GitHubServiceError.networkFailure))
        let viewModel = GitHubProfileViewModel(repository: repository)
        viewModel.username = "octocat"

        await viewModel.search()
        viewModel.clearError()

        #expect(viewModel.state == .idle)
        #expect(viewModel.alertContent == nil)
    }

    @Test
    func dismissDetailReturnsToIdle() async {
        let profile = GitHubProfile(user: .init(username: "octocat", displayName: "The Octocat", avatarURL: nil), repositories: [])
        let repository = MockRepository(result: .success(profile))
        let viewModel = GitHubProfileViewModel(repository: repository)
        viewModel.username = "octocat"

        await viewModel.search()
        viewModel.dismissDetail()

        #expect(viewModel.state == .idle)
    }

    @Test
    func stateIsLoadingWhileFetching() async {
        let profile = GitHubProfile(user: .init(username: "octocat", displayName: "The Octocat", avatarURL: nil), repositories: [])
        let repository = DeferredRepository()
        let viewModel = GitHubProfileViewModel(repository: repository)
        viewModel.username = "octocat"

        let searchTask = Task { await viewModel.search() }
        await repository.waitForRequest()

        #expect(viewModel.isLoading)
        repository.complete(with: .success(profile))
        await searchTask.value
        #expect(viewModel.state == .loaded(profile))
    }
}

private struct MockError: Error {}

private final class MockRepository: GitHubRepositoryProtocol {
    private(set) var fetchCallCount = 0
    private let result: Result<GitHubProfile, Error>

    init(result: Result<GitHubProfile, Error>) {
        self.result = result
    }

    func fetchProfile(for username: String, forceRefresh: Bool) async throws -> GitHubProfile {
        fetchCallCount += 1
        switch result {
        case let .success(profile):
            return profile
        case let .failure(error):
            throw error
        }
    }

    func clearCache() async {}
}

private final class DeferredRepository: GitHubRepositoryProtocol {
    private var continuation: CheckedContinuation<GitHubProfile, Error>?

    func fetchProfile(for username: String, forceRefresh: Bool) async throws -> GitHubProfile {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func waitForRequest() async {
        while continuation == nil {
            await Task.yield()
        }
    }

    func complete(with result: Result<GitHubProfile, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        switch result {
        case let .success(profile):
            continuation.resume(returning: profile)
        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }

    func clearCache() async {}
}
