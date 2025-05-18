import SwiftUI

func getDescriptionForClimbView(desc: String) -> (String, Bool) {
    if desc.isEmpty {
        return ("No description.", true)
    }
    return (desc, false)
}

// Comment cell view component
struct CommentCell: View {
    let comment: ClimbComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formattedDate(comment.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
            
            HStack {
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            
            
        }
        .padding(10)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// TODO: add support for slide to go back.
// TODO: don't allow the image to shrink when the keyboard comes up.
struct ClimbView: View {
    @EnvironmentObject var nav: NavigationStateManager

    var climb: Climb
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var commentText: String = ""
    @State private var comments: [ClimbComment] = []
    
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
                        .truncationMode(.tail)
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
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                    
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
                                climb.addComment(content: commentText)
                                // Refresh comments after adding
                                comments = climb.comments
                                commentText = ""
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(toolbarColor)
                                .padding(10)
                        }
                    }
                    .padding(.horizontal, 10)
                    
                    // Comments list
                    ScrollView {
                        VStack(spacing: 0) { // Changed spacing to 0
                            if comments.isEmpty {
                                Text("No comments yet.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
                                ForEach(comments, id: \.id) { comment in
                                    VStack {
                                        CommentCell(comment: comment)
                                            .contextMenu {
                                                Button(role: .destructive, action: {
                                                    if let commentId = comment.id {
                                                        climb.deleteComment(commentId: commentId)
                                                        // Refresh comments after deleting
                                                        comments = climb.comments
                                                    }
                                                }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        
                                        // Add thin white divider line after each comment (except the last one)
                                        if comment.id != comments.last?.id {
                                            Divider()
                                                .background(Color.black.opacity(0.3))
                                                .padding(.horizontal, 10)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .background(Color.white)
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
        .onAppear {
            // Load comments when view appears
            comments = climb.comments
        }
    }
}
