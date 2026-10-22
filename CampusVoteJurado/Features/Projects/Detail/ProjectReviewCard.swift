import SwiftUI

/// Formulario de reseña: estrellas, aspectos destacados y comentario.
struct ProjectReviewCard: View {
    @Environment(\.locale) private var locale

    @Binding var stars: Int
    @Binding var comment: String
    @Binding var aspects: Set<String>

    let aspectOptions: [String]
    let highlightsKey: String
    let canSave: Bool
    let isSaving: Bool
    let commentHint: String?
    let onSave: () -> Void

    private var verdeAspecto: Color { .brandTeal }

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

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        stars = star
                    } label: {
                        Image(systemName: star <= stars ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundStyle(star <= stars ? Color.brand : Color.appNeutral)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .accessibilityLabel(L10n.format("%d estrellas", locale: locale, star))
                    .accessibilityValue(star == stars ? L10n.tr("Seleccionado", locale: locale) : "")
                    .accessibilityAddTraits(star == stars ? .isSelected : [])
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
                        .foregroundStyle(Color.appWarning)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(minHeight: 44)
            .background(
                Capsule().fill(selected ? verdeAspecto.opacity(0.12) : Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private func insertAspect(_ item: String) {
        let localizedItem = L10n.tr(item, locale: locale)
        let current = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.range(of: localizedItem, options: .caseInsensitive) != nil {
            return
        }
        let sentence = "\(localizedItem)."
        let next = current.isEmpty ? sentence : "\(current) \(sentence)"
        guard next.utf16.count <= 1000 else { return }
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
                .accessibilityLabel("Escribe un comentario")
                .scrollContentBackground(.hidden)
                .frame(minHeight: 88)
                .disabled(isSaving)
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
            var limited = String(newValue.prefix(1000))
            while limited.utf16.count > 1000 { limited.removeLast() }
            if limited != newValue { comment = limited }
        }
    }

    private var commentCount: Int {
        comment.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count
    }
}
