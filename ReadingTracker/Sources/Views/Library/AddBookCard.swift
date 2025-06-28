//
//  AddBookCard.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


import SwiftUI

struct AddBookCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "4CAF50"))
                
                Text("Add Book")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "4CAF50").opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }
}
