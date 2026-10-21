import SwiftUI

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let activeColor: Color

    // MARK: - Inicializador con valor por defecto
    init(
        icon: String,
        label: String,
        isSelected: Bool,
        activeColor: Color = .brand
    ) {
        self.icon = icon
        self.label = label
        self.isSelected = isSelected
        self.activeColor = activeColor
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .medium))
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .foregroundStyle(isSelected ? activeColor : Color.appNeutral)
            
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .tracking(0.2)
                .foregroundStyle(isSelected ? activeColor : Color.appNeutral)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? activeColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1), value: isSelected)
    }
}

// MARK: - Preview (Ahora compila sin errores)
#Preview {
    struct TabBarPreview: View {
        @State private var selectedTab = 0
        
        var body: some View {
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    TabBarItem(
                        icon: "chart.bar.fill",
                        label: "Evaluación",
                        isSelected: selectedTab == 0
                        // activeColor usa el valor por defecto (.brand)
                    )
                    .onTapGesture { selectedTab = 0 }
                    
                    TabBarItem(
                        icon: "doc.text.fill",
                        label: "Proyectos",
                        isSelected: selectedTab == 1,
                        activeColor: .brandTeal // Ejemplo de sobrescritura
                    )
                    .onTapGesture { selectedTab = 1 }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Color.cardBackground
                        .shadow(color: Color.brand.opacity(0.1), radius: 10, y: -4)
                )
            }
            .background(Color.appBackground.ignoresSafeArea())
        }
    }
    
    return TabBarPreview()
}
