
import SwiftUI

struct LabeledTextField: View {
    // MARK: - PROPERTIES
    
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    @FocusState private var isFocused: Bool
    
    // MARK: - BODY
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // --- LABEL ---
            // The label appears with an animation when the text field is focused or contains text.
            if isFocused || !text.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
            
            // --- TEXTFIELD & CLEAR BUTTON ---
            HStack {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .keyboardType(keyboardType)
                    // When the text is empty and the field is not focused, show the label as a placeholder.
                    .placeholder(when: text.isEmpty && !isFocused) {
                        Text(label)
                            .foregroundColor(.gray)
                    }
                
                Spacer()
                
                // --- CLEAR BUTTON ---
                // Appears only when there is text in the field.
                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle()) // Removes default button styling
                }
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                // --- FOCUSED BORDER ---
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - VIEW EXTENSION
// Custom ViewModifier to show a placeholder view
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}


// MARK: - PREVIEW
struct LabeledTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LabeledTextField(
                label: "이름",
                placeholder: "이름 입력",
                text: .constant("")
            )
            
            LabeledTextField(
                label: "이름",
                placeholder: "이름 입력",
                text: .constant("홍길동")
            )
            
            LabeledTextField(
                label: "이메일",
                placeholder: "이메일 입력",
                text: .constant(""),
                keyboardType: .emailAddress
            )
        }
        .padding()
    }
}
