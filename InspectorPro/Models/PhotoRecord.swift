import Foundation
import SwiftData

typealias PhotoRecord = InspectorProSchemaV7.PhotoRecord

extension InspectorProSchemaV7.PhotoRecord {
    var displayImagePath: String {
        annotatedImagePath ?? imagePath
    }
}
