import SwiftUI
import SwiftData
import Foundation

struct EditWallView: View {
    var wall: Wall
    @State private var showAddHoldsView = false
    @Environment(\.dismiss) private var dismiss
    
    // Add state variables for better image handling
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationStack {
            VStack {
                // Improved wall image display
                GeometryReader { geo in
                    ZStack {
                        if let uiImage = UIImage(data: wall.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .padding(.vertical)
                        } else {
                            Text("Unable to load image")
                                .foregroundColor(.red)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(height: UIScreen.main.bounds.height * 0.4)
                
                // List of holds
                List {
                    ForEach(wall.holds.indices, id: \.self) { index in
                        HStack {
                            Text("Hold \(index + 1)")
                            Spacer()
                            Text("\(wall.holds[index].points.count) points")
                                .foregroundColor(.gray)
                        }
                    }
                    .onDelete(perform: deleteHold)
                }
                .listStyle(.plain)
                
                Spacer()
            }
            .toolbar {
                // Back button at the top left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Title in the center
                ToolbarItem(placement: .principal) {
                    Text("Manage Your Wall")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Add Hold button at the top right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddHoldsView = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
//                            Text("Add Hold")
//                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showAddHoldsView) {
                AddHoldsView(wall: wall)
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func deleteHold(at offsets: IndexSet) {
        // Remove the holds at the specified indices
        offsets.forEach { index in
            if index < wall.holds.count {
                wall.holds.remove(at: index)
            }
        }
    }
}

#Preview {
    let image = UIImage(named: "test_wall")!
    let data = image.pngData()!
    let wall = getWallFromData(data: data)
    return EditWallView(wall: wall)
}
