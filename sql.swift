import Foundation
import SQLite3

// MARK: - Enums
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

enum Grade: Int {
    case proj = 0
    case V_0 = 1, V_1, V_2, V_3, V_4, V_5, V_6, V_7, V_8, V_9, V_10, V_11, V_12, V_13, V_14, V_15, V_16, V_17
    
    func displayString() -> String {
        switch self {
        case .proj: return "proj"
        default: return "V\(self.rawValue - 1)"
        }
    }
}

enum HoldType: Int {
    case start = 1
    case finish = 2
    case middle = 3
}

struct Point: Codable {
    var x: Double
    var y: Double
}

class Hold: Comparable {
    var id: Int64?
    var points: [Point] = []
    
    init(points: [Point]) {
        self.points = points
        
        if self.points.count < 3 {
            fatalError("hold does not have enough points: \(self.points.count)")
        }
    }
    
    init(cgPoints: [CGPoint]) {
        self.points = cgPoints.map { Point(x: Double($0.x), y: Double($0.y)) }
        
        if self.points.count < 3 {
            fatalError("hold does not have enough points: \(self.points.count)")
        }
    }
    
    func cgPoints() -> [CGPoint] {
        var pointsToRet: [CGPoint] = []
        for point in self.points {
            pointsToRet.append(CGPoint(x: point.x, y: point.y))
        }
        return pointsToRet
    }
    
    init(id: Int64, points: [Point]) {
        self.id = id
        self.points = points
        
        if self.points.count < 3 {
            fatalError("hold does not have enough points: \(self.points.count)")
        }
    }
    
    static func < (lhs: Hold, rhs: Hold) -> Bool {
        return lhs.id.unsafelyUnwrapped < rhs.id.unsafelyUnwrapped
    }

    static func == (lhs: Hold, rhs: Hold) -> Bool {
        return lhs.id.unsafelyUnwrapped == rhs.id.unsafelyUnwrapped
    }
}

class Wall: Identifiable {
    var id: Int64?
    var imageData: Data
    var width: Double
    var height: Double
    var name: String = ""
    
    // Relationships
    private var _holds: [Hold]? = nil
    private var _climbs: [Climb]? = nil
    
    var holds: [Hold] {
        if let holds = _holds {
            return holds
        }
        
        // Load holds if id exists
        if let id = id {
            _holds = DatabaseManager.shared.getHoldsForWall(wallId: id)
            return _holds ?? []
        }
        
        return []
    }
    
    var climbs: [Climb] {
        if let climbs = _climbs {
            return climbs
        }
        
        // Load climbs if id exists
        if let id = id {
            _climbs = DatabaseManager.shared.getClimbsForWall(wallId: id)
            return _climbs ?? []
        }
        
        return []
    }
    
    init(imageData: Data, width: Double, height: Double, name: String) {
        self.imageData = imageData
        self.width = width
        self.height = height
        self.name = name
    }
    
    func addHold(hold: Hold) {
        if self.id == nil {
            fatalError("wall id is nil")
        }

        if hold.id == nil {
            // Save hold to database
            let holdId = DatabaseManager.shared.saveHold(hold: hold, wallId: self.id.unsafelyUnwrapped)
            hold.id = holdId
        }

        // Add to in-memory collection
        if _holds == nil {
            _holds = []
        }
        _holds?.append(hold)
    }
    
    func addClimb(climb: Climb) {
        climb.validate()
        
        if climb.id == nil {
            // Save climb to database
            if let wallID = id {
                climb.wallID = wallID
                let climbId = DatabaseManager.shared.saveClimb(climb: climb)
                climb.id = climbId
            }
        }
        
        // Add to in-memory collection
        if _climbs == nil {
            _climbs = []
        }
        _climbs?.append(climb)
    }
    
    func deleteHold(index: Int) {
        if index < 0 || index >= holds.count {
            fatalError("invalid hold index: \(index)")
        }
        
        if climbs.count > 0 {
            fatalError("cannot delete hold when wall already has climbs")
        }
        
        let hold = holds[index]
        
        // Delete from database if it exists
        if let holdId = hold.id {
            DatabaseManager.shared.deleteHold(holdId: holdId)
        } else {
            fatalError("hold has no id")
        }

        // Remove from in-memory collection
        _holds?.remove(at: index)
    }
    
