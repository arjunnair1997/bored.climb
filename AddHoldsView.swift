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

// TODO: As more than one point is added, also show the distance between the
// points.
struct AddHoldsView: View {
    var wall: Wall

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageFrame: CGRect = .zero
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        // TODO: Why are there two geometry readers here?
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
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = min(max(1.0, lastScale * value), 10.0)
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                        },
                                    DragGesture()
                                        .onChanged { value in
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

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scale: \(scale, specifier: "%.2f")")
                    Text("Image Size: \(Int(imageFrame.width)) x \(Int(imageFrame.height))")
                    Text("Top-Left: (x: \(Int(imageFrame.minX)), y: \(Int(imageFrame.minY)))")
                    Text("Bottom-Right: (x: \(Int(imageFrame.maxX)), y: \(Int(imageFrame.maxY)))")
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(10)
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
        }
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
}

// TODO: Have a second test image which is vertically longer than it is horizontally.
#Preview {
    let image = UIImage(named: "test_wall")!
    let data = image.pngData()!
    let wall = getWallFromData(data: data)
    return AddHoldsView(wall: wall)
}
