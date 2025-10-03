import Foundation

public struct GitHubProfile: Equatable {
    public struct User: Equatable {
        public let username: String
        public let displayName: String
        public let avatarURL: URL?

        public init(username: String, displayName: String, avatarURL: URL?) {
            self.username = username
            self.displayName = displayName
            self.avatarURL = avatarURL
        }
    }

    public let user: User
    public let repositories: [Repository]

    public init(user: User, repositories: [Repository]) {
        self.user = user
        self.repositories = repositories
    }
}

public struct Repository: Identifiable, Equatable {
    public struct Owner: Equatable {
        public let login: String
        public let avatarURL: URL?

        public init(login: String, avatarURL: URL?) {
            self.login = login
            self.avatarURL = avatarURL
        }
    }

    public let id: Int
    public let name: String
    public let description: String?
    public let language: String?
    public let htmlURL: URL
    public let owner: Owner

    public init(id: Int, name: String, description: String?, language: String?, htmlURL: URL, owner: Owner) {
        self.id = id
        self.name = name
        self.description = description
        self.language = language
        self.htmlURL = htmlURL
        self.owner = owner
    }
}
