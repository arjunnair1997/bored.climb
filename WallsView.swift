import SwiftUI
import SwiftData
import PhotosUI

func saveContext(context: ModelContext) {
    do {
        try context.save()
    } catch {
        fatalError("Error saving context: \(error)")
    }
}

func getWallFromData(data: Data) -> Wall {
    let uiImage = UIImage(data: data).unsafelyUnwrapped
    let height = uiImage.size.height
    let width = uiImage.size.width
    return Wall(imageData: data, width: width, height: height, name: "my_test_wall")
}

func createTestWall() -> Wall {
    let image = UIImage(named: "test_wall")!
    let data = image.pngData()!
    return getWallFromData(data: data)
}

@MainActor
class NavigationStateManager: ObservableObject {

    @Published var selectionPath = NavigationPath()
    
    func popToRoot() {
        selectionPath = NavigationPath()
    }
    
    func removeN(n: Int) {
        selectionPath.removeLast(n)
    }

    func removeLast() {
        selectionPath.removeLast()
    }
}

class NavToClimbsView: Hashable {
    var wall: Wall
    var viewID: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wall.id)
        hasher.combine(viewID)
    }
    
    static func == (lhs: NavToClimbsView, rhs: NavToClimbsView) -> Bool {
        return lhs.wall.id == rhs.wall.id && lhs.viewID == rhs.viewID
    }
    
    init(wall: Wall, viewID: String) {
        self.wall = wall
        self.viewID = viewID
    }
}

class NavToEditWallView: Hashable {
    var wall: Wall
    var viewID: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wall.id)
        hasher.combine(viewID)
    }
    
    static func == (lhs: NavToEditWallView, rhs: NavToEditWallView) -> Bool {
        return lhs.wall.id == rhs.wall.id && lhs.viewID == rhs.viewID
    }
    
    init(wall: Wall, viewID: String) {
        self.wall = wall
        self.viewID = viewID
    }
}

class NavToAddHoldView: Hashable {
    var wall: Wall
    var viewID: String
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(wall.id)
            hasher.combine(viewID)
    }
    
    static func == (lhs: NavToAddHoldView, rhs: NavToAddHoldView) -> Bool {
        return lhs.wall.id == rhs.wall.id && lhs.viewID == rhs.viewID
    }

    init(wall: Wall, viewID: String) {
        self.wall = wall
        self.viewID = viewID
    }
}

class NavToAddClimbView: Hashable {
    var wall: Wall
    var viewID: String
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(wall.id)
            hasher.combine(viewID)
    }
    
    static func == (lhs: NavToAddClimbView, rhs: NavToAddClimbView) -> Bool {
        return lhs.wall.id == rhs.wall.id && lhs.viewID == rhs.viewID
    }

    init(wall: Wall, viewID: String) {
        self.wall = wall
        self.viewID = viewID
    }
}

class NavToSelectStartHoldView: Hashable {
    var wall: Wall
    // Invariant: Holds must belong to the wall.
    var selectedHolds: [Hold]
    var viewID: String
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(wall.id)
            hasher.combine(viewID)
    }
    
    static func == (lhs: NavToSelectStartHoldView, rhs: NavToSelectStartHoldView) -> Bool {
        return lhs.wall.id == rhs.wall.id && lhs.viewID == rhs.viewID
    }

    init(wall: Wall, selectedHolds: [Hold], viewID: String) {
        self.wall = wall
        self.viewID = viewID
        self.selectedHolds = selectedHolds
    }
}

class NavToSelectFinishHoldView: Hashable {
    var wall: Wall
    // Invariant: Holds must belong to the wall.
    var selectedHolds: [Hold]
    var holdTypes: [HoldType]
    var viewID: String
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(wall.id)
            hasher.combine(viewID)
    }
    
    static func == (lhs: NavToSelectFinishHoldView, rhs: NavToSelectFinishHoldView) -> Bool {
        return lhs.wall.id == rhs.wall.id && lhs.viewID == rhs.viewID
    }

    init(wall: Wall, selectedHolds: [Hold], holdTypes: [HoldType], viewID: String) {
        self.wall = wall
        self.viewID = viewID
        self.selectedHolds = selectedHolds
        self.holdTypes = holdTypes
    }
}

