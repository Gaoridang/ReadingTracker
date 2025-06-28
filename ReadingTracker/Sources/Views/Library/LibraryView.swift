//
//  LibraryView.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//

import SwiftUI
import CoreData

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default)
    private var books: FetchedResults<Book>
    
    @State private var showingAddBook = false
    @State private var selectedCategory = "All"
    
    let categories = ["All", "Fiction", "Non-Fiction", "Poetry", "Science"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Library")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("\(books.count) books in collection")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Category Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryPill(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Books Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(books) { book in
                        BookCard(book: book)
                    }
                    
                    // Add Book Card
                    AddBookCard(action: { showingAddBook = true })
                }
                .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(hex: "FAFAFA"))
        .sheet(isPresented: $showingAddBook) {
            AddBookView()
        }
    }
}

#Preview {
    LibraryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
