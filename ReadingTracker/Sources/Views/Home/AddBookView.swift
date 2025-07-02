import SwiftUI
import CoreData

struct AddBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var currentPage = "0"
    @State private var category = "Fiction"
    @State private var difficulty = 3
    
    @State private var isLoading = false
    @State private var error: AppError?
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case title, author, totalPages, currentPage
    }
    
    let categories = ["Fiction", "Non-Fiction", "Biography", "Science", "Technology", "Poetry", "Philosophy", "History"]
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(totalPages) != nil &&
        Int(currentPage) != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section {
                        TextField("Title", text: $title)
                            .focused($focusedField, equals: .title)
                            .autocapitalization(.words)
                            .onSubmit { hideKeyboard() }
                        
                        TextField("Author", text: $author)
                            .focused($focusedField, equals: .author)
                            .autocapitalization(.words)
                            .onSubmit { hideKeyboard() }
                    } header: {
                        Text("Book Information")
                    }
                    
                    Section {
                        TextField("Total Pages", text: $totalPages)
                            .focused($focusedField, equals: .totalPages)
                            .keyboardType(.numberPad)
                            .onSubmit { hideKeyboard() }
                        
                        TextField("Current Page", text: $currentPage)
                            .focused($focusedField, equals: .currentPage)
                            .keyboardType(.numberPad)
                            .onSubmit { hideKeyboard() }
                        
                        if let current = Int(currentPage), let total = Int(totalPages), current > total {
                            Label("Current page cannot exceed total pages", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } header: {
                        Text("Reading Progress")
                    } footer: {
                        Text("Enter 0 if you haven't started reading yet")
                            .font(.caption)
                    }
                    
                    Section {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reading Difficulty")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: { difficulty = level }) {
                                        Image(systemName: level <= difficulty ? "star.fill" : "star")
                                            .foregroundColor(Color(hex: "4CAF50"))
                                            .font(.title3)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Additional Details")
                    }
                    
                    Section {
                        Button(action: saveBook) {
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Adding Book...")
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Text("Add Book")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                            }
                        }
                        .listRowBackground(isValid ? Color(hex: "4CAF50") : Color.gray)
                        .disabled(!isValid || isLoading)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        focusedField = .title
                    }
                }
                
                if isLoading {
                    LoadingOverlay(message: "Adding book to library...")
                }
            }
            .navigationTitle("Add New Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .errorAlert($error)
        }
    }
    
    private func saveBook() {
        guard let totalPagesInt = Int16(totalPages),
              let currentPageInt = Int16(currentPage) else {
            error = AppError.validationError("Please enter valid page numbers")
            return
        }
        
        if currentPageInt > totalPagesInt {
            error = AppError.validationError("Current page cannot be greater than total pages")
            return
        }
        
        if totalPagesInt < 1 {
            error = AppError.validationError("Total pages must be at least 1")
            return
        }
        
        isLoading = true
        
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = viewContext
        
        backgroundContext.perform {
            let newBook = Book(context: backgroundContext)
            newBook.id = UUID()
            newBook.title = self.title.trimmingCharacters(in: .whitespacesAndNewlines)
            newBook.author = self.author.trimmingCharacters(in: .whitespacesAndNewlines)
            newBook.totalPages = totalPagesInt
            newBook.currentPage = currentPageInt
            newBook.difficulty = Int16(self.difficulty)
            newBook.category = self.category
            newBook.dateAdded = Date()
            newBook.isActive = true
            
            do {
                try backgroundContext.save()
                DispatchQueue.main.async {
                    do {
                        try self.viewContext.save()
                        self.dismiss()
                    } catch {
                        self.isLoading = false
                        self.error = AppError.coreDataError(error)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = AppError.coreDataError(error)
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    AddBookView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