class NavToFinishClimbView: Hashable {
    var wall: Wall
    // Invariant: Holds must belong to the wall.
    var selectedHolds: [Hold]
    // Invariant: len(holdTypes) == len(selectedHolds).
    //
    // TODO: verify this invariant.
    var holdTypes: [HoldType]
    var viewID: String
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(wall.id)
            hasher.combine(viewID)
    }
    
    static func == (lhs: NavToFinishClimbView, rhs: NavToFinishClimbView) -> Bool {
        return lhs.wall.id == rhs.wall.id && lhs.viewID == rhs.viewID
    }

    init(wall: Wall, selectedHolds: [Hold], holdTypes: [HoldType], viewID: String) {
        self.wall = wall
        self.viewID = viewID
        self.selectedHolds = selectedHolds
        self.holdTypes = holdTypes
    }
}

// TODO: prevent rotation of the screen.
// TODO: Make the naming system better. It's in the way, and i don't think
// there should be edit support for wall names.
// TODO: Force white background and don't respect dark theme.
struct WallsView: View {
    @Environment(\.modelContext) var context
    @Query var walls: [Wall] = []
    @StateObject var nav = NavigationStateManager()
    
    @State private var selectedWallImage: PhotosPickerItem? = nil
    @State private var navigateToEditBoardView: Bool = false
    
    // Add these state variables for the confirmation dialog
    @State private var showingDeleteConfirmation = false
    @State private var wallToDelete: Wall? = nil
    
    var body: some View {
        NavigationStack(path: $nav.selectionPath) {
            List {
                ForEach(walls) { wall in
                    // Full row navigation
                    ZStack{
                        NavigationLink(value: NavToClimbsView(wall: wall, viewID: "climbs_view")) {
                            EmptyView()
                        }
                            .opacity(0)
                            .buttonStyle(PlainButtonStyle())

                        HStack {
                            // Wall image and info
                            if let uiImage = UIImage(data: wall.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(wall.name)
                                    .font(.headline)
                            }
                            
                            Spacer()

                            // TODO: Make this menu more clickable. Too easy to fat finger right now.
                            Menu {
                                Button(action: {
                                    nav.selectionPath.append(NavToEditWallView(wall: wall, viewID: "edit_wall_view"))
                                }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                // Modified delete button to trigger confirmation
                                Button(action: {
                                    wallToDelete = wall
                                    showingDeleteConfirmation = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                        Text("Delete")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            // Add the confirmation dialog
            .confirmationDialog(
                "Are you sure you want to delete this wall?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let wall = wallToDelete {
                        context.delete(wall)
                        try? context.save()
                    }
                    wallToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    wallToDelete = nil
                }
            } message: {
                if let wall = wallToDelete {
                    Text("Are you sure you want to delete \"\(wall.name)\"? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this wall? This action cannot be undone.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Walls")
                        .font(.title)
                        .fontWeight(.bold)
                }
                    
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedWallImage, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedWallImage) { oldItem, newItem in
                Task {
                    if let dd = try? await newItem?.loadTransferable(type: Data.self) {
                        let wall = getWallFromData(data: dd)
                        context.insert(wall)
                        nav.selectionPath.append(NavToEditWallView(wall: wall, viewID: "edit_wall_view"))
                    }
                }
            }
            .navigationDestination(for: NavToEditWallView.self) { navWall in
                EditWallView(wall: navWall.wall)
            }
            .navigationDestination(for: NavToClimbsView.self) { navWall in
                ClimbsView(wall: navWall.wall)
            }
        }
        .environmentObject(nav)
    }
}

#Preview {
    WallsView()
    .modelContainer(try! ModelContainer(for: Wall.self, configurations:
        ModelConfiguration(isStoredInMemoryOnly: true)
    ))
}
