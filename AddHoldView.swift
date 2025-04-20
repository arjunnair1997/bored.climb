import SwiftUI
import SwiftData
import Foundation

func convertToImageCoordinates(tapLocation: CGPoint,
                               containerSize: CGSize,
                               zoomScale: CGFloat,
                               offset: CGSize,
                               imageSize: CGSize) -> CGPoint {

    let imageFrame = CGRect(
        x: (containerSize.width - imageSize.width) / 2,
        y: (containerSize.height - imageSize.height) / 2,
        width: imageSize.width,
        height: imageSize.height
    )

    let adjustedX = (tapLocation.x - imageFrame.origin.x - offset.width) / zoomScale
    let adjustedY = (tapLocation.y - imageFrame.origin.y - offset.height) / zoomScale

    return CGPoint(x: adjustedX, y: adjustedY)
}

func clampedOffset(_ offset: CGSize, maxX: CGFloat, maxY: CGFloat) -> CGSize {
    CGSize(
        width: min(max(offset.width, -maxX), maxX),
        height: min(max(offset.height, -maxY), maxY)
    )
}

func convertToScreenCoordinates(imagePoint: CGPoint,
                                containerSize: CGSize,
                                zoomScale: CGFloat,
                                offset: CGSize,
                                imageSize: CGSize) -> CGPoint {

    let imageFrame = CGRect(
        x: (containerSize.width - imageSize.width) / 2,
        y: (containerSize.height - imageSize.height) / 2,
        width: imageSize.width,
        height: imageSize.height
    )

    let screenX = imageFrame.origin.x + imagePoint.x * zoomScale + offset.width
    let screenY = imageFrame.origin.y + imagePoint.y * zoomScale + offset.height

    return CGPoint(x: screenX, y: screenY)
}

func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
}
struct AddHoldView: View {
    var wall: Wall

    @Environment(\.dismiss) private var dismiss

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0

    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero

    @State private var isAddingPoints = false
    @State private var currentPoints: [CGPoint] = []
    @State private var firstTapThreshold: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Undo") {
                    if !currentPoints.isEmpty {
                        currentPoints.removeLast()
                    }
                }

                Spacer()

                Button("Done") {
                    if currentPoints.count > 2 {
                        wall.holds.append(Hold(points: currentPoints))
                    }
                    dismiss()
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .overlay(Divider(), alignment: .bottom)

            if let uiImage = UIImage(data: wall.imageData) {
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        let containerSize = geometry.size
                        let imageWidth = containerSize.width
                        let imageHeight = uiImage.size.height / uiImage.size.width * imageWidth
                        let imageSize = CGSize(width: imageWidth, height: imageHeight)
                        let maxOffsetX = max(0, (imageWidth * zoomScale - imageWidth) / 2)
                        let maxOffsetY = max(0, (imageHeight * zoomScale - imageHeight) / 2)
                        
                        VStack {
                            ZStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: imageWidth)
                                    .scaleEffect(zoomScale)
                                    .offset(imageOffset)
                                    .gesture(
                                        isAddingPoints ? nil :
                                            SimultaneousGesture(
                                                MagnificationGesture()
                                                    .onChanged { value in
                                                        zoomScale = max(1.0, lastZoomScale * value)
                                                    }
                                                    .onEnded { _ in
                                                        lastZoomScale = zoomScale
                                                        
                                                        if zoomScale == 1.0 {
                                                            imageOffset = .zero
                                                            lastImageOffset = .zero
                                                        } else {
                                                            imageOffset = clampedOffset(imageOffset, maxX: maxOffsetX, maxY: maxOffsetY)
                                                            lastImageOffset = imageOffset
                                                        }
                                                    },
                                                
                                                DragGesture()
                                                    .onChanged { value in
                                                        if zoomScale > 1.0 {
                                                            let rawOffset = CGSize(
                                                                width: lastImageOffset.width + value.translation.width,
                                                                height: lastImageOffset.height + value.translation.height
                                                            )
                                                            imageOffset = clampedOffset(rawOffset, maxX: maxOffsetX, maxY: maxOffsetY)
                                                        }
                                                    }
                                                    .onEnded { _ in
                                                        lastImageOffset = imageOffset
                                                    }
                                            )
                                    )
                                    .clipped()
                                
                                ForEach(Array(currentPoints.enumerated()), id: \.0) { (i, point) in
                                    let screenPoint = convertToScreenCoordinates(
                                        imagePoint: point,
                                        containerSize: containerSize,
                                        zoomScale: zoomScale,
                                        offset: imageOffset,
                                        imageSize: imageSize
                                    )
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .position(screenPoint)
                                }
                            }
                            .contentShape(Rectangle())
                            .gesture(
                                isAddingPoints
                                ? DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let location = value.location
                                        let imagePoint = convertToImageCoordinates(
                                            tapLocation: location,
                                            containerSize: containerSize,
                                            zoomScale: zoomScale,
                                            offset: imageOffset,
                                            imageSize: imageSize
                                        )
                                        
                                        if let first = currentPoints.first,
                                           distance(first, imagePoint) < firstTapThreshold {
                                            // Close the polygon
                                            currentPoints.append(first)
                                            wall.holds.append(Hold(points: currentPoints))
                                            currentPoints = []
                                            isAddingPoints = false
                                        } else {
                                            currentPoints.append(imagePoint)
                                        }
                                    }
                                : nil
                            )
                            
                            Button("Add") {
                                isAddingPoints = true
                            }
                            .disabled(isAddingPoints)
                            .padding(.vertical, 8)
                        }
                    }
                }
            } else {
                fatalError("wall must have an image")
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
