import SwiftUI

struct LoginAccessTypeSelector: View {
    @Environment(\.locale) private var locale
    let accessType: JuryAccessType
    let showContent: Bool
    let onSelect: (JuryAccessType) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(JuryAccessType.allCases) { type in
                Button {
                    onSelect(type)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: type == .external ? "person.badge.key.fill" : "building.columns.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.tr(type.rawValue, locale: locale))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(accessType == type ? Color.onBrand : Color.campusGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Group {
                            if accessType == type {
                                LinearGradient(
                                    colors: [Color.campusGreen, Color.campusTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color.cardBackground
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Color.campusGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 12)
    }
}
