import SwiftUI
import CoreData
import os.log

@MainActor
struct AddBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var currentPage = "0"
    @State private var category = "Fiction"
    @State private var difficulty = 3
    
    @State private var isLoading = false
    @State private var error: BookError?
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case title, author, totalPages, currentPage
    }
    
    let categories = ["Fiction", "Non-Fiction", "Biography", "Science", "Technology", "Poetry", "Philosophy", "History"]
    
    // Modern logging system
    private let logger = Logger(subsystem: "AddBookView", category: "CoreData")
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(totalPages) != nil &&
        Int(currentPage) != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // 헤더
                        HStack {
                            Text("📚 새 책 추가")
                                .font(.title)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // 책 정보 섹션
                        VStack(alignment: .leading, spacing: 16) {
                            Text("책 정보")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                FloatingLabelInput(
                                    label: "책 제목",
                                    placeholder: "책 제목을 입력하세요",
                                    text: $title
                                )
                                .focused($focusedField, equals: .title)
                                
                                FloatingLabelInput(
                                    label: "저자",
                                    placeholder: "저자명을 입력하세요",
                                    text: $author
                                )
                                .focused($focusedField, equals: .author)
                            }
                            .padding(.horizontal)
                        }
                        
                        // 독서 진행 섹션
                        VStack(alignment: .leading, spacing: 16) {
                            Text("독서 진행")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                FloatingLabelInput(
                                    label: "총 페이지",
                                    placeholder: "예: 350",
                                    text: $totalPages,
                                    keyboardType: .numberPad
                                )
                                .focused($focusedField, equals: .totalPages)
                                
                                FloatingLabelInput(
                                    label: "현재 페이지",
                                    placeholder: "예: 120",
                                    text: $currentPage,
                                    keyboardType: .numberPad
                                )
                                .focused($focusedField, equals: .currentPage)
                                
                                // 유효성 검사 메시지
                                if let current = Int(currentPage), let total = Int(totalPages), current > total {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.red)
                                        Text("현재 페이지는 총 페이지를 초과할 수 없습니다")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // 도움말 텍스트
                                Text("아직 읽기 시작하지 않았다면 0을 입력하세요")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                            .padding(.horizontal)
                        }
                        
                        // 추가 정보 섹션
                        VStack(alignment: .leading, spacing: 16) {
                            Text("추가 정보")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 20) {
                                // 카테고리 선택
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("카테고리")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 12)
                                    
                                    Menu {
                                        ForEach(categories, id: \.self) { categoryOption in
                                            Button(categoryOption) {
                                                category = categoryOption
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(category)
                                                .font(.system(size: 16))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                                
                                // 난이도 선택
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("읽기 난이도")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 12)
                                    
                                    HStack {
                                        ForEach(1...5, id: \.self) { level in
                                            Button(action: { difficulty = level }) {
                                                Image(systemName: level <= difficulty ? "star.fill" : "star")
                                                    .foregroundColor(Color(hex: "4CAF50"))
                                                    .font(.title3)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 저장 버튼
                        Button {
                            Task {
                                await saveBook()
                            }
                        } label: {
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("책 추가 중...")
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(10)
                            } else {
                                Text("책 추가하기")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                                    .padding()
                                    .background(isValid ? Color(hex: "4CAF50") : Color.gray)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(!isValid || isLoading)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
                .scrollDismissesKeyboard(.interactively)
                .task {
                    // Modern SwiftUI async initialization
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    focusedField = .title
                }
                
                if isLoading {
                    LoadingOverlay(message: "책을 라이브러리에 추가하는 중...")
                }
            }
            .navigationBarHidden(true)
            .onTapGesture {
                hideKeyboard()
            }
            .errorAlert($error)
        }
    }
    
    // MARK: - Modern async/await save method
    private func saveBook() async {
        logger.info("Starting book save process")
        
        // Validation
        guard let totalPagesInt = Int16(totalPages),
              let currentPageInt = Int16(currentPage) else {
            logger.error("Invalid page numbers provided")
            error = BookError.validationError("올바른 페이지 번호를 입력해주세요")
            return
        }
        
        if currentPageInt > totalPagesInt {
            logger.error("Current page (\(currentPageInt)) exceeds total pages (\(totalPagesInt))")
            error = BookError.validationError("현재 페이지는 총 페이지보다 클 수 없습니다")
            return
        }
        
        if totalPagesInt < 1 {
            logger.error("Total pages must be at least 1")
            error = BookError.validationError("총 페이지는 최소 1페이지여야 합니다")
            return
        }
        
        // Start loading state
        isLoading = true
        
        do {
            // Use modern async CoreData operations
            try await saveBookToCoreData(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                totalPages: totalPagesInt,
                currentPage: currentPageInt,
                category: category,
                difficulty: Int16(difficulty)
            )
            
            logger.info("Book saved successfully: \(title)")
            dismiss()
            
        } catch {
            logger.error("Failed to save book: \(error.localizedDescription)")
            self.error = BookError.coreDataError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Modern CoreData async operation
    private func saveBookToCoreData(
        title: String,
        author: String,
        totalPages: Int16,
        currentPage: Int16,
        category: String,
        difficulty: Int16
    ) async throws {
        // Create background context using correct approach
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = viewContext
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Perform save operation using modern async API
        try await backgroundContext.perform {
            let newBook = Book(context: backgroundContext)
            newBook.id = UUID()
            newBook.title = title
            newBook.author = author
            newBook.totalPages = totalPages
            newBook.currentPage = currentPage
            newBook.difficulty = difficulty
            newBook.category = category
            newBook.dateAdded = Date()
            newBook.isActive = true
            
            // Save to background context
            try backgroundContext.save()
            
            self.logger.info("Background context saved successfully")
        }
        
        // Save to main context - this will trigger UI updates
        try await viewContext.perform {
            try self.viewContext.save()
            self.logger.info("Main context saved successfully")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Modern Error Types (following SessionManager pattern)
enum BookError: LocalizedError {
    case validationError(String)
    case coreDataError(Error)
    case invalidContext
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .validationError(let message):
            return message
        case .coreDataError(let error):
            return "데이터 저장 오류: \(error.localizedDescription)"
        case .invalidContext:
            return "유효하지 않은 데이터 컨텍스트입니다"
        case .saveFailed(let error):
            return "저장 실패: \(error.localizedDescription)"
        }
    }
}


// MARK: - Modern Error Alert Extension
extension View {
    func errorAlert(_ error: Binding<BookError?>) -> some View {
        alert("오류", isPresented: .constant(error.wrappedValue != nil)) {
            Button("확인") {
                error.wrappedValue = nil
            }
        } message: {
            Text(error.wrappedValue?.errorDescription ?? "알 수 없는 오류가 발생했습니다.")
        }
    }
}

// MARK: - Modern Usage Example
extension AddBookView {
    /// Example of using modern async patterns with potential SessionManager integration
    func startReadingSession(for book: Book) async throws {
        // This integrates with the existing SessionManager (with completion handler)
        try await withCheckedThrowingContinuation { continuation in
            SessionManager.shared.startSession(for: book, startingPage: Int(book.currentPage)) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

#Preview {
    AddBookView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
