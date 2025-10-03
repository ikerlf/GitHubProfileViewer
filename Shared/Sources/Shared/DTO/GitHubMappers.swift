import Foundation

enum GitHubMapper {
    static func mapRepositories(_ dtos: [RepositoryDTO]) -> [Repository] {
        dtos.map { mapRepository($0) }
    }

    static func mapRepository(_ dto: RepositoryDTO) -> Repository {
        Repository(
            id: dto.id,
            name: dto.name,
            description: dto.description,
            language: dto.language,
            htmlURL: dto.htmlURL,
            owner: mapOwner(dto.owner)
        )
    }

    static func mapOwner(_ dto: RepositoryDTO.OwnerDTO) -> Repository.Owner {
        Repository.Owner(login: dto.login, avatarURL: dto.avatarURL)
    }

    static func mapUser(_ dto: GitHubUserDTO) -> GitHubProfile.User {
        GitHubProfile.User(
            username: dto.login,
            displayName: (dto.name?.isEmpty == false ? dto.name! : dto.login),
            avatarURL: dto.avatarURL
        )
    }
}
