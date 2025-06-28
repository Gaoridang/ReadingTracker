// QuickStatCard.swift
import SwiftUI

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .padding(.bottom, 12)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 4)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}

#Preview {
    HStack(spacing: 12) {
        QuickStatCard(
            icon: "book",
            value: "45",
            label: "pages today",
            iconColor: .black.opacity(0.6),
            backgroundColor: Color.gray.opacity(0.1)
        )
        
        QuickStatCard(
            icon: "clock",
            value: "120",
            label: "minutes",
            iconColor: .black.opacity(0.6),
            backgroundColor: Color.gray.opacity(0.1)
        )
    }
    .padding()
}
