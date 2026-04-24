import Foundation
import SwiftData

typealias PhotoRecord = InspectorProSchemaV9.PhotoRecord

extension InspectorProSchemaV9.PhotoRecord {
    var displayImagePath: String {
        annotatedImagePath ?? imagePath
    }
}
