import SwiftUI
import SwiftData
import Foundation

@Model
class Hold {
    var points: [CGPoint] = []

    init(points: [CGPoint]) {
        self.points = points
    }
}

@Model
class Wall {
    var imageData: Data
    var width: CGFloat
    var height: CGFloat

    // TODO: Check if this needs a query param.
    var holds: [Hold] = []

    // When the wall is first constructed on a device, we compute it's original height
    // and original width. All other points are stored relative to the original height
    // and width of the original image.
    //
    // Then, the points are appropriately scaled based on the dimensions of the image
    // on the new device.
    init(imageData: Data, width: CGFloat, height: CGFloat) {
        self.imageData = imageData
        self.width = width
        self.height = height
    }
}

enum WallViewMode {
    case addPoints
    case addHold
    case view
}

// WallView is a container which displays the wall.
//
// In .addPoints mode:
//    1. You can zoom in on the wall image.
//    2. You can tap points to create a polygon. If you click Preview, it shows you a boundary with
//       the polygon. If you 
//
// In .addHold mode:
//    1. If there are 3 or more points then, the hold is saved.
//
// In .view mode:
//   1. You can tap on the image. If the tap location is inside one or more hold polygons, then the hold boundaries
//      light up.
//
// 1. Add Hold: This allows tapping on the view to add points to the Wall.
// 2. Move: This allows zooming in on the image, and moving around the image inside the container.
//
// In VIEW mode, it's possible to click on parts of the image. When you click within the boundaries of
// a hold as defined by a polygon, the hold boundaries are overlayed on the image. It's possible to zoom
// in on the image before clicking on the polygon.
struct WallView: View {
    var wall: Wall
    @Binding var mode: WallViewMode

    var body: some View {
        if let uiImage = UIImage(data: wall.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        } else {
            fatalError("wall must have an image")
        }
    }
}

#Preview {
    let image = UIImage(named: "test_wall")!
    let data = image.pngData()!
    let wall = getWallFromData(data: data)

    @State var mode = WallViewMode.addPoints
    return WallView(wall: wall, mode: $mode)
}
