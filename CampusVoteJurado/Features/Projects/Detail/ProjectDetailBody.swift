import SwiftUI

/// Foto, datos del proyecto, video y después la descripción.
struct ProjectDetailBody: View {
    let detail: ProjectDetail
    let fairName: String?
    let photos: [String]
    @Binding var page: Int
    let access: ReviewAccess
    let onSelectPhoto: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !photos.isEmpty {
                ProjectGalleryBanner(urls: photos, page: $page, onSelect: onSelectPhoto)
            }
            identity
                .padding(.horizontal, 16)
            if let video = detail.videoUrl, let url = URL(string: video) {
                videoCard(url)
            }
            VStack(alignment: .leading, spacing: 16) {
                if let description = trimmed(detail.description) {
                    ProjectDetailCard {
                        ProjectDetailLabel(title: "Sobre el proyecto")
                        ProseText(text: description, font: .subheadline, expands: true)
                    }
                }
                if let page = detail.projectUrl, let url = URL(string: page) {
                    ProjectDetailCard {
                        ProjectDetailLabel(title: "ENLACE")
                        ProjectLinkRow(url: url)
                    }
                }
                FairReviewNotice(access: access)
            }
            .padding(.horizontal, 16)
        }
    }

    private func videoCard(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "video")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.12)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Presentación en video")
                        .font(.headline.weight(.bold))
                    Text("Conoce la propuesta del equipo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ProjectVideoBlock(url: url, poster: photos.first)
        }
        .padding(14)
        .premiumSurface()
        .padding(.horizontal, 16)
    }

    private var identity: some View {
        HStack(alignment: .top, spacing: 12) {
            if let logo = detail.logoUrl, !logo.isEmpty {
                ProjectLogoMark(urlString: logo)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(detail.name)
                    .font(.title3.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                if let fairName = trimmed(fairName) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        ProseText(text: fairName, font: .subheadline)
                    }
                }
                if let category = trimmed(detail.categoryName) {
                    meta("square.grid.2x2", category)
                }
                if let stand = trimmed(detail.standCode) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 18)
                        Text("Stand")
                            .font(.subheadline)
                        Text(stand)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private func meta(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private func trimmed(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }
}
