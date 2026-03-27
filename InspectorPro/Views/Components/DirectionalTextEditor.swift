import SwiftUI
import UIKit

struct DirectionalTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let layoutDirection: LayoutDirection

    init(
        text: Binding<String>,
        isFocused: Binding<Bool> = .constant(false),
        layoutDirection: LayoutDirection
    ) {
        _text = text
        _isFocused = isFocused
        self.layoutDirection = layoutDirection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, layoutDirection: layoutDirection)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .label
        textView.keyboardDismissMode = .interactive
        textView.autocorrectionType = .default
        applyDirection(to: textView, coordinator: context.coordinator)
        applyText(text, to: textView, coordinator: context.coordinator)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.layoutDirection = layoutDirection
        applyDirection(to: textView, coordinator: context.coordinator)

        if textView.text != text {
            applyText(text, to: textView, coordinator: context.coordinator)
        }

        if isFocused, !textView.isFirstResponder {
            textView.becomeFirstResponder()
        } else if !isFocused, textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }

    private func applyDirection(to textView: UITextView, coordinator: Coordinator) {
        let paragraphStyle = coordinator.paragraphStyle
        textView.textAlignment = paragraphStyle.alignment
        textView.semanticContentAttribute = coordinator.semanticContentAttribute
        textView.typingAttributes = [
            .font: textView.font ?? UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle,
        ]
    }

    private func applyText(_ text: String, to textView: UITextView, coordinator: Coordinator) {
        let previousSelection = textView.selectedRange
        let font = textView.font ?? UIFont.preferredFont(forTextStyle: .body)

        textView.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.label,
                .paragraphStyle: coordinator.paragraphStyle,
            ]
        )

        let selectionLocation = min(previousSelection.location, textView.attributedText.length)
        let remainingLength = max(0, textView.attributedText.length - selectionLocation)
        textView.selectedRange = NSRange(
            location: selectionLocation,
            length: min(previousSelection.length, remainingLength)
        )
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var isFocused: Bool
        var layoutDirection: LayoutDirection

        init(text: Binding<String>, isFocused: Binding<Bool>, layoutDirection: LayoutDirection) {
            _text = text
            _isFocused = isFocused
            self.layoutDirection = layoutDirection
        }

        var paragraphStyle: NSParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.alignment = layoutDirection == .rightToLeft ? .right : .left
            style.baseWritingDirection = layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
            style.lineBreakMode = .byWordWrapping
            return style
        }

        var semanticContentAttribute: UISemanticContentAttribute {
            layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isFocused = true
            textView.typingAttributes = [
                .font: textView.font ?? UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraphStyle,
            ]
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFocused = false
        }
    }
}
