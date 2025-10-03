import Foundation
import Testing
@testable import Shared

@Suite("GitHubMapper")
struct GitHubMapperTests {
    @Test
    func repositoryMappingCopiesAllFields() {
        let ownerDTO = RepositoryDTO.OwnerDTO(login: "octocat", avatarURL: URL(string: "https://example.com/avatar.png"))
        let dto = RepositoryDTO(
            id: 42,
            name: "SomeRepo",
            description: "Description",
            language: "Swift",
            htmlURL: URL(string: "https://github.com/octocat/SomeRepo")!,
            owner: ownerDTO
        )

        let repository = GitHubMapper.mapRepository(dto)

        #expect(repository.id == dto.id)
        #expect(repository.name == dto.name)
        #expect(repository.description == dto.description)
        #expect(repository.language == dto.language)
        #expect(repository.htmlURL == dto.htmlURL)
        #expect(repository.owner.login == ownerDTO.login)
        #expect(repository.owner.avatarURL == ownerDTO.avatarURL)
    }

    @Test
    func repositoryArrayMappingMapsEachElement() {
        let owner = RepositoryDTO.OwnerDTO(login: "octocat", avatarURL: nil)
        let dtos = [
            RepositoryDTO(id: 1, name: "A", description: nil, language: nil, htmlURL: URL(string: "https://github.com/octocat/A")!, owner: owner),
            RepositoryDTO(id: 2, name: "B", description: "Desc", language: "Swift", htmlURL: URL(string: "https://github.com/octocat/B")!, owner: owner)
        ]

        let repositories = GitHubMapper.mapRepositories(dtos)

        #expect(repositories.count == dtos.count)
        zip(repositories, dtos).forEach { repo, dto in
            #expect(repo.id == dto.id)
            #expect(repo.name == dto.name)
        }
    }

    @Test
    func userMappingUsesNameWhenAvailable() {
        let dto = GitHubUserDTO(login: "octocat", name: "The Octocat", avatarURL: nil)

        let user = GitHubMapper.mapUser(dto)

        #expect(user.username == dto.login)
        #expect(user.displayName == "The Octocat")
        #expect(user.avatarURL == nil)
    }

    @Test
    func userMappingFallsBackToLoginWhenNameMissing() {
        let dto = GitHubUserDTO(login: "octocat", name: "", avatarURL: nil)

        let user = GitHubMapper.mapUser(dto)

        #expect(user.displayName == dto.login)
    }
}
