import Foundation
import SwiftData

typealias PhotoRecord = InspectorProSchemaV5.PhotoRecord

extension InspectorProSchemaV5.PhotoRecord {
    var displayImagePath: String {
        annotatedImagePath ?? imagePath
    }
}
