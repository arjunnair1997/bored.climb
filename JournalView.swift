import SwiftUI

struct JournalView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Journal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                Text("Coming soon...")
                    .foregroundColor(.gray)
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Journal")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            .toolbarBackground(toolbarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

