//
//  AddBookView.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/28/25.
//


// AddBookView.swift
import SwiftUI

struct AddBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var currentPage = "0"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Book Information") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Total Pages", text: $totalPages)
                        .keyboardType(.numberPad)
                    TextField("Current Page (if already started)", text: $currentPage)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(action: saveBook) {
                        Text("Add Book")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color(hex: "4CAF50"))
                    .disabled(title.isEmpty || author.isEmpty || totalPages.isEmpty)
                }
            }
            .navigationTitle("Add New Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveBook() {
        guard let totalPagesInt = Int16(totalPages),
              let currentPageInt = Int16(currentPage) else { return }
        
        let newBook = Book(context: viewContext)
        newBook.id = UUID()
        newBook.title = title
        newBook.author = author
        newBook.totalPages = totalPagesInt
        newBook.currentPage = currentPageInt
        newBook.difficulty = 3
        newBook.dateAdded = Date()
        newBook.isActive = true
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving book: \(error)")
        }
    }
}

#Preview {
    AddBookView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}