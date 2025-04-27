import SwiftUI
import SwiftData
import Foundation

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
    var width: CGFloat
    var height: CGFloat
    var holds: [Hold] = []

    init(imageData: Data, width: CGFloat, height: CGFloat) {
        self.imageData = imageData
        self.width = width
        self.height = height
    }
}

struct AddHoldsView: View {
    var wall: Wall

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageFrame: CGRect = .zero
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var tapCoordinates: CGPoint? = nil
    @State private var showTapCoordinates: Bool = false
    @State private var showModal: Bool = true
    
    // Timer for showing tap coordinates temporarily
    let tapDisplayDuration: Double = 2.0

    var body: some View {
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
                                .background(
                                    Color.clear
                                        .onAppear {
                                            imageFrame = computeScaledFrame(baseFrame: baseFrame, scale: scale)
                                        }
                                        .onChange(of: scale) { _, newScale in
                                            imageFrame = computeScaledFrame(baseFrame: baseFrame, scale: newScale)
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
                                        .onTapGesture { location in
                                            // Dismiss modal on tap
                                            showModal = false
                                            
                                            // Convert container coordinates to image coordinates
                                            let relativeTapPoint = convertToImageCoordinates(
                                                containerPoint: location,
                                                containerSize: containerSize,
                                                imageSize: uiImage.size,
                                                scale: scale,
                                                offset: imageOffset
                                            )
                                            
                                            // Store and display the tap coordinates
                                            tapCoordinates = relativeTapPoint
                                            showTapCoordinates = true
                                            
                                            // Hide coordinates after delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + tapDisplayDuration) {
                                                showTapCoordinates = false
                                            }
                                        }
                                )
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                // Dismiss modal on gesture
                                                showModal = false
                                                scale = min(max(1.0, lastScale * value), 10.0)
                                            }
                                            .onEnded { _ in
                                                lastScale = scale
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                // Dismiss modal on gesture
                                                showModal = false
                                                let newOffset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                                imageOffset = clampedOffset(
                                                    offset: newOffset,
                                                    scale: scale,
                                                    containerSize: containerSize,
                                                    imageSize: baseFrame.size
                                                )
                                            }
                                            .onEnded { _ in
                                                lastOffset = imageOffset
                                            }
                                    )
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
            
            // Undo and redo buttons overlay
            VStack {
                HStack {
                    // Undo and redo buttons
                    HStack {
                        Button(action: {
                            undoAction()
                            showModal = false
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.gray.opacity(0.5)))
                        }
                        
                        Button(action: {
                            redoAction()
                            showModal = false
                        }) {
                            Image(systemName: "arrow.uturn.forward")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.gray.opacity(0.5)))
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // Modal overlay
            if showModal {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        Text("Zoom and tap to create hold")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(10)
                    )
                    .onTapGesture {
                        showModal = false
                    }
            }
        }
        .onAppear {
            // Show modal when view appears
            showModal = true
        }
    }
    
    // Stub function for undo action
    func undoAction() {
        print("Undo action triggered")
        // TODO: Implement undo functionality
    }
    
    // Stub function for redo action
    func redoAction() {
        print("Redo action triggered")
        // TODO: Implement redo functionality
    }

    func computeScaledFrame(baseFrame: CGRect, scale: CGFloat) -> CGRect {
        let center = CGPoint(x: baseFrame.midX, y: baseFrame.midY)
        let newSize = CGSize(width: baseFrame.width * scale, height: baseFrame.height * scale)
        let newOrigin = CGPoint(x: center.x - newSize.width / 2, y: center.y - newSize.height / 2)
        return CGRect(origin: newOrigin, size: newSize)
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

        // 3. Compute image edges relative to offset
        let minX = (containerSize.width - scaledSize.width) / 2 + offset.width
        let maxX = minX + scaledSize.width
        let minY = (containerSize.height - scaledSize.height) / 2 + offset.height
        let maxY = minY + scaledSize.height

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
}

// TODO: Have a second test image which is vertically longer than it is horizontally.
#Preview {
    let image = UIImage(named: "test_wall")!
    let data = image.pngData()!
    let wall = getWallFromData(data: data)
    return AddHoldsView(wall: wall)
}
