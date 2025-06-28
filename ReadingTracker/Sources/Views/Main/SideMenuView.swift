//
//  SideMenuView.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { isShowing = false }
            
            // Menu content
            HStack {
                VStack(alignment: .leading, spacing: 30) {
                    // Profile section
                    VStack(alignment: .leading, spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            )
                        
                        Text("Welcome Back")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black)
                    }
                    
                    // Menu items
                    VStack(alignment: .leading, spacing: 24) {
                        MenuItem(icon: "chart.bar.fill", title: "Statistics")
                        MenuItem(icon: "target", title: "Goals")
                        MenuItem(icon: "bell.fill", title: "Reminders")
                        MenuItem(icon: "gearshape.fill", title: "Settings")
                    }
                    
                    Spacer()
                    
                    // Bottom items
                    VStack(alignment: .leading, spacing: 20) {
                        MenuItem(icon: "questionmark.circle", title: "Help")
                        MenuItem(icon: "info.circle", title: "About")
                    }
                }
                .padding()
                .frame(width: 250)
                .background(Color.white)
                
                Spacer()
            }
        }
        .transition(.move(edge: .leading))
        .animation(.easeInOut, value: isShowing)
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "4CAF50"))
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.black)
        }
    }
}