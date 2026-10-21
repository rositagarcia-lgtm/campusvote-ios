import SwiftUI

/// Formulario de reseña: estrellas, aspectos destacados y comentario.
struct ProjectReviewCard: View {
    @Environment(\.locale) private var locale

    @Binding var stars: Int
    @Binding var comment: String
    @Binding var aspects: Set<String>

    let aspectOptions: [String]
    let highlightsKey: String
    let fairIsClosed: Bool
    let canSave: Bool
    let isSaving: Bool
    let commentHint: String?
    let onSave: () -> Void

    private let verdeAspecto = Color(red: 0.13, green: 0.62, blue: 0.36)

    var body: some View {
        ProjectDetailCard {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tu reseña")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Evalúa el impacto y claridad del proyecto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if fairIsClosed {
                Text("Esta feria está cerrada.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        guard !fairIsClosed else { return }
                        stars = star
                    } label: {
                        Image(systemName: star <= stars ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundStyle(star <= stars ? Color.brandGold : Color.appNeutral)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .disabled(fairIsClosed)
                }

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.1f", Double(stars)))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("/ 5")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ProjectDetailLabel(title: "ASPECTOS DESTACADOS")
                ChipFlow(spacing: 8) {
                    ForEach(aspectOptions, id: \.self) { item in
                        aspectChip(item)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ProjectDetailLabel(title: "COMENTARIOS ADICIONALES")
                commentBox
                if let commentHint {
                    Text(commentHint)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Button(action: onSave) {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(Color.onBrand)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.bold))
                            Text("Guardar reseña")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
                .foregroundStyle(Color.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.brand.opacity(canSave ? 1 : 0.4))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .padding(.top, 4)
        }
    }

    private func aspectChip(_ item: String) -> some View {
        let selected = aspects.contains(item)
        return Button {
            guard !fairIsClosed else { return }
            if selected {
                aspects.remove(item)
            } else {
                aspects.insert(item)
                insertAspect(item)
            }
            UserDefaults.standard.set(Array(aspects), forKey: highlightsKey)
        } label: {
            HStack(spacing: 4) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                    Text(L10n.tr(item, locale: locale))
                } else {
                    Text(L10n.format("+ %@", locale: locale, L10n.tr(item, locale: locale)))
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? verdeAspecto : Color.secondary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(selected ? verdeAspecto.opacity(0.12) : Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .disabled(fairIsClosed)
    }

    private func insertAspect(_ item: String) {
        let localizedItem = L10n.tr(item, locale: locale)
        let current = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.range(of: localizedItem, options: .caseInsensitive) != nil {
            return
        }
        let sentence = "\(localizedItem)."
        let next = current.isEmpty ? sentence : "\(current) \(sentence)"
        guard next.count <= 1000 else { return }
        comment = next
    }

    private var commentBox: some View {
        ZStack(alignment: .topLeading) {
            if comment.isEmpty {
                Text("Escribe un comentario")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }

            TextEditor(text: $comment)
                .font(.subheadline)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 88)
                .disabled(fairIsClosed)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .overlay(alignment: .bottomTrailing) {
            Text("\(min(commentCount, 1000))/1000")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.trailing, 10)
                .padding(.bottom, 8)
        }
        .onChange(of: comment) { _, newValue in
            if newValue.count > 1000 {
                comment = String(newValue.prefix(1000))
            }
        }
    }

    private var commentCount: Int {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).count
    }
}
