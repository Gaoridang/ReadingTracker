import SwiftUI
import CoreData

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default
    ) private var books: FetchedResults<Book>
    
    var body: some View {
        List {
            ForEach(books) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookRowView(book: book)
                }
            }
        }
        .navigationTitle("Library")
    }
}
