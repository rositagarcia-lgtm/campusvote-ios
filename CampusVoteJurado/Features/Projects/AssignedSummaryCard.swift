import SwiftUI

struct AssignedSummaryCard: View {
    let rated: Int
    let total: Int
    let pending: Int

    private let naranja = Color(red: 0.85, green: 0.45, blue: 0.12)

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(rated) / Double(total)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            progressRing
            VStack(alignment: .leading, spacing: 6) {
                Text("AVANCE GENERAL")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(Color.appNeutral)
                Text(rated == 1 ? "1 proyecto evaluado" : "\(rated) proyectos evaluados")
                    .font(.subheadline.weight(.semibold))
                Text(pending == 1 ? "1 pendiente" : "\(pending) pendientes")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(naranja)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(naranja.opacity(0.12)))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appNeutral.opacity(0.1), lineWidth: 1))
    }

    private var progressRing: some View {
        ZStack {
            Circle().stroke(Color.brand.opacity(0.15), lineWidth: 6)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.brand, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(rated)/\(total)")
                    .font(.caption.weight(.semibold))
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.caption2)
                    .foregroundStyle(Color.appNeutral)
            }
        }
        .frame(width: 64, height: 64)
    }
}
