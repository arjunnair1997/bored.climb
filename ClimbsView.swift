import SwiftUI

struct ClimbsView: View {
    @EnvironmentObject var nav: NavigationStateManager
    var wall: Wall
    
    var body: some View {
        List {
            // This would contain the list of climbs for the selected wall
            // For now it's empty as per your requirements
        }
        .listStyle(PlainListStyle())
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("Climbs")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        nav.selectionPath.append(NavToAddClimbView(wall: wall, viewID: "add_climb_view"))
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .padding(.trailing, 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 8)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    nav.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavToAddClimbView.self) { navWall in
            AddClimbView(wall: navWall.wall)
        }
    }
}
