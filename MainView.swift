// First, let's create a simple empty view for the Journal tab
import SwiftUI

// Now, let's create the main tab view that will contain both tabs
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WallsView()
                .tabItem {
                    Label("Climb", systemImage: "figure.play")
                }
                .tag(0)
            
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book")
                }
                .tag(1)
        }
        .accentColor(toolbarColor)
    }
}

// We need to modify the WallsView to work within the tab structure

// Update the preview to show the MainTabView instead of just WallsView
#Preview {
    MainTabView()
        .preferredColorScheme(.light)
}
