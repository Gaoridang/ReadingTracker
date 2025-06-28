//
//  EmptyBooksView.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


// EmptyBooksView.swift
import SwiftUI

struct EmptyBooksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No books yet")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Add a book from the Library tab")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    EmptyBooksView()
        .padding()
}