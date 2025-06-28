//
//  Book+Extensions.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//

// Book+Preview.swift
import CoreData

extension Book {
    static var preview: Book {
        let context = PersistenceController.preview.container.viewContext
        let book = Book(context: context)
        book.id = UUID()
        book.title = "The Great Gatsby"
        book.author = "F. Scott Fitzgerald"
        book.totalPages = 180
        book.currentPage = 120
        book.difficulty = 3
        book.dateAdded = Date()
        book.isActive = true
        return book
    }
}
