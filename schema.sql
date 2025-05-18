-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Wall table
CREATE TABLE IF NOT EXISTS Wall (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    imageData BLOB NOT NULL,
    width REAL NOT NULL,
    height REAL NOT NULL,
    name TEXT NOT NULL
);

-- Hold table
CREATE TABLE IF NOT EXISTS Hold (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    wall_id INTEGER NOT NULL,
    FOREIGN KEY (wall_id) REFERENCES Wall(id) ON DELETE CASCADE
);

-- HoldPoint table
CREATE TABLE IF NOT EXISTS HoldPoint (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hold_id INTEGER NOT NULL,
    x REAL NOT NULL,
    y REAL NOT NULL,
    point_order INTEGER NOT NULL,
    FOREIGN KEY (hold_id) REFERENCES Hold(id) ON DELETE CASCADE
);

-- Climb table
CREATE TABLE IF NOT EXISTS Climb (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    grade INTEGER NOT NULL,
    wall_id INTEGER NOT NULL,
    description TEXT,
    FOREIGN KEY (wall_id) REFERENCES Wall(id) ON DELETE CASCADE
);

-- ClimbHold table
CREATE TABLE IF NOT EXISTS ClimbHold (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    climb_id INTEGER NOT NULL,
    hold_id INTEGER NOT NULL,
    hold_type INTEGER NOT NULL,
    hold_order INTEGER NOT NULL,
    FOREIGN KEY (climb_id) REFERENCES Climb(id) ON DELETE CASCADE,
    FOREIGN KEY (hold_id) REFERENCES Hold(id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_hold_wall_id ON Hold(wall_id);
CREATE INDEX IF NOT EXISTS idx_hold_point_hold_id ON HoldPoint(hold_id);
CREATE INDEX IF NOT EXISTS idx_climb_wall_id ON Climb(wall_id);
CREATE INDEX IF NOT EXISTS idx_climb_hold_climb_id ON ClimbHold(climb_id);
CREATE INDEX IF NOT EXISTS idx_climb_hold_hold_id ON ClimbHold(hold_id);



