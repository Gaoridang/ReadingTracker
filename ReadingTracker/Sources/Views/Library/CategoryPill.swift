//
//  CategoryPill.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


import SwiftUI

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "4CAF50") : Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}
