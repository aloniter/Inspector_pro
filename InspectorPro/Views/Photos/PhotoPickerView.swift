import SwiftUI
import PhotosUI

// PhotosPicker is used inline in FindingEditorView.
// This file contains shared photo picker utilities.

extension PhotosPickerItem {
    /// Load as UIImage
    func loadUIImage() async -> UIImage? {
        guard let data = try? await loadTransferable(type: Data.self) else { return nil }
        return UIImage(data: data)
    }
}
