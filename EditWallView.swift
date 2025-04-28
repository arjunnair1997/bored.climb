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
    
    // TODO: Allow zoom in this view.
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                        ZStack(alignment: .topLeading) {
                            if let uiImage = UIImage(data: wall.imageData) {
                                // Calculate proper sizing based on aspect ratio
                                // let imageAspect = uiImage.size.width / uiImage.size.height
                                // let containerAspect = geo.size.width / geo.size.height
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .scaleEffect(1)
                                    .overlay(
                                        Color.clear
                                            .contentShape(Rectangle())
                                            .onTapGesture { containerLoc in
                                                // The image fits somewhere within the container depending on its aspect ratio.
                                                let relativeTapPoint = convertToImageCoordinates(
                                                    containerPoint: containerLoc,
                                                    containerSize: geo.size,
                                                    imageSize: uiImage.size,
                                                    scale: 1,
                                                    offset: .zero
                                                )
                                                
                                                // Figure out how to draw the points here.
                                                // Should be easy. Since I have the relative tap point,
                                                // i can determine if a hold overlaps with the tap. And if
                                                // i know that a hold overlaps with the tap, then i can make
                                                // the hold visible.
                                                //
                                                // TODO: Need to maintain a per hold state of visible or invisible.
                                                // Should not be stored in the hold, but stored in the view.
                                                print("containerLoc", containerLoc)
                                                print("relativeLoc", relativeTapPoint)
                                            }
                                    )
                            } else {
                                Text("Unable to load image")
                                    .foregroundColor(.red)
                            }
                        }
                        .background(Color.black.ignoresSafeArea())
                }
                .background(Color.black.opacity(0.1))
//                .frame(height: UIScreen.main.bounds.height * 0.5) // Adjust as needed
                
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
//    let image = UIImage(named: "test_wall")!
    let image = UIImage(named: "vert_test_wall")!
    let data = image.pngData()!
    let wall = getWallFromData(data: data)
    return EditWallView(wall: wall)
}
