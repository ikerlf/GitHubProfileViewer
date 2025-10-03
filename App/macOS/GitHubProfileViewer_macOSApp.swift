import SwiftUI

@main
struct GitHubProfileViewer_macOSApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .frame(minWidth: 400, minHeight: 480)
        }
        .windowResizability(.contentSize)
    }
}
