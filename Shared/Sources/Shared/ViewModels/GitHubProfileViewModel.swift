import Foundation
import Observation

@Observable
@MainActor
public final class GitHubProfileViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded(GitHubProfile)
        case error(AlertContent)
    }

    public var username: String = ""
    public private(set) var state: State = .idle

    private let repository: GitHubRepositoryProtocol

    public init(repository: GitHubRepositoryProtocol = GitHubRepository(service: GitHubService())) {
        self.repository = repository
    }

    public var isSearchDisabled: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || isLoading
    }

    public var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    public var currentProfile: GitHubProfile? {
        if case let .loaded(profile) = state { return profile }
        return nil
    }

    public var alertContent: AlertContent? {
        if case let .error(alert) = state { return alert }
        return nil
    }

    public var isDetailVisible: Bool {
        if case .loaded = state { return true }
        return false
    }

    public func search() async {
        guard !isSearchDisabled else { return }
        let currentUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        state = .loading

        await loadProfile(for: currentUsername)
    }

    public func dismissDetail() {
        state = .idle
    }

    public func clearError() {
        if case .error = state {
            state = .idle
        }
    }

    private func loadProfile(for username: String) async {
        do {
            let profile = try await repository.fetchProfile(for: username)
            state = .loaded(profile)
        } catch let error as GitHubServiceError {
            handle(error: error)
        } catch {
            handle(error: .networkFailure)
        }
    }

    private func handle(error: GitHubServiceError) {
        switch error {
        case .userNotFound:
            state = .error(AlertContent(
                title: "User not found",
                message: "User not found. Please enter another name"
            ))
        case .networkFailure, .invalidResponse:
            state = .error(AlertContent(
                title: "Network error",
                message: "A network error has occurred. Check your Internet connection and try again later."
            ))
        }
    }
}

public struct AlertContent: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let message: String

    public init(id: UUID = UUID(), title: String, message: String) {
        self.id = id
        self.title = title
        self.message = message
    }
}
