import SwiftUI

/// Prosa escrita por una persona. En español se ve igual.
/// En inglés espera la traducción y no muestra primero el español.
struct ProseText: View {
    let text: String
    var font: Font = .body
    var weight: Font.Weight?
    var color: Color = .primary
    var lineLimit: Int?
    var alignment: TextAlignment = .leading
    var tracking: CGFloat = 0
    var uppercase: Bool = false
    var expands: Bool = false

    @AppStorage("campusvote.preferences.language") private var language = "es"
    @State private var english: String?

    var body: some View {
        Text(visible)
            .font(styled)
            .foregroundStyle(color)
            .lineLimit(lineLimit)
            .multilineTextAlignment(alignment)
            .tracking(tracking)
            .fixedSize(horizontal: false, vertical: expands)
            .opacity(waiting ? 0 : 1)
            .task(id: "\(language)|\(text)") { await load() }
    }

    private var styled: Font {
        guard let weight else { return font }
        return font.weight(weight)
    }

    private var waiting: Bool {
        language == "en" && english == nil && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var visible: String {
        let source = language == "en" ? (english ?? text) : text
        return uppercase ? source.uppercased() : source
    }

    private func load() async {
        guard language == "en" else {
            english = nil
            return
        }
        english = await ProseTranslator.translate(text)
    }
}
