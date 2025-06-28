// TabBar.swift
import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabBarButton(
                icon: "house",
                title: "Home",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabBarButton(
                icon: "books.vertical",
                title: "Library",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            TabBarButton(
                icon: "timer",
                title: "Track",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.monochrome)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? Color(hex: "4CAF50") : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}
