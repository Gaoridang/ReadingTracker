import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear // Removes top border
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = .black
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeView()
            }
            .tabItem {
                selectedTab == 0 ? Image("TabHomeIconSelected") : Image("TabHomeIcon")
            }
            .tag(0)
            
            // Stats Tab
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Image(systemName: "chart.bar")
            }
            .tag(1)
            
            // Library Tab
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Image(systemName: "books.vertical")
            }
            .tag(2)
        }
        .accentColor(.black) // Ensures selected tab icon is black
    }
}
