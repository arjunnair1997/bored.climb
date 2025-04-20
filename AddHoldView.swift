import SwiftUI
import Foundation

struct AddHoldView: View {
    var wall: Wall

    // TODO: When finished adding a hold, navigate back to the wall.
    // You must pass the wall back and recreate the view.
    var body: some View {
        Text("Add Hold View")
            .font(.largeTitle)
            .padding()
            .navigationBarBackButtonHidden(true)
    }
}
