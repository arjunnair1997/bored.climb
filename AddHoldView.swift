import SwiftUI
import Foundation

struct AddHoldView: View {
    var wall: Wall

    @Environment(\.dismiss) private var dismiss

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0

    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button("Undo") {
                    // TODO
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .overlay(Divider(), alignment: .bottom)

            if let uiImage = UIImage(data: wall.imageData) {
                GeometryReader { geometry in
                    let containerSize = geometry.size
                    let imageWidth = containerSize.width
                    let imageHeight = uiImage.size.height / uiImage.size.width * imageWidth
                    let maxOffsetX = max(0, (imageWidth * zoomScale - imageWidth) / 2)
                    let maxOffsetY = max(0, (imageHeight * zoomScale - imageHeight) / 2)

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageWidth)
                        .scaleEffect(zoomScale)
                        .offset(imageOffset)
                        .gesture(
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
                                            imageOffset = clampedOffset(lastImageOffset, maxX: maxOffsetX, maxY: maxOffsetY)
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
                        .animation(.easeInOut(duration: 0.2), value: zoomScale)
                }
            } else {
                Text("No image available")
                    .padding()
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }

    /// Clamp offset so image never leaves frame
    private func clampedOffset(_ offset: CGSize, maxX: CGFloat, maxY: CGFloat) -> CGSize {
        CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}

