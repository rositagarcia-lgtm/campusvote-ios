import Foundation
import Observation

@Observable
final class InstitutionBrandState {
    var name: String?
    var kindLabel: String?
    var logoURL: URL?
    var primaryHex: String?
    var secondaryHex: String?
}
