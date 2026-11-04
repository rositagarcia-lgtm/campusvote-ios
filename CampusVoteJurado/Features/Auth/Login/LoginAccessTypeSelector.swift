import SwiftUI

struct LoginAccessTypeSelector: View {
    @Environment(\.locale) private var locale
    let accessType: JuryAccessType
    let showContent: Bool
    let onSelect: (JuryAccessType) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(JuryAccessType.allCases) { type in
                let selected = accessType == type
                Button {
                    onSelect(type)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: type == .external ? "person.badge.key.fill" : "building.columns.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.tr(type.rawValue, locale: locale))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(selected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        Capsule().fill(selected ? Color.campusGreen : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color(light: 0xF3F5F7, dark: 0x1C2826)))
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
        .animation(.easeInOut(duration: 0.2), value: accessType)
    }
}
