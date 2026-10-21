import SwiftUI

struct TabSegmentButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let activeColor: Color
    let activeBadgeColor: Color
    let action: () -> Void

    // MARK: - Inicializador con valores por defecto del sistema dinámico
    init(
        title: String,
        count: Int,
        isSelected: Bool,
        activeColor: Color = .brand,
        activeBadgeColor: Color = .brand,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.count = count
        self.isSelected = isSelected
        self.activeColor = activeColor
        self.activeBadgeColor = activeBadgeColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // MARK: - Título con transición de peso
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .tracking(0.3)
                    .foregroundStyle(isSelected ? activeColor : Color.appNeutral)

                // MARK: - Badge de Conteo Premium
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? Color.onBrand : activeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(isSelected ? activeBadgeColor : activeBadgeColor.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : activeColor.opacity(0.3), lineWidth: 1)
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0) // Micro-interacción de escala
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.cardBackground : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? activeColor.opacity(0.2) : Color.clear, lineWidth: 1)
            )
            .shadow(
                color: isSelected ? activeColor.opacity(0.08) : .clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain) // Evita el oscurecimiento por defecto de UIButton
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview de Validación
#Preview {
    struct PreviewWrapper: View {
        @State private var selected = 0
        
        var body: some View {
            VStack(spacing: 16) {
                TabSegmentButton(
                    title: "Pendientes",
                    count: 12,
                    isSelected: selected == 0
                ) { selected = 0 }
                
                TabSegmentButton(
                    title: "Completados",
                    count: 45,
                    isSelected: selected == 1,
                    activeColor: .brandTeal,
                    activeBadgeColor: .brandTeal
                ) { selected = 1 }
            }
            .padding()
            .background(Color.appBackground.ignoresSafeArea())
        }
    }
    return PreviewWrapper()
}
