// MainContainerView.swift
import SwiftUI

struct HomeView: View {
    @State private var currentDate = Date()
        
        var body: some View {
            HomeViewContent(currentDate: $currentDate)
                .navigationTitle("Reading Tracker")
                .navigationBarTitleDisplayMode(.large)
        }
}
