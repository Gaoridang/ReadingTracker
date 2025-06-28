// AppError.swift
import SwiftUI

// MARK: - App Error Model
struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let underlyingError: Error?
    
    init(title: String = "Error", message: String, error: Error? = nil) {
        self.title = title
        self.message = message
        self.underlyingError = error
    }
    
    static func coreDataError(_ error: Error) -> AppError {
        AppError(
            title: "Database Error",
            message: "Failed to save your reading data. Please try again.",
            error: error
        )
    }
    
    static func validationError(_ message: String) -> AppError {
        AppError(
            title: "Invalid Input",
            message: message
        )
    }
    
    static func networkError(_ error: Error) -> AppError {
        AppError(
            title: "Network Error",
            message: "Unable to connect. Please check your internet connection.",
            error: error
        )
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { error in
                Alert(
                    title: Text(error.title),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(hex: "4CAF50"))
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color(hex: "4CAF50"))
                        .cornerRadius(25)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