    func save() -> Int64 {
        let id = DatabaseManager.shared.saveWall(wall: self)
        self.id = id
        return id
    }
}

let maxStartHolds = 4
let maxFinishHolds = 2

class ClimbHold {
    var id: Int64?
    weak var climb: Climb?
    var hold: Hold
    var holdType: HoldType
    
    init(climb: Climb, hold: Hold, holdType: HoldType) {
        self.climb = climb
        self.hold = hold
        self.holdType = holdType
    }
}

class Climb: Identifiable {
    var id: Int64?
    var name: String
    var grade: Grade
    var wallID: Int64
    var desc: String

    // Relationships
    private var _climbHolds: [ClimbHold]? = nil
    
    func wall() -> Wall {
        DatabaseManager.shared.getWall(id: wallID).unsafelyUnwrapped
    }

    var climbHolds: [ClimbHold] {
        if let climbHolds = _climbHolds {
            return climbHolds
        }
        
        // Load climbHolds if id exists
        if let id = id {
            _climbHolds = DatabaseManager.shared.getClimbHoldsForClimb(climbId: id)
            return _climbHolds ?? []
        }
        
        return []
    }
    
    init(name: String, grade: Grade, wallID: Int64, desc: String) {
        if name.isEmpty {
            fatalError("climb name cannot be empty")
        }
        
        self.name = name
        self.grade = grade
        self.wallID = wallID
        self.desc = desc
    }

    func addHold(hold: Hold, holdType: HoldType) {
        guard let holdId = hold.id else {
            fatalError("Hold must be saved before adding to a climb")
        }
        
        let climbHold = ClimbHold(climb: self, hold: hold, holdType: holdType)
        
        // Save to database if the climb exists
        if let climbId = id {
            let climbHoldId = DatabaseManager.shared.saveClimbHold(climbHold: climbHold, climbId: climbId, holdId: holdId)
            climbHold.id = climbHoldId
        }
        
        // Add to in-memory collection
        if _climbHolds == nil {
            _climbHolds = []
        }
        _climbHolds?.append(climbHold)
    }
    
    func setHolds(holds: [Hold], holdTypes: [HoldType]) {
        if holdTypes.count != holds.count {
            fatalError("invalid len holds/holdTypes")
        }
        
        let wall = DatabaseManager.shared.getWall(id: wallID).unsafelyUnwrapped
        
        for hold in holds {
            if !wall.holds.contains(where: { $0.id == hold.id }) {
                fatalError("hold not contained in wall")
            }
        }
        
        // Clear existing relationships
        _climbHolds = []
        
        // Create new relationships preserving order
        for i in 0..<holds.count {
            self.addHold(hold: holds[i], holdType: holdTypes[i])
        }
    }
    
