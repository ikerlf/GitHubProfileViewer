import SwiftUI
import Shared

struct RepositoryRowView: View {
    let repository: Repository

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(repository.name)
                .font(.headline)

            if let language = repository.language, !language.isEmpty {
                Text(language)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Language unavailable")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Repository Row") {
    RepositoryRowView(
        repository: Repository(
            id: 1,
            name: "SampleRepo",
            description: nil,
            language: "Swift",
            htmlURL: URL(string: "https://github.com/example/SampleRepo")!,
            owner: .init(login: "example", avatarURL: nil)
        )
    )
}
