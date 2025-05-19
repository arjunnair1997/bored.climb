import SwiftUI

struct ClimbImageView: View {
    @EnvironmentObject var nav: NavigationStateManager

    var climb: Climb

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(climb: Climb) {
        climb.validate()
        self.climb = climb
    }

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                VStack(spacing: 0) {
                    GeometryReader { containerGeo in
                        ZStack(alignment: .topLeading) {
                            if let uiImage = UIImage(data: climb.wall().imageData) {
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
                                        .clipped()
                                        .overlay(
                                            PolygonView(
                                                polygons: climb.climbHolds.map { $0.hold.cgPoints() },
                                                containerSize: containerSize,
                                                imageSize: uiImage.size,
                                                scale: scale,
                                                offset: imageOffset,
                                                drawCircle: false,
                                                holdTypes: climb.climbHolds.map { $0.holdType}
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
                                }
                            } else {
                                fatalError("wall must have an image")
                            }
                        }
                        .background(Color.black.ignoresSafeArea())
                    }
                }
                .background(Color.black)

                VStack {
                    HStack {
                        Button(action: {
                            nav.removeLast()
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .cornerRadius(8)
                        }
                        .padding()

                        Spacer()

                        Text("\(climb.name)")
                            .font(.custom("tiny", size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)

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
                            let wall = climb.wall()
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
        .navigationDestination(for: NavToFinishClimbView.self) { navWall in
            FinishClimbView(wall: navWall.wall, selectedHolds: navWall.selectedHolds, holdTypes: navWall.holdTypes)
        }
    }
}
