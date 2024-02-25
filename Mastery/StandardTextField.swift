//
//  StandardTextField.swift
//  Mastery
//
//  Created by Andy Tieu on 2/2/24.
//

import SwiftUI

private let DEFAULT_CHAR_LIMIT_WARNING = 5

struct StandardTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        ZStack {
            configuration
                .padding(10)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(uiColor: .systemGray3), lineWidth: 1)
                }
        }
    }
}

// Wrapper over a TextField that provides additional functionality like character limits and a button to clear text.
struct StandardTextField<Field: View>: View {
    private let textField: Field
    @Binding private var fieldText: String
    private let labelText: String?
    private let charLimit: Int?
    private let charLimitWarning: Int // How many characters remaining until the user is warned about the character limit.
    private let clearTextButtonEnabled: Bool
    
    init(
        textField: Field,
        fieldText: Binding<String>,
        labelText: String? = nil,
        charLimit: Int? = nil,
        charLimitWarning: Int = DEFAULT_CHAR_LIMIT_WARNING,
        clearTextButtonEnabled: Bool = true
    ) {
        self.textField = textField
        self._fieldText = fieldText
        self.labelText = labelText
        self.charLimit = charLimit
        self.charLimitWarning = charLimitWarning
        self.clearTextButtonEnabled = clearTextButtonEnabled
    }
    
    private func makeClearTextButton() -> some View {
        Button(action: {
            fieldText.removeAll()
        }) {
            Image(systemName: "xmark")
                .foregroundStyle(.appLabel)
        }
    }
    
    @ViewBuilder
    private func makeCharLimitWarningText() -> some View {
        if let charLimit {
            let charsLeft = charLimit - fieldText.count
            if charsLeft <= charLimitWarning {
                Text("\(charsLeft) Remaining")
                    .foregroundStyle(charsLeft == 0 ? .red : .appLabel)
            }
        }
    }
    
    private func limitCharCount() {
        if let charLimit, fieldText.count > charLimit {
            let endIndex = fieldText.index(fieldText.startIndex, offsetBy: charLimit)
            fieldText.removeSubrange(endIndex...)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let labelText {
                    Text(labelText)
                        .font(.headline)
                }
                Spacer()
                makeCharLimitWarningText()
            }
            HStack {
                textField
                    .onChange(of: fieldText, limitCharCount)
                if clearTextButtonEnabled {
                    if fieldText.count > 0 {
                        makeClearTextButton()
                    }
                }
            }
            .padding(10)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(uiColor: .systemGray3), lineWidth: 1)
            }
        }
    }
    
}

private struct PreviewView: View {
    @State private var text = ""
    
    var body: some View {
        StandardTextField(
            textField: TextField("Empty", text: $text),
            fieldText: $text, labelText: "Text",
            charLimit: 10
        )
        .padding()
    }
}

#Preview("Light") {
    PreviewView()
}

#Preview("Dark") {
    PreviewView()
        .preferredColorScheme(.dark)
}
