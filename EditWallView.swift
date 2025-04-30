import SwiftUI
import SwiftData
import Foundation
import CoreGraphics

// Function to check if a point is inside a polygon using Core Graphics
func isPointInPolygon(point: CGPoint, points: [CGPoint]) -> Bool {
    guard points.count > 2 else { return false }
    
    let path = CGMutablePath()
    
    if let firstPoint = points.first {
        path.move(to: firstPoint)
        
        // Add lines to all other points
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        // Close the path
        path.closeSubpath()
    }
    // Use Core Graphics to check if the point is inside the path
    return path.contains(point)
}

struct EditWallView: View {
    var wall: Wall
    @State private var showAddHoldsView = false
    @Environment(\.dismiss) private var dismiss
    
    // Add state for tracking overlapping holds
    @State private var overlappingHoldPolygons: [[CGPoint]] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                        ZStack(alignment: .topLeading) {
                            if let uiImage = UIImage(data: wall.imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .scaleEffect(1)
                                    .overlay(
                                        ZStack {
                                            // Render the polygons that overlap with the tapped point
                                            if !overlappingHoldPolygons.isEmpty {
                                                PolygonView(
                                                    polygons: overlappingHoldPolygons,
                                                    containerSize: geo.size,
                                                    imageSize: uiImage.size,
                                                    scale: 1,
                                                    offset: .zero,
                                                    drawCircle: false
                                                )
                                            }

                                            // Invisible overlay for tap detection
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .onTapGesture { containerLoc in
                                                    // Convert tap location to image coordinates
                                                    let relativeTapPoint = convertToImageCoordinates(
                                                        containerPoint: containerLoc,
                                                        containerSize: geo.size,
                                                        imageSize: uiImage.size,
                                                        scale: 1,
                                                        offset: .zero
                                                    )
                                                    
                                                    // Find all holds that contain the tapped point
                                                    let tappedHolds = wall.holds.filter { hold in
                                                        isPointInPolygon(point: relativeTapPoint, points: hold.points)
                                                    }
                                                    
                                                    // Update the list of polygons to display
                                                    overlappingHoldPolygons = tappedHolds.map { $0.points }
                                                    
                                                    print("Tapped coordinates: \(relativeTapPoint)")
                                                    print("Overlapping holds found: \(tappedHolds.count)")
                                                }
                                        }
                                    )
                            } else {
                                fatalError("unable to load image")
                            }
                        }
                        .background(Color.black.ignoresSafeArea())
                }
                .background(Color.black.opacity(0.1))

                // List of holds
                List {
                    ForEach(wall.holds.indices, id: \.self) { index in
                        HStack {
                            Text("Hold \(index + 1)")
                            // This is needed so that the entire list item registers
                            // the tap. Otherwise, the tap is only registered for the
                            // text.
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            overlappingHoldPolygons = [wall.holds[index].points]
                        }
                    }
                    // TODO: Show a modal confirming the deletion.
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
        overlappingHoldPolygons = []

        // Remove the holds at the specified indices
        offsets.forEach { index in
            if index < wall.holds.count {
                wall.holds.remove(at: index)
            }
        }
    }
}

#Preview {
    // Step 1: Create an in-memory SwiftData container
    do {
        let container = try ModelContainer(
            for: Wall.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: false)
        )
        //    let image = UIImage(named: "test_wall")!
        let image = UIImage(named: "test_wall")!
        let data = image.pngData()!
        let wall = getWallFromData(data: data)
        let context = container.mainContext
        context.insert(wall)
        return EditWallView(wall: wall).modelContainer(container)
    } catch {
        fatalError("Failed to create model container: \(error)")
    }
}
