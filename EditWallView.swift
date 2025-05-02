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

// TODO: If you add edit support for a wall, then you need to store multiple versions
// of the same wall to support existing climbs which use the older wall.
struct EditWallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var wall: Wall
    
    // Add state for tracking overlapping holds
    @State private var overlappingHoldPolygons: [[CGPoint]] = []
    @State private var showDeleteConfirmation = false
    @State private var indexToDelete: Int?
    
    @EnvironmentObject var nav: NavigationStateManager
    
    var body: some View {
//        NavigationStack {
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
                    .onDelete { offsets in
                        if let first = offsets.first {
                            indexToDelete = first
                            showDeleteConfirmation = true
                        }
                    }
                }
                .listStyle(.plain)
                .alert("Delete Hold?", isPresented: $showDeleteConfirmation, actions: {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            if let index = indexToDelete {
                                deleteHold(at: IndexSet(integer: index))
                                indexToDelete = nil
                                showDeleteConfirmation = false
                            }
                        }
                    }, message: {
                        Text("Are you sure you want to delete this hold?")
                    })
            }
            .toolbar {
                // Back button at the top left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Save the wall.
                        saveContext(context: context)
//                        dismiss()
                        nav.removeLast()
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
                        nav.selectionPath.append(NavToAddHoldView(wall: wall, viewID: "add_hold_view"))
                    }) {
                        HStack {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationDestination(for: NavToAddHoldView.self) { navView in
                return AddHoldsView(wall: navView.wall)
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

//#Preview {
//    // Step 1: Create an in-memory SwiftData container
//    do {
//        let container = try ModelContainer(
//            for: Wall.self,
//            configurations: ModelConfiguration(isStoredInMemoryOnly: false)
//        )
//        //    let image = UIImage(named: "test_wall")!
//        let image = UIImage(named: "test_wall")!
//        let data = image.pngData()!
//        let wall = getWallFromData(data: data)
//        let context = container.mainContext
//        context.insert(wall)
//        return EditWallView(wall: wall).modelContainer(container)
//    } catch {
//        fatalError("Failed to create model container: \(error)")
//    }
//}
