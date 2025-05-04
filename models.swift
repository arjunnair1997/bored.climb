import Foundation
import SwiftData

@Model
class Hold {
    var points: [CGPoint] = []

    init(points: [CGPoint]) {
        self.points = points
    }
}

// Invariant: Once a wall has at least one climb, it is considered immutable.
//
// TODO: Perform all mutations on the wall through custom functions so that
// the invariants can be verified.
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

func formatGrade(_ grade: Grade) -> String {
    switch grade {
    case .V_0: return "V0"
    case .V_1: return "V1"
    case .V_2: return "V2"
    case .V_3: return "V3"
    case .V_4: return "V4"
    case .V_5: return "V5"
    case .V_6: return "V6"
    case .V_7: return "V7"
    case .V_8: return "V8"
    case .V_9: return "V9"
    case .V_10: return "V10"
    case .V_11: return "V11"
    case .V_12: return "V12"
    case .V_13: return "V13"
    case .V_14: return "V14"
    case .V_15: return "V15"
    case .V_16: return "V16"
    case .V_17: return "V17"
    }
}

let maxStartHolds = 4
let maxFinishHolds = 2

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
    var desc: String

    // Set of holds associated with this climb.
    //
    // INVARIANT: holdTypes and holds have the same length.
    var holds: [Hold]
    var holdTypes: [HoldType]

    // TODO: deal with the case where the hold is deleted. What happens to the climb?
    init(name: String, grade: Grade, wall: Wall, desc: String, holds: [Hold], holdTypes: [HoldType]) {
        self.name = name
        self.grade = grade
        self.wall = wall
        self.desc = desc
        self.holds = holds
        self.holdTypes = holdTypes
        
        // TODO: Check other invariants here.
        if holdTypes.count != holds.count {
            fatalError("invalid len holds/holdTypes")
        }
    }
}
