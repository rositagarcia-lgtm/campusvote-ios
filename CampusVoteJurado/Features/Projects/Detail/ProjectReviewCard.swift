import SwiftUI
import UIKit

/// Hoja pegada al borde inferior, del ancho del teléfono.
struct ProjectReviewSheet: View {
    let name: String
    let summary: String?
    let imageURL: String?
    @Binding var stars: Int
    @Binding var comment: String
    let canSave: Bool
    let isSaving: Bool
    let commentHint: String?
    let errorMessage: String?
    let onSave: () -> Void
    let onClose: () -> Void

    @FocusState private var commentFocused: Bool
    @State private var keyboard: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let panelHeight = min(geo.size.height * 0.52 + keyboard, geo.size.height - 24)
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { onClose() }

                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color.primary.opacity(0.25))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 8)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ProjectReviewCard(
                                name: name,
                                summary: summary,
                                imageURL: imageURL,
                                stars: $stars,
                                comment: $comment,
                                canSave: canSave,
                                isSaving: isSaving,
                                commentHint: commentHint,
                                commentFocused: $commentFocused,
                                onSave: onSave
                            )
                            if let errorMessage, !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(Color.appDanger)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: max(panelHeight - 28 - keyboard, 0), alignment: .center)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
                .frame(maxWidth: .infinity)
                .frame(height: panelHeight)
                .background(Color.cardBackground)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 22,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 22,
                        style: .continuous
                    )
                )
                .ignoresSafeArea(edges: .bottom)
                .gesture(
                    DragGesture(minimumDistance: 12).onEnded { value in
                        if value.translation.height > 80 { onClose() }
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            keyboard = Self.overlap(note)
        }
    }

    private static func overlap(_ note: Notification) -> CGFloat {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let screen = (note.object as? UIScreen)?.bounds.height
                ?? UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.screen.bounds.height else { return 0 }
        return max(0, screen - frame.minY)
    }
}

/// Ficha corta, estrellas, comentario y envío.
struct ProjectReviewCard: View {
    @Environment(\.locale) private var locale

    let name: String
    let summary: String?
    let imageURL: String?
    @Binding var stars: Int
    @Binding var comment: String
    let canSave: Bool
    let isSaving: Bool
    let commentHint: String?
    var commentFocused: FocusState<Bool>.Binding
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryCard
            ratingBlock
            commentBlock
                .id("comment-field")
            sendButton
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var summaryCard: some View {
        HStack(alignment: .center, spacing: 10) {
            CoverImage(url: imageURL.flatMap(URL.init(string:)))
                .frame(width: 56, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                if let summary = trimmed(summary) {
                    ProseText(
                        text: summary,
                        font: .caption,
                        color: .secondary,
                        lineLimit: 2
                    )
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var ratingBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Tu calificación")
                .font(.subheadline.weight(.semibold))
            Text(stars == 0
                 ? "Elige de 1 a 5 estrellas"
                 : L10n.format("%d de 5 estrellas", locale: locale, stars))
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        stars = star
                    } label: {
                        Image(systemName: "star.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(star <= stars ? Color.brand : Color.appNeutral.opacity(0.35))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .accessibilityLabel(L10n.format("%d estrellas", locale: locale, star))
                }
            }
        }
    }

    private var commentBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Comentario")
                .font(.subheadline.weight(.semibold))
            TextField("¿Qué podrían mejorar? Sé concreto y respetuoso.", text: $comment, axis: .vertical)
                .lineLimit(2...4)
                .font(.subheadline)
                .focused(commentFocused)
                .disabled(isSaving)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .onChange(of: comment) { _, newValue in
                    var limited = String(newValue.prefix(1000))
                    while limited.utf16.count > 1000 { limited.removeLast() }
                    if limited != newValue { comment = limited }
                }
            if let commentHint {
                Text(commentHint)
                    .font(.caption2)
                    .foregroundStyle(Color.appWarning)
            }
            Text("Solo lo verá el equipo del proyecto.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var sendButton: some View {
        Button(action: onSave) {
            Group {
                if isSaving {
                    ProgressView().tint(Color.onBrand)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                            .font(.footnote.weight(.bold))
                        Text("Enviar mi opinión")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .foregroundStyle(Color.onBrand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brand.opacity(canSave ? 1 : 0.4))
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
    }

    private func trimmed(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }
}
