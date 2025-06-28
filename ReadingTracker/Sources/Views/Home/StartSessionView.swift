// StartSessionView.swift
import SwiftUI

struct StartSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let onStarted: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "4CAF50"))
                    
                    Text("Start Reading Session")
                        .font(.largeTitle)
                        .bold()
                    
                    Text(book.title)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("by \(book.author)")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    Text("Current page: \(book.currentPage)")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding(.top)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        SessionManager.shared.startSession(for: book, location: "Home") { result in
                            switch result {
                            case .success:
                                self.dismiss()
                                self.onStarted()
                            case .failure(let error):
                                print("Failed to start session: \(error)")
                            }
                        }
                    }) {
                        Text("Start Reading")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "4CAF50"))
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

// Disable preview for now - Core Data previews can be problematic
// To test, run the app in the simulator instead
/*
#Preview {
    StartSessionView(book: Book.preview)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
*/
