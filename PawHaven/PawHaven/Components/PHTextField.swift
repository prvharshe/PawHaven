// PHTextField.swift
// PawHaven

import SwiftUI

struct PHTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool
    @State private var isRevealed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.phTextSecondary)

            HStack {
                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                    }
                }
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(isSecure)
                .focused($isFocused)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .foregroundStyle(Color.phTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.phSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.phPrimary : Color.phBorder, lineWidth: isFocused ? 1.5 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PHTextField(label: "Email", placeholder: "you@example.com", text: .constant(""), keyboardType: .emailAddress, autocapitalization: .never)
        PHTextField(label: "Password", placeholder: "••••••••", text: .constant(""), isSecure: true)
    }
    .padding()
    .background(Color.phBackground)
}
