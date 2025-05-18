import SwiftUI

func getDescriptionForClimbView(desc: String) -> (String, Bool) {
    if desc.isEmpty {
        return ("No description.", true)
    }
    return (desc, false)
}

// TODO: add support for slide to go back.
struct ClimbView: View {
    @EnvironmentObject var nav: NavigationStateManager

    var climb: Climb
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var commentText: String = ""
    
    var body: some View {
        GeometryReader { superGeo in
            VStack(spacing: 0) {
                if let uiImage = UIImage(data: climb.wall().imageData) {
                    let imageAspect = uiImage.size.width / uiImage.size.height
                    let fittedSize = getFittedSize(imageAspect: imageAspect, containerSize: superGeo.size)
                    GeometryReader { containerGeo in
                        ZStack(alignment: .topLeading) {
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
                        }
                        //                        .background(Color.black.ignoresSafeArea())
                    }
                    .background(Color.black)
                    .frame(maxHeight: fittedSize.height)
                } else {
                    fatalError("unable to load image")
                }
                
                // Banner displaying climb grade and description - no spacing between image and banner
                HStack {
                    // TODO: Make the grade banner take up the entire Hstack height. Or even use a fixed height
                    // for the entire hstack.
                    Text(climb.grade.displayString())
                        .font(.subheadline)
                        .padding(6)
                        .background(colorForGrade(climb.grade))
                        .cornerRadius(8)

                    let (desc, isDefault) = getDescriptionForClimbView(desc: climb.desc)
                    let textColor = if isDefault {
                        Color.white.opacity(0.3)
                    } else {
                        Color.white.opacity(0.9)
                    }
                    
                    Text(desc)
                        .font(.subheadline)
                        .padding(6)
                        .foregroundColor(textColor)
                        .lineLimit(3)
                        .truncationMode(/*@START_MENU_TOKEN@*/.tail/*@END_MENU_TOKEN@*/)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(red: 48/255, green: 50/255, blue: 56/255))
                
                // Comment box section
                VStack(spacing: 12) {
                    Text("Comments")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                    
                    VStack {
                        // Existing comments would go here
                        // This is a placeholder - you'd typically have a ForEach to display comments
                        Text("No comments yet. Be the first to add one!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 10)
                    
                    // Text input for new comment
                    HStack {
                        TextField("Add a comment...", text: $commentText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            // Handle comment submission
                            if !commentText.isEmpty {
                                // Add code to save the comment
                                commentText = ""
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                                .padding(10)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
                .background(Color.black.opacity(0.7))
            }
        }
        .background(Color.black.opacity(0.7))
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
                        Image(systemName: "rectangle.and.arrow.up.right.and.arrow.down.left")
                    }
                }
            }
        }
        .navigationDestination(for: NavToClimbImageView.self) { navView in
            ClimbImageView(climb: navView.climb)
        }
        .toolbarBackground(toolbarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}
