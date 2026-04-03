import Foundation
import SwiftData

typealias PhotoRecord = InspectorProSchemaV4.PhotoRecord

extension InspectorProSchemaV4.PhotoRecord {
    var displayImagePath: String {
        annotatedImagePath ?? imagePath
    }
}
