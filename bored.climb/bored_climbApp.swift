import SwiftUI
import SwiftData

@main
struct bored_climbApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Wall.self,
            Hold.self,
            Climb.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WallsView()
        }
        .modelContainer(sharedModelContainer)
    }
}
