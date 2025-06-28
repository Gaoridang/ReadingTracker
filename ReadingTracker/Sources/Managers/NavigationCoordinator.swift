// NavigationCoordinator.swift
import SwiftUI
import Combine

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var selectedTab = 0 {
        didSet {
            // Ensure updates happen on main thread
            if !Thread.isMainThread {
                DispatchQueue.main.async { [weak self] in
                    self?.selectedTab = oldValue
                    DispatchQueue.main.async {
                        self?.selectedTab = self?.selectedTab ?? 0
                    }
                }
            }
        }
    }
    
    @Published var shouldNavigateToTracking = false
    
    private init() {}
    
    func navigateToHomeTab() {
        DispatchQueue.main.async { [weak self] in
            self?.selectedTab = 0
        }
    }
    
    func navigateToLibraryTab() {
        DispatchQueue.main.async { [weak self] in
            self?.selectedTab = 1
        }
    }
    
    func navigateToStatsTab() {
        DispatchQueue.main.async { [weak self] in
            self?.selectedTab = 2
        }
    }
    
    func navigateToTrackingTab() {
        DispatchQueue.main.async { [weak self] in
            self?.shouldNavigateToTracking = true
        }
    }
}
