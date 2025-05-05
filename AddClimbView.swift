import SwiftUI

// The add climbs flow:
//
// 1. Start with AddClimbView. Allows users to tap and select holds for the climb.
// 2. Transition to SelectStartHoldView on next. Allows user to tap and select the
//    start holds.
// 3. Transition to SelectFinishHoldView on next. Allows user to tap and select the
//    finish holds.
// 4. Transition to FinishClimbView on next. Allows user to name the climb
//    assign it a grade, and add a description.
struct AddClimbView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var nav: NavigationStateManager

    var wall: Wall

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedHolds: [Hold] = []

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                VStack(spacing: 0) {
                    GeometryReader { containerGeo in
                        ZStack(alignment: .topLeading) {
                            if let uiImage = UIImage(data: wall.imageData) {
                                GeometryReader { imageGeo in
                                    let containerSize = containerGeo.size
                                    let baseFrame = imageGeo.frame(in: .global)

                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(scale)
                                        .offset(imageOffset)
                                        .frame(
                                            width: containerSize.width,
                                            height: containerSize.height
                                        )
                                        .clipped()
                                        .overlay(
                                            PolygonView(
                                                polygons: selectedHolds.map { $0.points },
                                                containerSize: containerSize,
                                                imageSize: uiImage.size,
                                                scale: scale,
                                                offset: imageOffset,
                                                drawCircle: false,
                                                holdTypes: []
                                            )
                                        )
                                        .background(
                                            Color.clear
                                                .onAppear {}
                                                .onChange(of: scale) { _, newScale in
                                                    imageOffset = clampedOffset(
                                                        offset: imageOffset,
                                                        scale: newScale,
                                                        containerSize: containerSize,
                                                        imageSize: baseFrame.size
                                                    )
                                                    lastOffset = imageOffset
                                                }
                                        )
                                        .overlay(
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .onTapGesture { containerLoc in
                                                    // Convert container coordinates to image coordinates
                                                    let relativeTapPoint = convertToImageCoordinates(
                                                        containerPoint: containerLoc,
                                                        containerSize: containerSize,
                                                        imageSize: uiImage.size,
                                                        scale: scale,
                                                        offset: imageOffset
                                                    )
                                                    
                                                    // Find all holds that contain the tapped point
                                                    let tappedHolds = wall.holds.filter { hold in
                                                        isPointInPolygon(point: relativeTapPoint, points: hold.points)
                                                    }
                                                    
                                                    print("Tapped coordinates: \(relativeTapPoint)")
                                                    print("Overlapping holds found: \(tappedHolds.count)")
                                                    
                                                    if !tappedHolds.isEmpty {
                                                        // Add each tapped hold to the selection
                                                        for hold in tappedHolds {
                                                            // If the hold is not already selected, add it
                                                            if !selectedHolds.contains(where: { $0.id == hold.id }) {
                                                                selectedHolds.append(hold)
                                                            } else {
                                                                // If the hold is already selected, you could optionally deselect it
                                                                 selectedHolds.removeAll(where: { $0.id == hold.id })
                                                            }
                                                        }
                                                    }
                                                }
                                        )
                                }
                            } else {
                                fatalError("wall must have an image")
                            }
                        }
                        .background(Color.black.ignoresSafeArea())
                    }
                }
                .background(Color.black)

                VStack {
                    HStack {
                        Button(action: {
                            // This will do nothing for now
                            // Add view dismissal code here when needed
                            print("Cancel button tapped")
                            saveContext(context: context)
                            nav.removeLast()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .cornerRadius(8)
                        }
                        .padding()

                        Spacer()

                        // TODO: Make sure this is centrally aligned.
                        Text("Tap to select holds")
                            .font(.custom("tiny", size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                        
                        Spacer()

                        ZStack {
                            // Invisible placeholder with same size as Next button. This is so that
                            // the previous text stays aligned.
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.clear) // Invisible
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .opacity(0)

                            // Actual Next button
                            if selectedHolds.count > 0 {
                                Button(action: {
                                    print("Next button tapped")
                                    nav.selectionPath.append(NavToSelectStartHoldView(wall: wall, selectedHolds: selectedHolds, viewID: "select_start_hold_view"))
                                }) {
                                    Text("Next")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            // Add the gestures directly to the ZStack to ensure they work with the modal
            .gesture(
                SimultaneousGesture(
                    // Magnification gesture to handle zooming
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(1.0, lastScale * value), 10.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        },
                    // Drag gesture for panning
                    DragGesture()
                        .onChanged { value in
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            imageOffset = clampedOffset(
                                offset: newOffset,
                                scale: scale,
                                containerSize: geometryProxy.size,
                                imageSize: CGSize(width: wall.width, height: wall.height)
                            )
                        }
                        .onEnded { _ in
                            lastOffset = imageOffset
                        }
                )
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavToSelectStartHoldView.self) { navWall in
            SelectStartHoldView(wall: navWall.wall, selectedHolds: navWall.selectedHolds)
        }
    }
}

struct SelectStartHoldView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var nav: NavigationStateManager

    var wall: Wall
    var selectedHolds: [Hold]

    @State private var holdTypes: [HoldType]
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    init(wall: Wall, selectedHolds: [Hold]) {
        self.wall = wall
        self.selectedHolds = selectedHolds
        
        var tempHoldTypes: [HoldType] = []
        for _ in selectedHolds {
            tempHoldTypes.append(.middle)
        }
        
        // Assign to the @State property
        _holdTypes = State(initialValue: tempHoldTypes)
        
        if selectedHolds.count != holdTypes.count {
            fatalError("hold type invariant not met")
        }
    }

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                VStack(spacing: 0) {
                    GeometryReader { containerGeo in
                        ZStack(alignment: .topLeading) {
                            if let uiImage = UIImage(data: wall.imageData) {
                                GeometryReader { imageGeo in
                                    let containerSize = containerGeo.size
                                    let baseFrame = imageGeo.frame(in: .global)

                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(scale)
                                        .offset(imageOffset)
                                        .frame(
                                            width: containerSize.width,
                                            height: containerSize.height
                                        )
                                        .clipped()
                                        .overlay(
                                            PolygonView(
                                                polygons: selectedHolds.map { $0.points },
                                                containerSize: containerSize,
                                                imageSize: uiImage.size,
                                                scale: scale,
                                                offset: imageOffset,
                                                drawCircle: false,
                                                holdTypes: holdTypes
                                            )
                                        )
                                        .background(
                                            Color.clear
                                                .onAppear {}
                                                .onChange(of: scale) { _, newScale in
                                                    imageOffset = clampedOffset(
                                                        offset: imageOffset,
                                                        scale: newScale,
                                                        containerSize: containerSize,
                                                        imageSize: baseFrame.size
                                                    )
                                                    lastOffset = imageOffset
                                                }
                                        )
                                        .overlay(
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .onTapGesture { containerLoc in
                                                    // Convert container coordinates to image coordinates
                                                    let relativeTapPoint = convertToImageCoordinates(
                                                        containerPoint: containerLoc,
                                                        containerSize: containerSize,
                                                        imageSize: uiImage.size,
                                                        scale: scale,
                                                        offset: imageOffset
                                                    )
                                                    
                                                    // Out of all selected holds, which ones were just tapped.
                                                    let tappedHolds = selectedHolds.filter { hold in
                                                        isPointInPolygon(point: relativeTapPoint, points: hold.points)
                                                    }
                                                    
                                                    print("Tapped coordinates: \(relativeTapPoint)")
                                                    print("Overlapping holds found: \(tappedHolds.count)")
                                                    print("htcount is \(holdTypes.count)")
                                                    
                                                    if !tappedHolds.isEmpty {
                                                        // Add each tapped hold to the selection
                                                        for hold in tappedHolds {
                                                            // Get all indices of the tapped hold in the selectedHolds array
                                                            let matchingIndices = selectedHolds.indices.filter { selectedHolds[$0] == hold }
                                                            
                                                            for index in matchingIndices {
                                                                // If this hold is already marked as .start, flip it to .middle
                                                                if holdTypes[index] == .start {
                                                                    holdTypes[index] = .middle
                                                                } else {
                                                                    // Count how many holds are already marked as .start
                                                                    let currentStartCount = holdTypes.filter { $0 == .start }.count
                                                                    
                                                                    if currentStartCount < maxStartHolds {
                                                                        holdTypes[index] = .start
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                        )
                                }
                            } else {
                                fatalError("wall must have an image")
                            }
                        }
                        .background(Color.black.ignoresSafeArea())
                    }
                }
                .background(Color.black)

                VStack {
                    HStack {
                        Button(action: {
                            // This will do nothing for now
                            // Add view dismissal code here when needed
                            print("Cancel button tapped")
                            nav.removeLast()
                        }) {
                            // TODO: try chevron left.
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .cornerRadius(8)
                        }
                        .padding()

                        Spacer()

                        // TODO: Make sure this is centrally aligned.
                        Text("Select upto 4 start holds")
                            .font(.custom("tiny", size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                        
                        Spacer()

                        ZStack {
                            // Invisible placeholder with same size as Next button. This is so that
                            // the previous text stays aligned.
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.clear) // Invisible
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .opacity(0)
                            
                            let currentStartCount = holdTypes.filter { $0 == .start }.count
                            if currentStartCount > 0 {
                                Button(action: {
                                    print("Next button tapped")
                                    nav.selectionPath.append(NavToSelectFinishHoldView(wall: wall, selectedHolds: selectedHolds, holdTypes: holdTypes, viewID: "finish_hold_view"))
                                }) {
                                    Text("Next")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            // Add the gestures directly to the ZStack to ensure they work with the modal
            .gesture(
                SimultaneousGesture(
                    // Magnification gesture to handle zooming
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(1.0, lastScale * value), 10.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        },
                    // Drag gesture for panning
                    DragGesture()
                        .onChanged { value in
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            imageOffset = clampedOffset(
                                offset: newOffset,
                                scale: scale,
                                containerSize: geometryProxy.size,
                                imageSize: CGSize(width: wall.width, height: wall.height)
                            )
                        }
                        .onEnded { _ in
                            lastOffset = imageOffset
                        }
                )
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavToSelectFinishHoldView.self) { navWall in
            SelectFinishHoldView(wall: navWall.wall, selectedHolds: navWall.selectedHolds, holdTypes: navWall.holdTypes)
        }
    }
}

struct SelectFinishHoldView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var nav: NavigationStateManager

    var wall: Wall
    var selectedHolds: [Hold]
    @State private var holdTypes: [HoldType]

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    init(wall: Wall, selectedHolds: [Hold], holdTypes: [HoldType]) {
        self.wall = wall
        self.selectedHolds = selectedHolds
        self._holdTypes = State(initialValue: holdTypes)
        
        if selectedHolds.count != holdTypes.count {
            fatalError("hold type invariant not met")
        }
    }

    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                VStack(spacing: 0) {
                    GeometryReader { containerGeo in
                        ZStack(alignment: .topLeading) {
                            if let uiImage = UIImage(data: wall.imageData) {
                                GeometryReader { imageGeo in
                                    let containerSize = containerGeo.size
                                    let baseFrame = imageGeo.frame(in: .global)

                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(scale)
                                        .offset(imageOffset)
                                        .frame(
                                            width: containerSize.width,
                                            height: containerSize.height
                                        )
                                        .clipped()
                                        .overlay(
                                            PolygonView(
                                                polygons: selectedHolds.map { $0.points },
                                                containerSize: containerSize,
                                                imageSize: uiImage.size,
                                                scale: scale,
                                                offset: imageOffset,
                                                drawCircle: false,
                                                holdTypes: holdTypes
                                            )
                                        )
                                        .background(
                                            Color.clear
                                                .onAppear {}
                                                .onChange(of: scale) { _, newScale in
                                                    imageOffset = clampedOffset(
                                                        offset: imageOffset,
                                                        scale: newScale,
                                                        containerSize: containerSize,
                                                        imageSize: baseFrame.size
                                                    )
                                                    lastOffset = imageOffset
                                                }
                                        )
                                        .overlay(
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .onTapGesture { containerLoc in
                                                    // Convert container coordinates to image coordinates
                                                    let relativeTapPoint = convertToImageCoordinates(
                                                        containerPoint: containerLoc,
                                                        containerSize: containerSize,
                                                        imageSize: uiImage.size,
                                                        scale: scale,
                                                        offset: imageOffset
                                                    )
                                                    
                                                    // Out of all selected holds, which ones were just tapped.
                                                    let tappedHolds = selectedHolds.filter { hold in
                                                        isPointInPolygon(point: relativeTapPoint, points: hold.points)
                                                    }
                                                    
                                                    print("Tapped coordinates: \(relativeTapPoint)")
                                                    print("Overlapping holds found: \(tappedHolds.count)")
                                                    print("htcount is \(holdTypes.count)")
                                                    
                                                    if !tappedHolds.isEmpty {
                                                        // Add each tapped hold to the selection
                                                        for hold in tappedHolds {
                                                            // Get all indices of the tapped hold in the selectedHolds array
                                                            let matchingIndices = selectedHolds.indices.filter { selectedHolds[$0] == hold }
                                                            
                                                            for index in matchingIndices {
                                                                // If this hold is already marked as .finish, flip it to .middle
                                                                if holdTypes[index] == .finish {
                                                                    holdTypes[index] = .middle
                                                                } else if holdTypes[index] == .middle {
                                                                    // Count how many holds are already marked as .finish
                                                                    let currentFinishCount = holdTypes.filter { $0 == .finish }.count
                                                                    if currentFinishCount < maxFinishHolds {
                                                                        holdTypes[index] = .finish
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                        )
                                }
                            } else {
                                fatalError("wall must have an image")
                            }
                        }
                        .background(Color.black.ignoresSafeArea())
                    }
                }
                .background(Color.black)

                VStack {
                    HStack {
                        Button(action: {
                            // This will do nothing for now
                            // Add view dismissal code here when needed
                            print("Cancel button tapped")
                            saveContext(context: context)
                            nav.removeLast()
                        }) {
                            // TODO: try chevron left.
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .cornerRadius(8)
                        }
                        .padding()

                        Spacer()

                        // TODO: Make sure this is centrally aligned.
                        Text("Select upto 2 finish holds. Cannot be same as start.")
                            .font(.custom("tiny", size: 14))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                        
                        Spacer()

                        ZStack {
                            // Invisible placeholder with same size as Next button. This is so that
                            // the previous text stays aligned.
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.clear) // Invisible
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .opacity(0)
                            
                            let currentFinishCount = holdTypes.filter { $0 == .finish }.count
                            if currentFinishCount > 0 {
                                Button(action: {
                                    print("Next button tapped")
                                    nav.selectionPath.append(NavToFinishClimbView(wall: wall, selectedHolds: selectedHolds, holdTypes: holdTypes, viewID: "finish_climb_view"))
                                }) {
                                    Text("Next")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            // Add the gestures directly to the ZStack to ensure they work with the modal
            .gesture(
                SimultaneousGesture(
                    // Magnification gesture to handle zooming
                    MagnificationGesture()
                        .onChanged { value in
                            scale = min(max(1.0, lastScale * value), 10.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        },
                    // Drag gesture for panning
                    DragGesture()
                        .onChanged { value in
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            imageOffset = clampedOffset(
                                offset: newOffset,
                                scale: scale,
                                containerSize: geometryProxy.size,
                                imageSize: CGSize(width: wall.width, height: wall.height)
                            )
                        }
                        .onEnded { _ in
                            lastOffset = imageOffset
                        }
                )
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavToFinishClimbView.self) { navWall in
            FinishClimbView(wall: navWall.wall, selectedHolds: navWall.selectedHolds, holdTypes: navWall.holdTypes)
        }
    }
}

// TODO: Get rid of all of the references to dismiss.
struct FinishClimbView: View {
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var nav: NavigationStateManager

    var wall: Wall
    var selectedHolds: [Hold]
    var holdTypes: [HoldType]

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // State variables for climb properties
    @State private var climbName: String = ""
    @State private var climbDescription: String = ""
    @State private var selectedGrade: Grade = .V_0

    private let grades: [Grade] = [
        .V_0, .V_1, .V_2, .V_3, .V_4, .V_5, .V_6, .V_7, .V_8,
        .V_9, .V_10, .V_11, .V_12, .V_13, .V_14, .V_15, .V_16, .V_17
    ]

    var body: some View {
        Form {
            Section("Climb Details") {
                TextField("Climb Name", text: $climbName)
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading) {
                    Text("Grade")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    Picker("", selection: $selectedGrade) {
                        ForEach(grades, id: \.self) { grade in
                            Text(formatGrade(grade)).tag(grade)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }
                
                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    TextEditor(text: $climbDescription)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("Finish Climb")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    nav.selectionPath.removeLast()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveClimb()
                    // this view, select finish hold view, select start hold view, select hold view.
                    nav.removeN(n: 4)
                }
                .disabled(!isValidClimb())
            }
        }
        .alert("Missing Information", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private func isValidClimb() -> Bool {
        let startCount = holdTypes.filter { $0 == .start }.count
        let finishCount = holdTypes.filter { $0 == .finish }.count
        
        return !climbName.isEmpty && startCount > 0 && finishCount > 0
    }
    
    private func saveClimb() {
        guard !climbName.isEmpty else {
            alertMessage = "Please enter a climb name."
            showAlert = true
            return
        }
        
        let startCount = holdTypes.filter { $0 == .start }.count
        if startCount == 0 {
            alertMessage = "You need at least one start hold."
            showAlert = true
            return
        }
        
        let finishCount = holdTypes.filter { $0 == .finish }.count
        if finishCount == 0 {
            alertMessage = "You need at least one finish hold."
            showAlert = true
            return
        }
        
        print("Creating climb")
        
        // Example: if your model requires loading an image or file
        // Create the new climb
        let newClimb = Climb(
            name: climbName,
            grade: selectedGrade,
            wall: wall,
            desc: climbDescription
        )
        
        newClimb.holds = selectedHolds
        newClimb.holdTypes = holdTypes
        
        // Add to the wall's climbs
        wall.climbs.append(newClimb)

        // TODO: any uses of try? should just throw a fatal error if the climb cannot be saved for some reason.
        try? context.save()
    }
}
