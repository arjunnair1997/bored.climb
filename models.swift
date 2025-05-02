import Foundation
import SwiftData

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
    var name: String = ""

    @Relationship(deleteRule: .cascade) var holds: [Hold] = []

    // Name must already be validated.
    init(imageData: Data, width: CGFloat, height: CGFloat, name: String) {
        self.imageData = imageData
        self.width = width
        self.height = height
        self.name = name
    }
}
