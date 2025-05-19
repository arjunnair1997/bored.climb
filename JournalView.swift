import SwiftUI

struct JournalView: View {
    @State private var entryText: String = ""
    @State private var entries: [JournalEntry] = []
    @State private var isShowingAlert = false
    @State private var entryToDelete: JournalEntry?

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Spacer().frame(height: 16)

                    // Text input for new entry
                    HStack {
                        TextField("Add an entry...", text: $entryText)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            // Handle entry submission
                            if !entryText.isEmpty {
                                addEntry()
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
//        .background(Color(.systemBackground))
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

