import SwiftUI

struct ProjectRowCard: View {
    let project: Project
    let isEvaluated: Bool
    let goldBg: Color
    let goldTxt: Color
    let tealBg: Color
    let tealTxt: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let description = project.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let tableNumber = project.tableNumber {
                        Text(tableNumber)
                            .font(.caption).bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(goldBg)
                            .foregroundColor(goldTxt)
                            .cornerRadius(6)
                    }

                    if let category = project.category {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tealBg)
                            .foregroundColor(tealTxt)
                            .cornerRadius(6)
                    }
                }
            }

            Spacer()

            Image(systemName: isEvaluated ? "checkmark.circle.fill" : "chevron.right")
                .foregroundColor(isEvaluated ? .green : .gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
