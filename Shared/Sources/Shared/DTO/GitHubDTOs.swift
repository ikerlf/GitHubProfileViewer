import Foundation

struct RepositoryDTO: Decodable {
    struct OwnerDTO: Decodable {
        let login: String
        let avatarURL: URL?

        private enum CodingKeys: String, CodingKey {
            case login
            case avatarURL = "avatar_url"
        }
    }

    let id: Int
    let name: String
    let description: String?
    let language: String?
    let htmlURL: URL
    let owner: OwnerDTO

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case language
        case htmlURL = "html_url"
        case owner
    }
}

struct GitHubUserDTO: Decodable {
    let login: String
    let name: String?
    let avatarURL: URL?

    private enum CodingKeys: String, CodingKey {
        case login
        case name
        case avatarURL = "avatar_url"
    }
}
