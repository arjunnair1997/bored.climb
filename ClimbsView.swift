import SwiftUI

func colorForGrade(_ grade: Grade) -> Color {
    switch grade {
    case .proj:
        // Metallic silver - with enhanced shine built in
        return Color(red: 0.9, green: 0.9, blue: 0.95)
    case .V_0:
        // Pearlescent light green
        return Color(red: 0.7, green: 0.95, blue: 0.7)
    case .V_1:
        // Glossy pastel green
        return Color(red: 0.6, green: 0.9, blue: 0.6)
    case .V_2:
        // Iridescent seafoam
        return Color(red: 0.5, green: 0.85, blue: 0.75)
    case .V_3:
        // Shimmering teal
        return Color(red: 0.4, green: 0.8, blue: 0.8)
    case .V_4:
        // Luminous sky blue
        return Color(red: 0.4, green: 0.75, blue: 0.9)
    case .V_5:
        // Radiant azure
        return Color(red: 0.5, green: 0.7, blue: 0.95)
    case .V_6:
        // Gleaming indigo
        return Color(red: 0.6, green: 0.65, blue: 0.95)
    case .V_7:
        // Lustrous lavender
        return Color(red: 0.7, green: 0.6, blue: 0.95)
    case .V_8:
        // Glowing violet
        return Color(red: 0.8, green: 0.6, blue: 0.95)
    case .V_9:
        // Vivid magenta
        return Color(red: 0.9, green: 0.6, blue: 0.9)
    case .V_10:
        // Brilliant rose pink with enhanced shine
        return Color(red: 1.0, green: 0.65, blue: 0.85)
    case .V_11:
        // Sparkling coral with enhanced shine
        return Color(red: 1.0, green: 0.6, blue: 0.75)
    case .V_12:
        // Polished salmon with enhanced shine
        return Color(red: 1.0, green: 0.55, blue: 0.65)
    case .V_13:
        // Resplendent cherry with enhanced shine
        return Color(red: 1.0, green: 0.55, blue: 0.55)
    case .V_14:
        // Lustrous peach with enhanced shine
        return Color(red: 1.0, green: 0.65, blue: 0.45)
    case .V_15:
        // Vibrant orange with enhanced shine
        return Color(red: 1.0, green: 0.75, blue: 0.45)
    case .V_16:
        // Dazzling amber with enhanced shine
        return Color(red: 1.0, green: 0.85, blue: 0.45)
    case .V_17:
        // Brilliant gold with enhanced shine
        return Color(red: 1.0, green: 0.95, blue: 0.6)
    }
}

struct ClimbsView: View {
    @EnvironmentObject var nav: NavigationStateManager
    var wall: Wall
    
    @State private var isShowingAlert = false
    @State private var climbToDelete: Climb?
    
    var body: some View {
        List {
            ForEach(wall.climbs) { climb in
                ZStack {
                    NavigationLink(value: NavToClimbView(climb: climb, viewID: "climb_view")) {
                        EmptyView()
                    }
                        .opacity(0)
                        .buttonStyle(PlainButtonStyle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(climb.name)
                                .font(.headline)
                                .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                                .lineLimit(1)

                            Spacer()
                            
                            Text(climb.grade.displayString())
                                .font(.subheadline)
                                .padding(6)
                                .background(colorForGrade(climb.grade))
                                .cornerRadius(8)
                        }

                        Text(climb.desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button(role: .destructive, action: {
                            climbToDelete = climb
                            isShowingAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .alert("Delete Entry", isPresented: $isShowingAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let climb = climbToDelete, let _ = climb.id {
                    wall.deleteClimb(climb: climb)
                    climbToDelete = nil
                } else {
                    fatalError("either no climb or climb id")
                }
            }
        } message: {
            Text("Are you sure you want to delete this entry?")
        }
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
        .toolbarBackground(toolbarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavToAddClimbView.self) { navWall in
            AddClimbView(wall: navWall.wall)
        }
        .navigationDestination(for: NavToClimbView.self) { navWall in
            ClimbView(climb: navWall.climb)
        }
    }
}
