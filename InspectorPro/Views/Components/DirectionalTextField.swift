import SwiftUI
import UIKit

struct DirectionalTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let layoutDirection: LayoutDirection
    var keyboardType: UIKeyboardType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var textContentType: UITextContentType?
    var autocorrectionType: UITextAutocorrectionType = .default

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.adjustsFontForContentSizeCategory = true
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        applyConfiguration(to: textField)
        textField.text = text
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        applyConfiguration(to: textField)
        if textField.text != text {
            textField.text = text
        }
    }

    private func applyConfiguration(to textField: UITextField) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = layoutDirection == .rightToLeft ? .right : .left
        paragraphStyle.baseWritingDirection = layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight

        let font = textField.font ?? UIFont.preferredFont(forTextStyle: .body)
        textField.defaultTextAttributes = [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle,
        ]
        textField.placeholder = placeholder
        textField.textAlignment = paragraphStyle.alignment
        textField.semanticContentAttribute = layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = autocapitalizationType
        textField.autocorrectionType = autocorrectionType
        textField.textContentType = textContentType
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        @objc func textDidChange(_ sender: UITextField) {
            text = sender.text ?? ""
        }
    }
}
