import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        MainContainerView()
    }
}

#Preview {
    MainContainerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
