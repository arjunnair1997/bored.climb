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
    @Relationship(deleteRule: .cascade) var holds: [Hold] = []

    init(imageData: Data, width: CGFloat, height: CGFloat) {
        self.imageData = imageData
        self.width = width
        self.height = height
    }
}
