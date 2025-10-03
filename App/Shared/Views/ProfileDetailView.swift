import SwiftUI
import Shared

struct ProfileDetailView: View {
    let profile: GitHubProfile
    let onBack: () -> Void

    var body: some View {
        List {
            Section {
                ProfileHeader(user: profile.user)
            }

            Section("Repositories") {
                if profile.repositories.isEmpty {
                    Text("This user has no public repositories yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(profile.repositories) { repository in
                        RepositoryRowView(repository: repository)
                    }
                }
            }

            Section {
                Button(action: onBack) {
                    Label("Search Another User", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                #if os(tvOS)
                .buttonStyle(.bordered)
#else
                .buttonStyle(.borderedProminent)
#endif
            }
        }
        .navigationTitle(displayTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(macOS)
        .listStyle(.inset)
        #elseif os(tvOS)
        .listStyle(.grouped)
        #else
        .listStyle(.insetGrouped)
        #endif
    }

    private var displayTitle: String {
        if profile.user.displayName.isEmpty {
            return profile.user.username
        }
        return profile.user.displayName
    }
}

private struct ProfileHeader: View {
    let user: GitHubProfile.User

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: user.avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                case .empty:
                    ProgressView()
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))

            VStack(spacing: 4) {
                if !user.displayName.isEmpty {
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Text("@\(user.username)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle.badge.questionmark")
            .resizable()
            .scaledToFit()
            .foregroundColor(.secondary)
    }
}

#Preview("Profile Detail") {
    ProfileDetailView(
        profile: GitHubProfile(
            user: .init(username: "octocat", displayName: "The Octocat", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/583231?v=4")),
            repositories: [
                Repository(
                    id: 1,
                    name: "Hello-World",
                    description: "Sample repository",
                    language: "Swift",
                    htmlURL: URL(string: "https://github.com/octocat/Hello-World")!,
                    owner: .init(login: "octocat", avatarURL: URL(string: "https://avatars.githubusercontent.com/u/583231?v=4"))
                )
            ]
        ),
        onBack: {}
    )
}
