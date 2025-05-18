import SwiftUI

// TODO: This is fine but i want to try an alternate theme. The colors start off as dull
// per "group" of grades and as the grades progress they become brighter. So Light green
// should come after Teal-green. I don't care that it transitions correctly between groups
// of grades.
func colorForGrade(_ grade: Grade) -> Color {
    switch grade {
    case .proj:
        return Color.gray.opacity(0.2) // Projects with a distinct neutral color
    case .V_0:
        return Color(red: 0.4, green: 0.8, blue: 0.4).opacity(0.5) // Light green
    case .V_1:
        return Color(red: 0.2, green: 0.7, blue: 0.2).opacity(0.5) // Medium green
    case .V_2:
        return Color(red: 0.0, green: 0.6, blue: 0.4).opacity(0.5) // Teal-green
    case .V_3:
        return Color(red: 0.0, green: 0.5, blue: 0.5).opacity(0.5) // Teal
    case .V_4:
        return Color(red: 0.0, green: 0.4, blue: 0.7).opacity(0.5) // Blue-teal
    case .V_5:
        return Color(red: 0.0, green: 0.2, blue: 0.8).opacity(0.5) // Medium blue
    case .V_6:
        return Color(red: 0.2, green: 0.0, blue: 0.8).opacity(0.5) // Indigo
    case .V_7:
        return Color(red: 0.4, green: 0.0, blue: 0.8).opacity(0.5) // Purple
    case .V_8:
        return Color(red: 0.6, green: 0.0, blue: 0.8).opacity(0.5) // Deep purple
    case .V_9:
        return Color(red: 0.8, green: 0.0, blue: 0.8).opacity(0.5) // Magenta
    case .V_10:
        return Color(red: 0.8, green: 0.0, blue: 0.6).opacity(0.5) // Pink-purple
    case .V_11:
        return Color(red: 0.8, green: 0.0, blue: 0.4).opacity(0.5) // Dark pink
    case .V_12:
        return Color(red: 0.8, green: 0.0, blue: 0.2).opacity(0.5) // Pink-red
    case .V_13:
        return Color(red: 0.9, green: 0.0, blue: 0.0).opacity(0.5) // Bright red
    case .V_14:
        return Color(red: 1.0, green: 0.2, blue: 0.0).opacity(0.5) // Red-orange
    case .V_15:
        return Color(red: 1.0, green: 0.4, blue: 0.0).opacity(0.5) // Orange
    case .V_16:
        return Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.5) // Amber
    case .V_17:
        return Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.5) // Gold
    }
}

struct ClimbsView: View {
    @EnvironmentObject var nav: NavigationStateManager
    var wall: Wall
    
    var body: some View {
        List {
            ForEach(wall.climbs) { climb in
                ZStack {
                    NavigationLink(value: NavToClimbView(climb: climb, viewID: "climb_view")) {
                        EmptyView()
                    }
                        .opacity(0)
                        .buttonStyle(PlainButtonStyle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(climb.name)
                                .font(.headline)
                                .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                                .lineLimit(1)

                            Spacer()
                            
                            Text(climb.grade.displayString())
                                .font(.subheadline)
                                .padding(6)
                                .background(colorForGrade(climb.grade))
                                .cornerRadius(8)
                        }

                        Text(climb.desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(PlainListStyle())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    nav.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Climbs")
                    .font(.title)
                    .fontWeight(.bold)
            }
                
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    nav.selectionPath.append(NavToAddClimbView(wall: wall, viewID: "add_climb_view"))
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .padding(.trailing, 0)
                }
            }
        }
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavToAddClimbView.self) { navWall in
            AddClimbView(wall: navWall.wall)
        }
        .navigationDestination(for: NavToClimbView.self) { navWall in
            ClimbView(climb: navWall.climb)
        }
    }
}

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
                            // TODO: try chevron left.
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

                        // TODO: Make sure this is centrally aligned.
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

// TODO: add support for slide to go back.
struct ClimbView: View {
    @EnvironmentObject var nav: NavigationStateManager

    var climb: Climb
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
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
                                        .contentShape(Rectangle()) // Ensures the entire area is tappable
                                        .onTapGesture {
                                            // Navigate to ClimbImageView on tap
                                            nav.selectionPath.append(NavToClimbImageView(climb: climb, viewID: "climb_image_view"))
                                        }
                                }
                            } else {
                                fatalError("unable to load image")
                            }
                        }
                        .background(Color.black.ignoresSafeArea())
                }
                .background(Color.black.opacity(0.1))
                
                // Banner displaying climb grade and description - no spacing between image and banner
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(climb.grade.displayString())
                            .font(.subheadline)
                            .padding(6)
                            .background(colorForGrade(climb.grade))
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                    
                    Text(climb.desc)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.8))
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
                    Text(climb.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Add Hold button at the top right
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        nav.selectionPath.append(NavToClimbImageView(climb: climb, viewID: "climb_image_view"))
                    }) {
                        HStack {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .navigationDestination(for: NavToClimbImageView.self) { navView in
                ClimbImageView(climb: navView.climb)
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
    }
}
