import SwiftUI
import SwiftData

struct UploadBoardView: View {
    let imageData: Data?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button("Back") {
                    dismiss()
                }

                Spacer()

                Button("Save") {
                    if let data = imageData {
                        context.insert(Wall(imageData: data))
                        // Save changes
                        do {
                            try context.save()
                        } catch {
                            print("Error saving wall: \(error)")
                        }
                        dismiss()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6)) // Light toolbar background
            .overlay(Divider(), alignment: .bottom)

            // Uploaded image
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            } else {
                Text("No image available")
                    .padding()
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}