    func validate() {
        if name.isEmpty {
            fatalError("climb name cannot be empty")
        }
        
        let wall = DatabaseManager.shared.getWall(id: wallID).unsafelyUnwrapped

        for climbHold in climbHolds {
            if !wall.holds.contains(where: { $0.id == climbHold.hold.id }) {
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
    
    func save() -> Int64 {
        let id = DatabaseManager.shared.saveClimb(climb: self)
        self.id = id
        return id
    }
}

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: OpaquePointer?

    private init() {
        do {
            // Create or open the database
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let dbPath = "\(path)/bored.climb.sqlite3"
            
            // Open database connection
            if sqlite3_open(dbPath, &db) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                throw NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error opening database: \(errmsg)"])
            }
            
            // Enable foreign keys
            if sqlite3_exec(db, "PRAGMA foreign_keys = ON", nil, nil, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                throw NSError(domain: "DatabaseManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error enabling foreign keys: \(errmsg)"])
            }
            
            // Initialize the database schema from SQL file
            try initializeDatabase()
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    private func initializeDatabase() throws {
        // Check if database is already initialized by checking for Wall table
        var stmt: OpaquePointer?
        let query = "SELECT EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'Wall')"
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            throw NSError(domain: "DatabaseManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Error checking table existence: \(errmsg)"])
        }
        
        defer {
            sqlite3_finalize(stmt)
        }
        
        if sqlite3_step(stmt) == SQLITE_ROW && sqlite3_column_int(stmt, 0) == 0 {
            // Database not initialized, load schema from SQL file
            if let schemaPath = Bundle.main.path(forResource: "schema", ofType: "sql"),
               let schemaSQL = try? String(contentsOfFile: schemaPath, encoding: .utf8) {
                
                // Split SQL statements and execute them individually
                let statements = schemaSQL.components(separatedBy: ";")
                
                for statement in statements where !statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if sqlite3_exec(db, statement, nil, nil, nil) != SQLITE_OK {
                        let errmsg = String(cString: sqlite3_errmsg(db)!)
                        throw NSError(domain: "DatabaseManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Error executing SQL: \(errmsg)"])
                    }
                }
                
                print("Database initialized from schema.sql")
            } else {
                fatalError("Schema SQL file not found")
            }
        }
    }
    
    // MARK: - Wall Operations
    
    func saveWall(wall: Wall) -> Int64 {
        var query: String
        var statement: OpaquePointer?
        
        if let id = wall.id {
            // Update existing wall
            query = "UPDATE Wall SET imageData = ?, width = ?, height = ?, name = ? WHERE id = ?"
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                fatalError("Error preparing update statement: \(errmsg)")
            }
            
            sqlite3_bind_blob(statement, 1, [UInt8](wall.imageData), Int32(wall.imageData.count), SQLITE_TRANSIENT)
            sqlite3_bind_double(statement, 2, wall.width)
            sqlite3_bind_double(statement, 3, wall.height)
            sqlite3_bind_text(statement, 4, (wall.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int64(statement, 5, id)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                fatalError("Error updating wall: \(errmsg)")
            }
            
            sqlite3_finalize(statement)
            return id
        } else {
            // Insert new wall
            query = "INSERT INTO Wall (imageData, width, height, name) VALUES (?, ?, ?, ?)"
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                fatalError("Error preparing insert statement: \(errmsg)")
            }
            
            sqlite3_bind_blob(statement, 1, [UInt8](wall.imageData), Int32(wall.imageData.count), SQLITE_TRANSIENT)
            sqlite3_bind_double(statement, 2, wall.width)
            sqlite3_bind_double(statement, 3, wall.height)
            sqlite3_bind_text(statement, 4, (wall.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                fatalError("Error inserting wall: \(errmsg)")
            }
            
            let id = sqlite3_last_insert_rowid(db)
            sqlite3_finalize(statement)
            return id
        }
    }
    
    func getWall(id: Int64) -> Wall? {
        let query = "SELECT id, imageData, width, height, name FROM Wall WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing select statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, id)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            
            let blobPointer = sqlite3_column_blob(statement, 1)
            let blobSize = sqlite3_column_bytes(statement, 1)
            let imageData = Data(bytes: blobPointer!, count: Int(blobSize))
            
            let width = sqlite3_column_double(statement, 2)
            let height = sqlite3_column_double(statement, 3)
            
            let namePtr = sqlite3_column_text(statement, 4)
            let name = namePtr != nil ? String(cString: namePtr!) : ""
            
            let wall = Wall(imageData: imageData, width: width, height: height, name: name)
            wall.id = id
            return wall
        }
        
        return nil
    }
    
    func getAllWalls() -> [Wall] {
        let query = "SELECT id, imageData, width, height, name FROM Wall"
        var statement: OpaquePointer?
        var walls = [Wall]()
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing select statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            
            let blobPointer = sqlite3_column_blob(statement, 1)
            let blobSize = sqlite3_column_bytes(statement, 1)
            let imageData = Data(bytes: blobPointer!, count: Int(blobSize))
            
            let width = sqlite3_column_double(statement, 2)
            let height = sqlite3_column_double(statement, 3)
            
            let namePtr = sqlite3_column_text(statement, 4)
            let name = namePtr != nil ? String(cString: namePtr!) : ""
            
            let wall = Wall(imageData: imageData, width: width, height: height, name: name)
            wall.id = id
            walls.append(wall)
        }
        
        return walls
    }
    
    func deleteWall(id: Int64) {
        let query = "DELETE FROM Wall WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing delete statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, id)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error deleting wall: \(errmsg)")
        }
    }
    
    // MARK: - Hold Operations
    
    func saveHold(hold: Hold, wallId: Int64) -> Int64 {
        // Begin transaction
        if sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error beginning transaction: \(errmsg)")
        }
        
        do {
            var holdId: Int64
            
            if let id = hold.id {
                // Hold already exists, just use its ID
                holdId = id
            } else {
                // Insert new hold
                let query = "INSERT INTO Hold (wall_id) VALUES (?)"
                var statement: OpaquePointer?
                
                if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    throw NSError(domain: "DatabaseManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Error preparing insert statement: \(errmsg)"])
                }
                
                sqlite3_bind_int64(statement, 1, wallId)
                
                if sqlite3_step(statement) != SQLITE_DONE {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    throw NSError(domain: "DatabaseManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "Error inserting hold: \(errmsg)"])
                }
                
                holdId = sqlite3_last_insert_rowid(db)
                sqlite3_finalize(statement)
            }
            
            // Delete existing points (if updating)
            let deleteQuery = "DELETE FROM HoldPoint WHERE hold_id = ?"
            var deleteStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, deleteQuery, -1, &deleteStatement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                throw NSError(domain: "DatabaseManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "Error preparing delete statement: \(errmsg)"])
            }
            
            sqlite3_bind_int64(deleteStatement, 1, holdId)
            
            if sqlite3_step(deleteStatement) != SQLITE_DONE {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                throw NSError(domain: "DatabaseManager", code: 8, userInfo: [NSLocalizedDescriptionKey: "Error deleting hold points: \(errmsg)"])
            }
            
            sqlite3_finalize(deleteStatement)
            
            // Insert points
            let insertQuery = "INSERT INTO HoldPoint (hold_id, x, y, point_order) VALUES (?, ?, ?, ?)"
            
            for (index, point) in hold.points.enumerated() {
                var insertStatement: OpaquePointer?
                
                if sqlite3_prepare_v2(db, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    throw NSError(domain: "DatabaseManager", code: 9, userInfo: [NSLocalizedDescriptionKey: "Error preparing insert statement: \(errmsg)"])
                }
                
                sqlite3_bind_int64(insertStatement, 1, holdId)
                sqlite3_bind_double(insertStatement, 2, point.x)
                sqlite3_bind_double(insertStatement, 3, point.y)
                sqlite3_bind_int(insertStatement, 4, Int32(index))
                
                if sqlite3_step(insertStatement) != SQLITE_DONE {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    throw NSError(domain: "DatabaseManager", code: 10, userInfo: [NSLocalizedDescriptionKey: "Error inserting hold point: \(errmsg)"])
                }
                
                sqlite3_finalize(insertStatement)
            }
            
            // Commit transaction
            if sqlite3_exec(db, "COMMIT", nil, nil, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                throw NSError(domain: "DatabaseManager", code: 11, userInfo: [NSLocalizedDescriptionKey: "Error committing transaction: \(errmsg)"])
            }
            
            return holdId
        } catch {
            // Rollback transaction on error
            sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
            fatalError("Failed to save hold: \(error)")
        }
    }
    
    func getHoldsForWall(wallId: Int64) -> [Hold] {
        var result = [Hold]()
        
        // Query holds for this wall
        let query = "SELECT id FROM Hold WHERE wall_id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing select statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, wallId)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let holdId = sqlite3_column_int64(statement, 0)
            
            // Get points for this hold
            let pointsQuery = "SELECT x, y FROM HoldPoint WHERE hold_id = ? ORDER BY point_order"
            var pointsStatement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, pointsQuery, -1, &pointsStatement, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                fatalError("Error preparing select statement: \(errmsg)")
            }
            
            defer {
                sqlite3_finalize(pointsStatement)
            }
            
            sqlite3_bind_int64(pointsStatement, 1, holdId)
            
            var points = [Point]()
            
            while sqlite3_step(pointsStatement) == SQLITE_ROW {
                let x = sqlite3_column_double(pointsStatement, 0)
                let y = sqlite3_column_double(pointsStatement, 1)
                
                let point = Point(x: x, y: y)
                points.append(point)
            }
            
            if points.count >= 3 {
                let hold = Hold(id: holdId, points: points)
                result.append(hold)
            }
        }
        
        return result
    }
    
    func deleteHold(holdId: Int64) {
        let query = "DELETE FROM Hold WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing delete statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, holdId)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error deleting hold: \(errmsg)")
        }
    }
    
    // MARK: - Climb Operations
    
    func saveClimb(climb: Climb) -> Int64 {
        // Begin transaction
        if sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error beginning transaction: \(errmsg)")
        }

        let wall = getWall(id: climb.wallID).unsafelyUnwrapped
        
        do {
            var climbId: Int64
            
            if let id = climb.id {
                // Update
                let query = "UPDATE Climb SET name = ?, grade = ?, wall_id = ?, description = ? WHERE id = ?"
                var statement: OpaquePointer?
                
                if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    throw NSError(domain: "DatabaseManager", code: 13, userInfo: [NSLocalizedDescriptionKey: "Error preparing update statement: \(errmsg)"])
                }
                
                sqlite3_bind_text(statement, 1, (climb.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(statement, 2, Int32(climb.grade.rawValue))
                sqlite3_bind_int64(statement, 3, wall.id.unsafelyUnwrapped)
                sqlite3_bind_text(statement, 4, (climb.desc as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int64(statement, 5, id)

                if sqlite3_step(statement) != SQLITE_DONE {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    throw NSError(domain: "DatabaseManager", code: 14, userInfo: [NSLocalizedDescriptionKey: "Error updating climb: \(errmsg)"])
                }
                
                sqlite3_finalize(statement)
                climbId = id
            } else {
                // Insert
                let query = "INSERT INTO Climb (name, grade, wall_id, description) VALUES (?, ?, ?, ?)"
                var statement: OpaquePointer?
                
                if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    throw NSError(domain: "DatabaseManager", code: 15, userInfo: [NSLocalizedDescriptionKey: "Error preparing insert statement: \(errmsg)"])
                }
                
                sqlite3_bind_text(statement, 1, (climb.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(statement, 2, Int32(climb.grade.rawValue))
                sqlite3_bind_int64(statement, 3, wall.id.unsafelyUnwrapped)
                sqlite3_bind_text(statement, 4, (climb.desc as NSString).utf8String, -1, SQLITE_TRANSIENT)

                if sqlite3_step(statement) != SQLITE_DONE {
                    let errmsg = String(cString: sqlite3_errmsg(db)!)
                    throw NSError(domain: "DatabaseManager", code: 16, userInfo: [NSLocalizedDescriptionKey: "Error inserting climb: \(errmsg)"])
                }
                
                climbId = sqlite3_last_insert_rowid(db)
                sqlite3_finalize(statement)
                climb.id = climbId
            }
            
            // Now handle climbHolds
            for climbHold in climb.climbHolds {
                if climbHold.id == nil {
                    guard let holdId = climbHold.hold.id else {
                        throw NSError(domain: "DatabaseManager", code: 17, userInfo: [NSLocalizedDescriptionKey: "Hold must be saved before adding to a climb"])
                    }
                    
                    _ = saveClimbHold(climbHold: climbHold, climbId: climbId, holdId: holdId)
                }
            }
            
            // Commit transaction
            if sqlite3_exec(db, "COMMIT", nil, nil, nil) != SQLITE_OK {
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                throw NSError(domain: "DatabaseManager", code: 18, userInfo: [NSLocalizedDescriptionKey: "Error committing transaction: \(errmsg)"])
            }
            
            return climbId
        } catch {
            // Rollback transaction on error
            sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
            fatalError("Failed to save climb: \(error)")
        }
    }
    
    func saveClimbHold(climbHold: ClimbHold, climbId: Int64, holdId: Int64) -> Int64 {
        // Determine the next order
        let orderQuery = "SELECT COALESCE(MAX(hold_order), -1) + 1 FROM ClimbHold WHERE climb_id = ?"
        var orderStatement: OpaquePointer?
        var nextOrder: Int32 = 0
        
        if sqlite3_prepare_v2(db, orderQuery, -1, &orderStatement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing select statement: \(errmsg)")
        }
        
        sqlite3_bind_int64(orderStatement, 1, climbId)
        
        if sqlite3_step(orderStatement) == SQLITE_ROW {
            nextOrder = sqlite3_column_int(orderStatement, 0)
        }
        
        sqlite3_finalize(orderStatement)
        
        // Insert climb hold
        let query = "INSERT INTO ClimbHold (climb_id, hold_id, hold_type, hold_order) VALUES (?, ?, ?, ?)"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing insert statement: \(errmsg)")
        }
        
        sqlite3_bind_int64(statement, 1, climbId)
        sqlite3_bind_int64(statement, 2, holdId)
        sqlite3_bind_int(statement, 3, Int32(climbHold.holdType.rawValue))
        sqlite3_bind_int(statement, 4, nextOrder)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error inserting climb hold: \(errmsg)")
        }
        
        let id = sqlite3_last_insert_rowid(db)
        sqlite3_finalize(statement)
        return id
    }
    
    func getClimbsForWall(wallId: Int64) -> [Climb] {
        var result = [Climb]()
        
        // Get wall
        guard let wall = getWall(id: wallId) else {
            return []
        }
        
        // Query climbs for this wall
        let query = "SELECT id, name, grade, description FROM Climb WHERE wall_id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing select statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, wallId)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let climbId = sqlite3_column_int64(statement, 0)
            
            let namePtr = sqlite3_column_text(statement, 1)
            let name = namePtr != nil ? String(cString: namePtr!) : ""
            
            let gradeInt = sqlite3_column_int(statement, 2)
            let grade = Grade(rawValue: Int(gradeInt)) ?? .proj
            
            let descPtr = sqlite3_column_text(statement, 3)
            let desc = descPtr != nil ? String(cString: descPtr!) : ""
            
            let climb = Climb(name: name, grade: grade, wallID: wall.id.unsafelyUnwrapped, desc: desc)
            climb.id = climbId
            
            result.append(climb)
        }
        
        return result
    }
    
    func getClimbHoldsForClimb(climbId: Int64) -> [ClimbHold] {
        var result = [ClimbHold]()
        
        // Get climb
        let climbQuery = "SELECT c.id, c.name, c.grade, c.description, c.wall_id FROM Climb c WHERE c.id = ?"
        var climbStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, climbQuery, -1, &climbStatement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing select statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(climbStatement)
        }
        
        sqlite3_bind_int64(climbStatement, 1, climbId)
        
        guard sqlite3_step(climbStatement) == SQLITE_ROW else {
            return []
        }
        
        let wallId = sqlite3_column_int64(climbStatement, 4)
        guard let wall = getWall(id: wallId) else {
            return []
        }
        
        let namePtr = sqlite3_column_text(climbStatement, 1)
        let name = namePtr != nil ? String(cString: namePtr!) : ""
        
        let gradeInt = sqlite3_column_int(climbStatement, 2)
        let grade = Grade(rawValue: Int(gradeInt)) ?? .proj
        
        let descPtr = sqlite3_column_text(climbStatement, 3)
        let desc = descPtr != nil ? String(cString: descPtr!) : ""
        
        let climb = Climb(name: name, grade: grade, wallID: wall.id.unsafelyUnwrapped, desc: desc)
        climb.id = climbId

        // Get all holds for this wall (for reference)
        let allHolds = getHoldsForWall(wallId: wallId)
        let holdsDict = Dictionary(uniqueKeysWithValues: allHolds.map { ($0.id!, $0) })
        
        // Query climbHolds for this climb
        let query = "SELECT id, hold_id, hold_type FROM ClimbHold WHERE climb_id = ? ORDER BY hold_order"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing select statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, climbId)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let climbHoldId = sqlite3_column_int64(statement, 0)
            let holdId = sqlite3_column_int64(statement, 1)
            let holdTypeInt = sqlite3_column_int(statement, 2)
            
            guard let hold = holdsDict[holdId] else {
                continue // Skip if hold doesn't exist
            }
            
            let holdType = HoldType(rawValue: Int(holdTypeInt)) ?? .middle
            
            let climbHold = ClimbHold(climb: climb, hold: hold, holdType: holdType)
            climbHold.id = climbHoldId
            
            result.append(climbHold)
        }
        
        return result
    }
    
    func deleteClimb(id: Int64) {
        let query = "DELETE FROM Climb WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error preparing delete statement: \(errmsg)")
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_int64(statement, 1, id)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error deleting climb: \(errmsg)")
        }
    }
}
