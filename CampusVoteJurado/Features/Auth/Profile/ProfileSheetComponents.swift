import SwiftUI

struct SheetTopBar: View {
    @Environment(\.locale) private var locale
    let title: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text(L10n.tr(title, locale: locale))
                .font(.subheadline.weight(.semibold))

            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar")
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }
}

extension View {
    func juryBottomSheet(height: CGFloat? = nil, background: Color) -> some View {
        let sheet = self
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(12)
            .presentationBackground(background)
        if let height {
            return AnyView(sheet.presentationDetents([.height(height)]))
        }
        return AnyView(sheet.presentationDetents([.large]))
    }
}
