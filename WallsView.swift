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
    return Wall(imageData: data, width: width, height: height)
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wall.id)
    }
    
    static func == (lhs: NavToEditWallView, rhs: NavToEditWallView) -> Bool {
        return lhs.wall.id == rhs.wall.id
    }
    
    init(wall: Wall) {
        self.wall = wall
    }
}

class NavToAddHoldView: Hashable {
    var wall: Wall
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(wall.id)
    }
    
    static func == (lhs: NavToAddHoldView, rhs: NavToAddHoldView) -> Bool {
        return lhs.wall.id == rhs.wall.id
    }

    init(wall: Wall) {
        self.wall = wall
    }
}


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
                    HStack(spacing: 12) {
                        if let uiImage = UIImage(data: wall.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wall Name")
                                .font(.headline)
                            Text("Grade: TBD")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
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
                    .padding(.leading, 8) // optional: reduce system margin
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
                        let image = UIImage(named: "test_wall")!
                        let g = image.pngData()!
                        let wall = getWallFromData(data: g)
                        context.insert(wall)
                        nav.selectionPath.append(NavToEditWallView(wall: wall))
                    }
                }
            }
            // TODO: Check that this can be done using isPresented so that you don't
            // have to worry about hashing.
            //
            // Someone wrote a how to on navigation which is actually good and not terrible
             // like the rest
        /*
        
         https://medium.com/@muhammadathief0/solving-common-ios-navigationstack-challenges-practical-solutions-based-on-my-experience-185c81a20940
         
         */
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
//    .environmentObject(NavigationStateManager())
}
