import Foundation
import SwiftData

typealias PhotoRecord = InspectorProSchemaV3.PhotoRecord

extension InspectorProSchemaV3.PhotoRecord {
    var displayImagePath: String {
        annotatedImagePath ?? imagePath
    }
}
