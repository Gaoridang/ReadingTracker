// MainContainerView.swift
import SwiftUI

struct MainContainerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTab = 0 // Local state instead of using NavigationCoordinator
    @State private var currentDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main Content Area
                ZStack {
                    // Tab Content
                    Group {
                        if selectedTab == 0 {
                            HomeViewContent(currentDate: $currentDate)
                        } else if selectedTab == 1 {
                            EnhancedStatsView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Date Navigation (only shown on Home tab)
                if selectedTab == 0 {
                    DateNavigationView(currentDate: $currentDate)
                        .background(Color.white)
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 0.5),
                            alignment: .top
                        )
                }
                
                // Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                    .background(Color.white)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Sync with NavigationCoordinator if needed
            if NavigationCoordinator.shared.selectedTab != selectedTab {
                DispatchQueue.main.async {
                    NavigationCoordinator.shared.selectedTab = selectedTab
                }
            }
        }
        .onReceive(NavigationCoordinator.shared.$selectedTab) { newTab in
            // Only update if different to avoid loops
            if newTab != selectedTab {
                selectedTab = newTab
            }
        }
    }
}

// Custom Tab Bar with 3 tabs
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabBarButton(
                icon: "house",
                title: "Home",
                isSelected: selectedTab == 0,
                action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 0
                    }
                }
            )
            
            TabBarButton(
                icon: "books.vertical",
                title: "Library",
                isSelected: selectedTab == 1,
                action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 1
                    }
                }
            )
            
            TabBarButton(
                icon: "chart.bar",
                title: "Stats",
                isSelected: selectedTab == 2,
                action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 2
                    }
                }
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

#Preview {
    MainContainerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
