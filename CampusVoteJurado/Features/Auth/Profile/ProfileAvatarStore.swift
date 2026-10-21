import Foundation
import UIKit

enum ProfileAvatarStore {
    private static let hiddenKey = "campusvote.jury.avatar.hidden"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("jury-profile-avatar.jpg")
    }

    static var isHidden: Bool {
        UserDefaults.standard.bool(forKey: hiddenKey)
    }

    static func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: fileURL, options: .atomic)
        UserDefaults.standard.set(false, forKey: hiddenKey)
    }

    static func load() -> UIImage? {
        guard !isHidden, let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    static func delete() {
        try? FileManager.default.removeItem(at: fileURL)
        UserDefaults.standard.set(true, forKey: hiddenKey)
    }
}
