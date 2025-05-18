import SwiftUI

struct JournalView: View {
    @State private var entryText: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Spacer().frame(height: 16)

                    // Text input for new comment
                    HStack {
                        TextField("Add an entry...", text: $entryText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            // Handle comment submission
                            if !entryText.isEmpty {
//                                climb.addComment(content: commentText)
                                // Refresh comments after adding
//                                comments = climb.comments
                                entryText = ""
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
                            if true {
                                Text("No entries yet.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
//                                ForEach(comments, id: \.id) { comment in
//                                    VStack {
//                                        CommentCell(comment: comment)
//                                            .contextMenu {
//                                                Button(role: .destructive, action: {
//                                                    if let commentId = comment.id {
//                                                        climb.deleteComment(commentId: commentId)
//                                                        // Refresh comments after deleting
//                                                        comments = climb.comments
//                                                    }
//                                                }) {
//                                                    Label("Delete", systemImage: "trash")
//                                                }
//                                            }
//                                        
//                                        // Add thin white divider line after each comment (except the last one)
//                                        if comment.id != comments.last?.id {
//                                            Divider()
//                                                .background(Color.black.opacity(0.3))
//                                                .padding(.horizontal, 10)
//                                        }
//                                    }
//                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .padding(.bottom, 10)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Journal")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            .toolbarBackground(toolbarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

