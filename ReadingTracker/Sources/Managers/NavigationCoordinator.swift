//
//  NavigationCoordinator.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/28/25.
//


// NavigationCoordinator.swift
import SwiftUI

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var selectedTab = 0
    @Published var shouldNavigateToTracking = false
    
    private init() {}
    
    func navigateToTrackingTab() {
        selectedTab = 2
        shouldNavigateToTracking = true
    }
    
    func navigateToLibraryTab() {
        selectedTab = 1
    }
    
    func navigateToHomeTab() {
        selectedTab = 0
    }
}
