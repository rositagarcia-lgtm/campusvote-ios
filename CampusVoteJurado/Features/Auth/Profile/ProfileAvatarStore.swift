import Foundation
import UIKit
import CryptoKit

enum ProfileAvatarStore {
    private static func hiddenKey(for userId: String) -> String {
        "campusvote.jury.avatar.hidden.\(userId)"
    }

    private static func fileURL(for userId: String) -> URL {
        let digest = SHA256.hash(data: Data(userId.utf8))
            .map { String(format: "%02x", $0) }.joined()
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("jury-profile-avatar-\(digest).jpg")
    }

    private static func removeLegacyAvatar() {
        let oldURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("jury-profile-avatar.jpg")
        try? FileManager.default.removeItem(at: oldURL)
        UserDefaults.standard.removeObject(forKey: "campusvote.jury.avatar.hidden")
    }

    static func isHidden(for userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: hiddenKey(for: userId))
    }

    static func save(_ image: UIImage, for userId: String) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        removeLegacyAvatar()
        try? data.write(to: fileURL(for: userId), options: .atomic)
        UserDefaults.standard.set(false, forKey: hiddenKey(for: userId))
    }

    static func load(for userId: String) -> UIImage? {
        removeLegacyAvatar()
        guard !isHidden(for: userId),
              let data = try? Data(contentsOf: fileURL(for: userId)) else { return nil }
        return UIImage(data: data)
    }

    static func delete(for userId: String) {
        try? FileManager.default.removeItem(at: fileURL(for: userId))
        UserDefaults.standard.set(true, forKey: hiddenKey(for: userId))
    }

    static func clear(for userId: String) {
        try? FileManager.default.removeItem(at: fileURL(for: userId))
        UserDefaults.standard.removeObject(forKey: hiddenKey(for: userId))
        removeLegacyAvatar()
    }
}
