import Foundation
import SwiftData

@Model
class Hold {
    var points: [CGPoint] = []

    init(points: [CGPoint]) {
        self.points = points
        
        if self.points.count < 3 {
            fatalError("hold does not have enough points: \(self.points.count)")
        }
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
    
    func addHold(hold: Hold) {
        holds.append(hold)
    }
    
    func addClimb(climb: Climb) {
        climb.validate()
        self.climbs.append(climb)
    }

    func deleteHold(index: Int) {
        if index < 0 || index >= holds.count {
            fatalError("invalid hold index: \(index)")
        }
        
        if climbs.count > 0 {
            fatalError("cannot delete hold when wall already has climbs")
        }
        
        self.holds.remove(at: index)
    }
}

// Add a .project enum
enum Grade: Codable {
    case
        proj,
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
    case .proj: return "proj"
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
class ClimbHold {
    @Relationship var climb: Climb
    @Relationship var hold: Hold
    var holdType: HoldType
    
    init(climb: Climb, hold: Hold, holdType: HoldType) {
        self.climb = climb
        self.hold = hold
        self.holdType = holdType
    }
}

@Model
class Climb {
    var name: String
    var grade: Grade
    
    // Wall associated with this climb.
    @Relationship var wall: Wall
    var desc: String

    @Relationship(deleteRule: .cascade) var climbHolds: [ClimbHold] = []

    // TODO: deal with the case where the hold is deleted. What happens to the climb?
    init(name: String, grade: Grade, wall: Wall, desc: String) {
        if name == "" {
            fatalError("climb name cannot be empty")
        }

        self.name = name
        self.grade = grade
        self.wall = wall
        self.desc = desc
    }
    
    func addHold(hold: Hold, holdType: HoldType) {
        let climbHold = ClimbHold(climb: self, hold: hold, holdType: holdType)
        climbHolds.append(climbHold)
    }

    func setHolds(holds: [Hold], holdTypes: [HoldType]) {
        if holdTypes.count != holds.count {
            fatalError("invalid len holds/holdTypes")
        }
        
        // Verify holds belong to wall
        for hold in holds {
            if !wall.holds.contains(where: { $0 === hold }) {
                fatalError("hold not contained in wall")
            }
        }

        // Clear existing relationships
        climbHolds = []
        
        // Create new relationships preserving order
        for i in 0..<holds.count {
            self.addHold(hold: holds[i], holdType: holdTypes[i])
        }
    }

    // Modified to use the computed properties
   func validate() {
       if name == "" {
           fatalError("climb name cannot be empty")
       }
       
       for climbHold in climbHolds {
           if !wall.holds.contains(where: { $0 === climbHold.hold }) {
               fatalError("hold not contained in wall")
           }
       }
       
       // Count start and finish holds
       let startHoldCount = climbHolds.filter { $0.holdType == .start }.count
       let finishHoldCount = climbHolds.filter { $0.holdType == .finish }.count
       
       // Validate start holds (at least 1, at most 4)
       if startHoldCount < 1 {
           fatalError("climb must have at least 1 start hold")
       }
       if startHoldCount > maxStartHolds {
           fatalError("climb cannot have more than \(maxStartHolds) start holds")
       }
       
       // Validate finish holds (at least 1, at most 2)
       if finishHoldCount < 1 {
           fatalError("climb must have at least 1 finish hold")
       }
       if finishHoldCount > maxFinishHolds {
           fatalError("climb cannot have more than \(maxFinishHolds) finish holds")
       }
   }
}
