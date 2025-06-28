//
//  FloatingActionButton.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


// FloatingActionButton.swift
import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            ZStack {
                Circle()
                    .fill(Color(hex: "4CAF50"))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        FloatingActionButton(action: {
            print("FAB tapped")
        })
    }
}