// BookRowView.swift
import SwiftUI

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            VStack(spacing: 0) {
                HStack {
                    // Book info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title ?? "Unknown Title")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Text(book.author ?? "Unknown Author")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Progress info
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(book.currentPage) pages")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        
                        Text("\(Int(book.percentComplete))%")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 12)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(Color(hex: "4CAF50"))
                            .frame(width: geometry.size.width * (book.percentComplete / 100), height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
            .padding(16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 12) {
        BookRowView(book: Book.preview)
        BookRowView(book: Book.preview)
    }
    .padding()
    .background(Color.gray.opacity(0.05))
}
