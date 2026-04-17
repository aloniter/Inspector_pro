import Foundation
import SwiftData

typealias PhotoRecord = InspectorProSchemaV6.PhotoRecord

extension InspectorProSchemaV6.PhotoRecord {
    var displayImagePath: String {
        annotatedImagePath ?? imagePath
    }
}
