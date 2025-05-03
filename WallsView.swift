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
    
    func removeLast() {
        selectionPath.removeLast()
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


// TODO: prevent rotation of the screen.
struct WallsView: View {
    @Environment(\.modelContext) var context

    @Query var walls: [Wall] = []

    @StateObject var nav = NavigationStateManager()

    @State private var selectedWallImage: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var navigateToEditBoardView: Bool = false

    var body: some View {
        NavigationStack(path: $nav.selectionPath) {
            List {
                ForEach(walls) { wall in
                    // TODO: Remove all the dumb padding for each item in the wall.
                    HStack {
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
                            Text("Grade: TBD")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                }
            }
            .listStyle(PlainListStyle())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Walls")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        PhotosPicker(selection: $selectedWallImage, matching: .images, photoLibrary: .shared()) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .padding(.trailing, 0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 8)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedWallImage) { oldItem, newItem in
                Task {
                    if let dd = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = dd
                        let image = UIImage(named: "vert_test_wall")!
                        let g = image.pngData()!
                        let wall = getWallFromData(data: g)
                        context.insert(wall)
                        nav.selectionPath.append(NavToEditWallView(wall: wall, viewID: "edit_wall_view"))
                    }
                }
            }
            .navigationDestination(for: NavToEditWallView.self) { navWall in
                EditWallView(wall: navWall.wall)
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
