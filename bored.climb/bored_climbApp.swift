import SwiftUI
import SwiftData

@main
struct bored_climbApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.light)
        }
    }
}
