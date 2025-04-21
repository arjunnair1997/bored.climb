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

    var body: some View {
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
                            .frame(
                                width: containerSize.width,
                                height: containerSize.height
                            )
                            .background(
                                Color.clear
                                    .onAppear {
                                        imageFrame = computeScaledFrame(baseFrame: baseFrame, scale: scale)
                                    }
                                    .onChange(of: scale) { oldScale, newScale in
                                        imageFrame = computeScaledFrame(baseFrame: baseFrame, scale: newScale)
                                    }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = min(max(1.0, lastScale * value), 10.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                    }
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
}

#Preview {
    let image = UIImage(named: "test_wall")!
    let data = image.pngData()!
    let wall = getWallFromData(data: data)
    return AddHoldsView(wall: wall)
}
