// MainContainerView.swift
import SwiftUI

struct MainContainerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var currentDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main Content Area
                ZStack {
                    // Tab Content - Only Home and Library now
                    switch navigationCoordinator.selectedTab {
                    case 0:
                        HomeViewContent(currentDate: $currentDate)
                    case 1:
                        LibraryView()
                    default:
                        HomeViewContent(currentDate: $currentDate)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Date Navigation (only shown on Home tab)
                if navigationCoordinator.selectedTab == 0 {
                    DateNavigationView(currentDate: $currentDate)
                        .background(Color.white)
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 0.5),
                            alignment: .top
                        )
                }
                
                // Tab Bar - Only 2 tabs now
                CustomTabBar(selectedTab: $navigationCoordinator.selectedTab)
                    .background(Color.white)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .ignoresSafeArea(.keyboard)
    }
}

// Custom Tab Bar with only 2 tabs
struct CustomTabBar: View {
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
