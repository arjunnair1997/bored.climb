import SwiftUI

// TODO: This is fine but i want to try an alternate theme. The colors start off as dull
// per "group" of grades and as the grades progress they become brighter. So Light green
// should come after Teal-green. I don't care that it transitions correctly between groups
// of grades.
func colorForGrade(_ grade: Grade) -> Color {
    switch grade {
    case .proj:
        return Color.gray.opacity(0.2) // Projects with a distinct neutral color
    case .V_0:
        return Color(red: 0.4, green: 0.8, blue: 0.4).opacity(0.5) // Light green
    case .V_1:
        return Color(red: 0.2, green: 0.7, blue: 0.2).opacity(0.5) // Medium green
    case .V_2:
        return Color(red: 0.0, green: 0.6, blue: 0.4).opacity(0.5) // Teal-green
    case .V_3:
        return Color(red: 0.0, green: 0.5, blue: 0.5).opacity(0.5) // Teal
    case .V_4:
        return Color(red: 0.0, green: 0.4, blue: 0.7).opacity(0.5) // Blue-teal
    case .V_5:
        return Color(red: 0.0, green: 0.2, blue: 0.8).opacity(0.5) // Medium blue
    case .V_6:
        return Color(red: 0.2, green: 0.0, blue: 0.8).opacity(0.5) // Indigo
    case .V_7:
        return Color(red: 0.4, green: 0.0, blue: 0.8).opacity(0.5) // Purple
    case .V_8:
        return Color(red: 0.6, green: 0.0, blue: 0.8).opacity(0.5) // Deep purple
    case .V_9:
        return Color(red: 0.8, green: 0.0, blue: 0.8).opacity(0.5) // Magenta
    case .V_10:
        return Color(red: 0.8, green: 0.0, blue: 0.6).opacity(0.5) // Pink-purple
    case .V_11:
        return Color(red: 0.8, green: 0.0, blue: 0.4).opacity(0.5) // Dark pink
    case .V_12:
        return Color(red: 0.8, green: 0.0, blue: 0.2).opacity(0.5) // Pink-red
    case .V_13:
        return Color(red: 0.9, green: 0.0, blue: 0.0).opacity(0.5) // Bright red
    case .V_14:
        return Color(red: 1.0, green: 0.2, blue: 0.0).opacity(0.5) // Red-orange
    case .V_15:
        return Color(red: 1.0, green: 0.4, blue: 0.0).opacity(0.5) // Orange
    case .V_16:
        return Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.5) // Amber
    case .V_17:
        return Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.5) // Gold
    }
}

struct ClimbsView: View {
    @EnvironmentObject var nav: NavigationStateManager
    var wall: Wall
    
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
                }
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
