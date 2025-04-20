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

@Model
class Hold {
    var points: [CGPoint] = []

    init(points: [CGPoint]) {
        self.points = points
    }
}

@Model
class Wall {
    var imageData: Data
    // TODO: Check if this needs a query param.
    var holds: [Hold] = []

    init(imageData: Data) {
        self.imageData = imageData
    }
}

struct BoardsView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var navigateToImageView = false

    @Query var walls: [Wall] = []
    @Environment(\.modelContext) var context

    var body: some View {
        NavigationStack {
            List {
                ForEach(walls) { wall in
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
                            Text("Boards")
                                .font(.title)
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            Spacer()
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .padding(.trailing, 0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.leading, 8) // optional: reduce system margin
                }
            }
            .onChange(of: selectedItem) { oldItem, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        navigateToImageView = true
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToImageView) {
                EditBoardView(imageData: selectedImageData)
            }
        }
    }
}

#Preview {
    BoardsView()
    .modelContainer(try! ModelContainer(for: Wall.self, configurations:
        ModelConfiguration(isStoredInMemoryOnly: true)
    ))
}
