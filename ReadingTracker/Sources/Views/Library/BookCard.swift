//
//  BookCard.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


import SwiftUI

struct BookCard: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book cover placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color(hex: "E8F5E9"), Color(hex: "C8E6C9")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "4CAF50"))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(book.author ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Progress
                HStack(spacing: 4) {
                    ProgressBar(progress: book.percentComplete / 100)
                        .frame(height: 4)
                    
                    Text("\(Int(book.percentComplete))%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}
