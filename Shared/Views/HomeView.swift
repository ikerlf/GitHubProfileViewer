import SwiftUI
import Observation
import Shared

@MainActor
struct HomeView: View {
    @State private var viewModel: GitHubProfileViewModel = GitHubProfileViewModel()

    var body: some View {
        @Bindable var bindings = viewModel

        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 12)

                VStack(spacing: 8) {
                    Text("GitHub Profile Finder")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    Text("Search for a GitHub username to view the profile name, avatar, and repositories.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                usernameField

                Button {
                    Task { await bindings.search() }
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                #if os(tvOS)
                .buttonStyle(.bordered)
#else
                .buttonStyle(.borderedProminent) 
#endif
                .disabled(bindings.isSearchDisabled)

                if bindings.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: 480)
            .navigationDestination(isPresented: Binding(
                get: { bindings.isDetailVisible },
                set: { isPresented in
                    if !isPresented {
                        bindings.dismissDetail()
                    }
                }
            )) {
                if let profile = bindings.currentProfile {
                    ProfileDetailView(profile: profile) {
                        bindings.dismissDetail()
                    }
                }
            }
        }
        .alert(item: Binding(
            get: { bindings.alertContent },
            set: { _ in bindings.clearError() }
        )) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var usernameField: some View {
        Group {
            #if os(macOS)
            TextField("Enter GitHub username", text: $bindings.username)
                .textFieldStyle(.roundedBorder)
                .onSubmit { Task { await bindings.search() } }
            #elseif os(tvOS)
            TextField("Enter GitHub username", text: $bindings.username)
                .textFieldStyle(.automatic)
                .onSubmit { Task { await bindings.search() } }
            #else
            TextField("Enter GitHub username", text: $bindings.username)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit { Task { await bindings.search() } }
            #endif
        }
        .padding(.horizontal)
    }
}

#Preview("HomeView") {
    HomeView()
}
