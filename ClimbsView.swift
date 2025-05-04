import SwiftUI

// TODO: restrict length of climb.name.
struct ClimbsView: View {
    @EnvironmentObject var nav: NavigationStateManager
    var wall: Wall
    
    var body: some View {
        List {
            ForEach(wall.climbs) { climb in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(climb.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(formatGrade(climb.grade))
                            .font(.subheadline)
                            .padding(6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Text(climb.desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    nav.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Climbs")
                    .font(.title)
                    .fontWeight(.bold)
            }
                
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    nav.selectionPath.append(NavToAddClimbView(wall: wall, viewID: "add_climb_view"))
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .padding(.trailing, 0)
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
