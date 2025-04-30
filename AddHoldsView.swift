import SwiftUI
import SwiftData
import Foundation

// Helper function to convert image coordinates to container coordinates
func convertToContainerCoordinates(
    imagePoint: CGPoint,
    containerSize: CGSize,
    imageSize: CGSize,
    scale: CGFloat,
    offset: CGSize
) -> CGPoint {
    // 1. Calculate the fitted image size within the container (before scaling)
    let imageAspect = imageSize.width / imageSize.height
    let containerAspect = containerSize.width / containerSize.height
    
    let fittedSize: CGSize
    if imageAspect > containerAspect {
        // Fit to width
        let width = containerSize.width
        let height = width / imageAspect
        fittedSize = CGSize(width: width, height: height)
    } else {
        // Fit to height
        let height = containerSize.height
        let width = height * imageAspect
        fittedSize = CGSize(width: width, height: height)
    }
    
    // 2. Calculate the scaled size and origin of the image
    let scaledSize = CGSize(width: fittedSize.width * scale, height: fittedSize.height * scale)
    let imageOriginX = (containerSize.width - scaledSize.width) / 2 + offset.width
    let imageOriginY = (containerSize.height - scaledSize.height) / 2 + offset.height
    
    // 3. Calculate the relative point within the image (0-1)
    let relativeX = imagePoint.x / imageSize.width
    let relativeY = imagePoint.y / imageSize.height
    
    // 4. Convert to container coordinates
    let containerX = imageOriginX + (relativeX * scaledSize.width)
    let containerY = imageOriginY + (relativeY * scaledSize.height)
    
    return CGPoint(x: containerX, y: containerY)
}

func convertToImageCoordinates(
    containerPoint: CGPoint,
    containerSize: CGSize,
    imageSize: CGSize,
    scale: CGFloat,
    offset: CGSize
) -> CGPoint {
    // 1. Calculate the fitted image size within the container (before scaling)
    let imageAspect = imageSize.width / imageSize.height
    let containerAspect = containerSize.width / containerSize.height
    
    let fittedSize: CGSize
    if imageAspect > containerAspect {
        // Fit to width
        let width = containerSize.width
        let height = width / imageAspect
        fittedSize = CGSize(width: width, height: height)
    } else {
        // Fit to height
        let height = containerSize.height
        let width = height * imageAspect
        fittedSize = CGSize(width: width, height: height)
    }
    
    // 2. Calculate the position of the image taking into account scaling and offset
    let scaledSize = CGSize(width: fittedSize.width * scale, height: fittedSize.height * scale)
    let imageOriginX = (containerSize.width - scaledSize.width) / 2 + offset.width
    let imageOriginY = (containerSize.height - scaledSize.height) / 2 + offset.height
    
    // 3. Calculate the relative position within the scaled image
    let relativeX = (containerPoint.x - imageOriginX) / scaledSize.width
    let relativeY = (containerPoint.y - imageOriginY) / scaledSize.height
    
    // 4. Convert relative position to original image coordinates
    let imageX = relativeX * imageSize.width
    let imageY = relativeY * imageSize.height
    
    // Make sure the coordinates are within the image bounds
    let boundedX = max(0, min(imageSize.width, imageX))
    let boundedY = max(0, min(imageSize.height, imageY))
    
    return CGPoint(x: boundedX, y: boundedY)
}

