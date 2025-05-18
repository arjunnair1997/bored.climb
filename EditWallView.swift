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

func holdNameFromIndex(i: Int) -> String {
    return "Hold \(i + 1)"
}

// TODO: If you add edit support for a wall, then you need to store multiple versions
// of the same wall to support existing climbs which use the older wall.
//
// TODO: It's instinctive to make this view zoomable. This is because some walls are extremely
// zoomed out, and you need to be able to zoom in to tap on the holds.
struct EditWallView: View {
    var wall: Wall
    
    // Add state for tracking overlapping holds
    @State private var overlappingHoldPolygons: [[CGPoint]] = []
    @State private var showDeleteConfirmation = false
    @State private var indexToDelete: Int?
    @State private var wallName: String
    
    @EnvironmentObject var nav: NavigationStateManager
    
    init(wall: Wall) {
        self.wall = wall
        
        // Initialize the state variable with the wall's current name
        var wallName: String
        if wall.name != "" {
            wallName = wall.name
        } else {
            wallName = "my home wall"
        }
        
        _wallName = State(initialValue: wallName)
    }
    
    var body: some View {
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
                                                    drawCircle: false,
                                                    holdTypes: []
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
                                                        isPointInPolygon(point: relativeTapPoint, points: hold.cgPoints())
                                                    }
                                                    
                                                    // Update the list of polygons to display
                                                    overlappingHoldPolygons = tappedHolds.map { $0.cgPoints() }
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
                
                // Wall name text field
                TextField("Enter wall name", text: $wallName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical)
                    .padding(.horizontal)
                    .font(.title2)
                    .onChange(of: wallName) { oldValue, newValue in
                        wall.name = newValue
                        let _ = wall.save()
                    }

                // List of holds
                List {
                    ForEach(wall.holds.indices, id: \.self) { index in
                        HStack {
                            Text(holdNameFromIndex(i: index))
                            // This is needed so that the entire list item registers
                            // the tap. Otherwise, the tap is only registered for the
                            // text.
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            overlappingHoldPolygons = [wall.holds[index].cgPoints()]
                        }
                    }
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
                                overlappingHoldPolygons = []
                                wall.deleteHold(index: index)
                                indexToDelete = nil
                                showDeleteConfirmation = false
                                let _ = wall.save()
                            }
                        }
                    }, message: {
                        if let index = indexToDelete {
                            Text("Are you sure you want to delete hold \"\(holdNameFromIndex(i: index))\"?")
                        } else {
                            Text("Are you sure you want to delete this hold?")
                        }
                    })
            }
            .toolbar {
                // Back button at the top left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
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
                        overlappingHoldPolygons = []
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
            .toolbarBackground(toolbarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
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
