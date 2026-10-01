import SwiftUI

struct MainTabView: View {
    @Environment(TabBarVisibility.self) private var tabBar
    @State private var selectedTab: Int = 0
    @State private var altoMenu: CGFloat = 58

    private let pestanas: [(icono: String, titulo: String)] = [
        ("house", "Ferias"),
        ("chart.bar", "Avance"),
        ("person", "Perfil"),
    ]

    private var notchCenter: CGFloat {
        let count = CGFloat(pestanas.count)
        return (CGFloat(selectedTab) + 0.5) / count
    }

    private var espacioMenu: CGFloat {
        tabBar.isHidden ? 0 : altoMenu
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            FairListView()
                .padding(.bottom, espacioMenu)
                .toolbar(.hidden, for: .tabBar)
                .tag(0)

            NavigationStack {
                MyProgressView()
            }
            .padding(.bottom, espacioMenu)
            .toolbar(.hidden, for: .tabBar)
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .padding(.bottom, espacioMenu)
            .toolbar(.hidden, for: .tabBar)
            .tag(2)
        }
        .tint(Color.brand)
        .overlay(alignment: .bottom) {
            if !tabBar.isHidden {
                barraInferior
            }
        }
        .onPreferenceChange(AltoMenuKey.self) { nuevo in
            if nuevo > 0 {
                altoMenu = nuevo
            }
        }
    }

    private var barraInferior: some View {
        HStack(spacing: 0) {
            ForEach(Array(pestanas.enumerated()), id: \.offset) { indice, pestana in
                Button {
                    selectedTab = indice
                } label: {
                    TabBarItem(
                        icon: pestana.icono,
                        label: pestana.titulo,
                        isSelected: selectedTab == indice,
                        activeColor: Color.brand
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(pestana.titulo)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: AltoMenuKey.self, value: proxy.size.height)
            }
        }
        .background {
            NotchedBarShape(
                cornerRadius: 22,
                notchRadius: 14,
                notchCenter: notchCenter
            )
            .fill(Color.cardBackground)
            .shadow(color: .black.opacity(0.10), radius: 10, y: -3)
            .ignoresSafeArea(edges: .bottom)
        }
        .overlay {
            GeometryReader { proxy in
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                    .position(x: proxy.size.width * notchCenter, y: 0)
            }
            .allowsHitTesting(false)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: selectedTab)
    }
}

private struct AltoMenuKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Barra a todo el ancho. Arriba redondeada, con la muesca; abajo recta, pegada al borde.
private struct NotchedBarShape: Shape {
    var cornerRadius: CGFloat
    var notchRadius: CGFloat
    var notchCenter: CGFloat

    var animatableData: CGFloat {
        get { notchCenter }
        set { notchCenter = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, rect.height / 2)
        let n = notchRadius
        let minCenter = rect.minX + r + n
        let maxCenter = rect.maxX - r - n
        let mid = min(max(rect.minX + rect.width * notchCenter, minCenter), maxCenter)
        let depth = n * 0.9

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        path.addLine(to: CGPoint(x: mid - n, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: mid + n, y: rect.minY),
            control1: CGPoint(x: mid - n * 0.45, y: depth),
            control2: CGPoint(x: mid + n * 0.45, y: depth)
        )
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
