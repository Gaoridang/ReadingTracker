//
//  StatItem.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


import SwiftUI

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(.black)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
