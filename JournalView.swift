import SwiftUI

struct ContentHeightTextEditor: View {
    @Binding var text: String
    @Binding var textEditorHeight: CGFloat
    @Binding var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder text
            if text.isEmpty {
                Text("Add an entry...")
                    .foregroundColor(Color(.placeholderText))
                    .padding(.horizontal, 4)
            }
            
            // The actual TextEditor with dynamic height
            UITextViewWrapper(text: $text, calculatedHeight: $textEditorHeight, isFocused: $isFocused)
                .frame(minHeight: 30, maxHeight: max(30, textEditorHeight))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// UIViewRepresentable wrapper for UITextView that can calculate its own height
struct UITextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    @Binding var isFocused: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = false
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != self.text {
            uiView.text = self.text
        }
        
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
        
        UITextViewWrapper.recalculateHeight(view: uiView, result: $calculatedHeight)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, height: $calculatedHeight, isFocused: $isFocused)
    }
    
    static func recalculateHeight(view: UITextView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            result.wrappedValue = newSize.height
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var calculatedHeight: CGFloat
        @Binding var isFocused: Bool
        
        init(text: Binding<String>, height: Binding<CGFloat>, isFocused: Binding<Bool>) {
            self._text = text
            self._calculatedHeight = height
            self._isFocused = isFocused
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.text = textView.text
            UITextViewWrapper.recalculateHeight(view: textView, result: $calculatedHeight)
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            self.isFocused = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            self.isFocused = false
        }
    }
}

struct JournalView: View {
    @State private var entryText: String = ""
    @State private var entries: [JournalEntry] = []
    @State private var isShowingAlert = false
    @State private var entryToDelete: JournalEntry?
    @State private var isTextEditorFocused: Bool = false
    @State private var editorHeight: CGFloat = 30

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Spacer().frame(height: 16)

                    // Text input for new entry
                    HStack(alignment: .bottom) {
                        // TextEditor instead of TextField for multi-line support
                        ZStack(alignment: .leading) {
                            // Placeholder text that shows when TextEditor is empty
                            if entryText.isEmpty {
                                Text("Add an entry...")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 4)
//                                    .padding(.vertical, 8)
                            }
                            
                            ContentHeightTextEditor(text: $entryText, textEditorHeight: $editorHeight, isFocused: $isTextEditorFocused)
                        }
                        .padding(.horizontal, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        Button(action: {
                            // Handle entry submission
                            if !entryText.isEmpty {
                                addEntry()
                                // Dismiss keyboard on submission
                                isTextEditorFocused = false
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(toolbarColor)
                                .padding(10)
                        }
                    }
                    .padding(.horizontal, 10)
                    
                    // Journal entries list
                    ScrollView {
                        VStack(spacing: 0) {
                            if entries.isEmpty {
                                Text("No entries yet.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
                                ForEach(entries, id: \.id) { entry in
                                    VStack {
                                        JournalEntryCell(entry: entry)
                                            .contextMenu {
                                                Button(role: .destructive, action: {
                                                    entryToDelete = entry
                                                    isShowingAlert = true
                                                }) {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        
                                        // Add thin divider line after each entry (except the last one)
                                        if entry.id != entries.last?.id {
                                            Divider()
                                                .background(Color.black.opacity(0.3))
                                                .padding(.horizontal, 10)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .padding(.bottom, 10)
                    // Add tap gesture to dismiss keyboard when tapping elsewhere
                    .onTapGesture {
                        isTextEditorFocused = false
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Journal")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            .toolbarBackground(toolbarColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Delete Entry", isPresented: $isShowingAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete, let id = entry.id {
                        deleteEntry(id: id)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this entry?")
            }
            .onAppear {
                loadEntries()
            }
            // Add tap gesture to dismiss keyboard when tapping background
            .contentShape(Rectangle())
            .onTapGesture {
                isTextEditorFocused = false
            }
        }
    }
    
    // Function to add a new entry
    private func addEntry() {
        let newEntry = JournalEntry(content: entryText)
        let _ = newEntry.save()
        
        // Clear the text field and reload entries
        entryText = ""
        loadEntries()
    }
    
    // Function to load all entries
    private func loadEntries() {
        entries = DatabaseManager.shared.getAllJournalEntries()
    }
    
    // Function to delete an entry
    private func deleteEntry(id: Int64) {
        DatabaseManager.shared.deleteJournalEntry(entryId: id)
        loadEntries()
    }
}

// Journal Entry Cell Component
struct JournalEntryCell: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.content)
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
                    .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 4)
        .cornerRadius(8)
    }
    
    // Format the date for display
    private var formattedDate: String {
        let formatter = DateFormatter()
        
        // If the entry was created today, show time only
        if Calendar.current.isDateInToday(entry.createdAt) {
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: entry.createdAt))"
        }
        
        // If the entry was created yesterday, show "Yesterday"
        if Calendar.current.isDateInYesterday(entry.createdAt) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday at \(formatter.string(from: entry.createdAt))"
        }
        
        // For older entries, show the date
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.createdAt)
    }
}
