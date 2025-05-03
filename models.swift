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
    @Relationship(deleteRule: .cascade) var climbs: [Climb] = []

    // Name must already be validated.
    init(imageData: Data, width: CGFloat, height: CGFloat, name: String) {
        self.imageData = imageData
        self.width = width
        self.height = height
        self.name = name
    }
}

enum Grade: Codable {
    case
        V_0,
        V_1,
        V_2,
        V_3,
        V_4,
        V_5,
        V_6,
        V_7,
        V_8,
        V_9,
        V_10,
        V_11,
        V_12,
        V_13,
        V_14,
        V_15,
        V_16,
        V_17
}

enum HoldType: Codable {
    case
        start,
        finish,
        middle
}

@Model
class Climb {
    var name: String
    var grade: Grade
    
    // Wall associated with this climb.
    var wall: Wall

    // Set of holds associated with this climb.
    //
    // INVARIANT: holdTypes and holds have the same length.
    var holds: [Hold] = []
    var holdTypes: [HoldType] = []

    init(name: String, grade: Grade, wall: Wall) {
        self.name = name
        self.grade = grade
        self.wall = wall
    }
}