// TODO: Consider a way to fit in a cancel button. Cancel is highly useful.
// Then if someone clicks on Done with less than 3 holds, show a pop-up which
// is something like "A hold must be constructed of at least 3 points.
struct AddHoldsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var nav: NavigationStateManager

    var wall: Wall

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var tapCoordinates: CGPoint? = nil
    @State private var showTapCoordinates: Bool = false
    
    // Store the tapped points
    @State private var tappedPoints: [CGPoint] = []
    
    // Timer for showing tap coordinates temporarily
    let tapDisplayDuration: Double = 2.0

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    GeometryReader { containerGeo in
                        ZStack(alignment: .topLeading) {
                            if let uiImage = UIImage(data: wall.imageData) {
                                GeometryReader { imageGeo in
                                    let containerSize = containerGeo.size
                                    let baseFrame = imageGeo.frame(in: .global)

                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(scale)
                                        .offset(imageOffset)
                                        .frame(
                                            width: containerSize.width,
                                            height: containerSize.height
                                        )
                                        .overlay(
                                            PolygonView(
                                                polygons: [tappedPoints],
                                                containerSize: containerSize,
                                                imageSize: uiImage.size,
                                                scale: scale,
                                                offset: imageOffset,
                                                drawCircle: true
                                            )
                                        )
                                        .background(
                                            Color.clear
                                                .onAppear {}
                                                .onChange(of: scale) { _, newScale in
                                                    imageOffset = clampedOffset(
                                                        offset: imageOffset,
                                                        scale: newScale,
                                                        containerSize: containerSize,
                                                        imageSize: baseFrame.size
                                                    )
                                                    lastOffset = imageOffset
                                                }
                                        )
                                        .overlay(
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .onTapGesture { containerLoc in
                                                    // Convert container coordinates to image coordinates
                                                    let relativeTapPoint = convertToImageCoordinates(
                                                        containerPoint: containerLoc,
                                                        containerSize: containerSize,
                                                        imageSize: uiImage.size,
                                                        scale: scale,
                                                        offset: imageOffset
                                                    )
                                                    
                                                    // Add the point to our collection
                                                    tappedPoints.append(relativeTapPoint)
                                                    
                                                    // Store and display the tap coordinates
                                                    tapCoordinates = relativeTapPoint
                                                    showTapCoordinates = true
                                                    
                                                    // Hide coordinates after delay
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + tapDisplayDuration) {
                                                        showTapCoordinates = false
                                                    }
                                                }
                                        )
                                }
                            } else {
                                fatalError("wall must have an image")
                            }

                            // Display tap coordinates when available
                            if showTapCoordinates, let coordinates = tapCoordinates {
                                VStack {
                                    Spacer()
                                    Text("Tap: (x: \(Int(coordinates.x)), y: \(Int(coordinates.y)))")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(10)
                                        .padding(.bottom, 20)
                                }
                                .frame(width: containerGeo.size.width)
                                .animation(.easeInOut, value: showTapCoordinates)
                            }
                        }
                        .background(Color.black.ignoresSafeArea())
                    }
                }
                .background(Color.black)
                
                // TODO: Maybe replace the Undo button with Undo text. Right now it looks too much like back, and in fact it's more obviously back, because you come into this view from the EditWallView.
                // Undo, redo, and Done buttons overlay
                VStack {
                    HStack {
                        // Undo and redo buttons
                        HStack {
                            Button(action: {
                                undoAction()
                            }) {
                                Image(systemName: "arrow.uturn.backward")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.clear))
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Instruction text
                        // TODO: Make sure this is centrally aligned.
                        Text("Zoom and tap to create hold")
                            .font(.custom("tiny", size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                        
                        Spacer()
                        
                        // Done button
                        Button(action: {
                            // This will do nothing for now
                            // Add view dismissal code here when needed
                            print("Done button tapped")
                            if tappedPoints.count > 2 {
                                wall.holds.append(Hold(points: tappedPoints))
                                
                            }
                            saveContext(context: context)
//                            dismiss()
                            nav.removeLast()
                        }) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            // Add the gestures directly to the ZStack to ensure they work with the modal
            .gesture(
                SimultaneousGesture(
                    // Magnification gesture to handle zooming
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(1.0, lastScale * value), 10.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        },
                    // Drag gesture for panning
                    DragGesture()
                        .onChanged { value in
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            imageOffset = clampedOffset(
                                offset: newOffset,
                                scale: scale,
                                containerSize: geometryProxy.size,
                                imageSize: CGSize(width: wall.width, height: wall.height)
                            )
                        }
                        .onEnded { _ in
                            lastOffset = imageOffset
                        }
                )
            )
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // Stub function for undo action
    func undoAction() {
        // Remove the last point if available
        if !tappedPoints.isEmpty {
            tappedPoints.removeLast()
        }
        print("Undo action triggered")
    }
    
    // Stub function for redo action
    func redoAction() {
        print("Redo action triggered")
        // TODO: Implement redo functionality
    }

    func clampedOffset(offset: CGSize, scale: CGFloat, containerSize: CGSize, imageSize: CGSize) -> CGSize {
        // 1. Get fitted image size after `.scaledToFit()` but before scaling
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        let fittedSize: CGSize
        if imageAspect > containerAspect {
            // Fit to width
            let width = containerSize.width
            let height = width / imageAspect
            fittedSize = CGSize(width: width, height: height)
        } else {
            // Fit to height
            let height = containerSize.height
            let width = height * imageAspect
            fittedSize = CGSize(width: width, height: height)
        }

        // 2. Apply scale
        let scaledSize = CGSize(width: fittedSize.width * scale, height: fittedSize.height * scale)

        // 4. Clamp offsets so image edges stay within container
        let clampX: CGFloat
        if scaledSize.width <= containerSize.width {
            clampX = 0  // no panning allowed
        } else {
            let maxOffsetX = (scaledSize.width - containerSize.width) / 2
            clampX = min(max(offset.width, -maxOffsetX), maxOffsetX)
        }

        let clampY: CGFloat
        if scaledSize.height <= containerSize.height {
            clampY = 0
        } else {
            let maxOffsetY = (scaledSize.height - containerSize.height) / 2
            clampY = min(max(offset.height, -maxOffsetY), maxOffsetY)
        }

        return CGSize(width: clampX, height: clampY)
    }
}

// Custom view to draw the polygon
struct PolygonView: View {
    let polygons: [[CGPoint]]  // Array of polygon point arrays
    let containerSize: CGSize
    let imageSize: CGSize
    let scale: CGFloat
    let offset: CGSize
    let drawCircle: Bool

    var body: some View {
        Canvas { context, size in
            // Process each polygon in the array
            for polygon in polygons {
                // Draw points and lines only if there are points in this polygon
                if !polygon.isEmpty {
                    // Convert image coordinates to container coordinates for display
                    let containerPoints = polygon.map { point in
                        convertToContainerCoordinates(
                            imagePoint: point,
                            containerSize: containerSize,
                            imageSize: imageSize,
                            scale: scale,
                            offset: offset
                        )
                    }
                    
                    // Draw points if drawCircle is true
                    if drawCircle {
                        for point in containerPoints {
                            // Draw a small circle at each point
                            let pointRect = CGRect(
                                x: point.x - 5,
                                y: point.y - 5,
                                width: 10,
                                height: 10
                            )
                            context.fill(Path(ellipseIn: pointRect), with: .color(.white))
                        }
                    }
                    
                    // Draw lines between points if there are at least 2 points
                    if containerPoints.count >= 2 {
                        // Create a path for the lines
                        var path = Path()
                        
                        // Start at the first point
                        path.move(to: containerPoints[0])
                        
                        // Connect each subsequent point
                        for i in 1..<containerPoints.count {
                            path.addLine(to: containerPoints[i])
                        }
                        
                        // Close the loop if there are 3 or more points
                        if containerPoints.count >= 3 {
                            path.addLine(to: containerPoints[0])
                        }
                        
                        // Draw the path with a white stroke
                        context.stroke(path, with: .color(.white), lineWidth: 2)
                    }
                }
            }
        }
    }
}
// TODO: Have a second test image which is vertically longer than it is horizontally.
//#Preview {
//    let image = UIImage(named: "test_wall")!
//    let data = image.pngData()!
//    let wall = getWallFromData(data: data)
//    return AddHoldsView(wall: wall)
//}
