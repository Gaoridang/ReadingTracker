//
//  ProgressBar.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


import SwiftUI

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(Color(hex: "4CAF50"))
                    .frame(width: geometry.size.width * progress)
            }
        }
        .cornerRadius(2)
    }
}