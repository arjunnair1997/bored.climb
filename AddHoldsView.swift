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
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .frame(
                            width: containerGeo.size.width,
                            height: containerGeo.size.height
                        )
                        // Measure *after* scaleEffect by using a background GeometryReader
                        .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        imageFrame = proxy.frame(in: .global)
                                    }
                                    .onChange(of: scale) { oldScale, newScale in
                                        imageFrame = proxy.frame(in: .global)
                                    }
                            }
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    // Restrict scaling to
                                    scale = max(1, lastScale * value)
                                    scale = min(scale, 10)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )
                } else {
                    fatalError("wall must have an image")
                }

                // Overlay debug info
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
}

#Preview {
    let image = UIImage(named: "test_wall")!
    let data = image.pngData()!
    let wall = getWallFromData(data: data)
    return AddHoldsView(wall: wall)
}
