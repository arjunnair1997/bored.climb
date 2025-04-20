import SwiftUI
import SwiftData

struct EditBoardView: View {
    let imageData: Data?
    @State private var wall:  Wall?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var navigateToAddHoldView = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button("Back") {
                    dismiss()
                }

                Spacer()

                Button("Save") {
                    // TODO: Wall shouldn't really be saved if there's literally no edits to it.
                    if wall == nil, let data = imageData {
                        // Create a new wall with the image. Do not persist it yet.
                        wall = Wall(imageData: data)
                        context.insert(wall.unsafelyUnwrapped)
                        saveContext(context: context)
                    }

                    // No need to reinsert, just and all the updates will automatically be saved.
                    saveContext(context: context)
                    dismiss()
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6)) // Light toolbar background
            .overlay(Divider(), alignment: .bottom)

            // TODO: Make sure that in all views, the image fits in the entire screen.
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            } else {
                Text("No image available")
                    .padding()
            }

            Button("Add Hold") {
                // TODO: Wall shouldn't really be saved if there's literally no edits to it.
                if wall == nil, let data = imageData {
                    // Create a new wall with the image. Do not persist it yet.
                    wall = Wall(imageData: data)
                    context.insert(wall.unsafelyUnwrapped)
                    saveContext(context: context)
                }

                // No need to reinsert, just and all the updates will automatically be saved.
                saveContext(context: context)
                navigateToAddHoldView = true
            }
            .padding(.top, 12)

            Spacer()
            
            // TODO: Render a list of all holds here. Have a delete button to delete the hold. Show
            // a confirmation.
        }
        .onAppear {
            // TODO: Auto save the wall if any property of the wall is changed.
            if imageData == nil && wall != nil {
                // Existing wall is being edited.
            } else if wall == nil, let _ = imageData {
               // This is ok, a new wall will be created using the imageData.
            } else {
                // Both wall and image data are nil, or both are set.
                fatalError("both wall and image data are nil or set")
            }
        }
        .navigationDestination(isPresented: $navigateToAddHoldView) {
            if let wall = wall {
                AddHoldView(wall: wall)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
