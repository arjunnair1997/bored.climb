import SwiftUI
import SwiftData
import PhotosUI

@Model
class Wall {
    var imageData: Data

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
                            Text("Climb Name")
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
            .navigationTitle("Boards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
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
                UploadBoardView(imageData: selectedImageData)
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
