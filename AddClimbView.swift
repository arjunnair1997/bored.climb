import SwiftUI

struct AddClimbView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var nav: NavigationStateManager

    var wall: Wall

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedHolds: [Hold] = []

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
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
                                                polygons: selectedHolds.map { $0.points },
                                                containerSize: containerSize,
                                                imageSize: uiImage.size,
                                                scale: scale,
                                                offset: imageOffset,
                                                drawCircle: false
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
                                                    
                                                    // Find all holds that contain the tapped point
                                                    let tappedHolds = wall.holds.filter { hold in
                                                        isPointInPolygon(point: relativeTapPoint, points: hold.points)
                                                    }
                                                    
                                                    print("Tapped coordinates: \(relativeTapPoint)")
                                                    print("Overlapping holds found: \(tappedHolds.count)")
                                                    
                                                    if !tappedHolds.isEmpty {
                                                        // Add each tapped hold to the selection
                                                        for hold in tappedHolds {
                                                            // If the hold is not already selected, add it
                                                            if !selectedHolds.contains(where: { $0.id == hold.id }) {
                                                                selectedHolds.append(hold)
                                                            } else {
                                                                // If the hold is already selected, you could optionally deselect it
                                                                // selectedHolds.removeAll(where: { $0.id == hold.id })
                                                            }
                                                        }
                                                    }
                                                }
                                        )
                                }
                            } else {
                                fatalError("wall must have an image")
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
                        Button(action: {
                            // This will do nothing for now
                            // Add view dismissal code here when needed
                            print("Cancel button tapped")
                            saveContext(context: context)
                            nav.removeLast()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .cornerRadius(8)
                        }
                        .padding()

                        Spacer()

                        // TODO: Make sure this is centrally aligned.
                        Text("Tap to select holds")
                            .font(.custom("tiny", size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                        
                        Spacer()

                        ZStack {
                            // Invisible placeholder with same size as Next button. This is so that
                            // the previous text stays aligned.
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.clear) // Invisible
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .opacity(0)

                            // Actual Next button
                            if selectedHolds.count > 0 {
                                Button(action: {
                                    print("Next button tapped")
                                    saveContext(context: context)
                                    nav.removeLast()
                                }) {
                                    Text("Next")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.clear)
                                        .cornerRadius(8)
                                }
                            }
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
}
