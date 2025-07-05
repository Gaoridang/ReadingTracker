//
//  FloatingLabelInput.swift
//  ReadingTracker
//
//  Created by 이재준 on 7/3/25.
//


import SwiftUI

// MARK: - Floating Label Input Component
struct FloatingLabelInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .leading) {
                // 배경 및 테두리
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .stroke(isFocused ? Color.black : Color.gray.opacity(0.3), lineWidth: 1)
                
                VStack(alignment: .leading, spacing: 8) {
                    // 플로팅 라벨
                    HStack {
                        Text(label)
                            .font(.system(size: 10))
                            .foregroundColor(Color.gray)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    
                    // 입력 필드와 Clear 버튼
                    HStack {
                        if isSecure {
                            SecureField(placeholder, text: $text)
                                .font(.system(size: 16))
                                .focused($isFocused)
                                .keyboardType(keyboardType)
                        } else {
                            TextField(placeholder, text: $text)
                                .font(.system(size: 16))
                                .focused($isFocused)
                                .keyboardType(keyboardType)
                        }
                        
                        // Clear 버튼
                        if !text.isEmpty {
                            Button(action: {
                                text = ""
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .frame(width: 20, height: 20)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
            }
        }
        .frame(height: 60)
    }
}