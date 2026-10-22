import SwiftUI

struct FairReviewNotice: View {
    let access: ReviewAccess
    @Environment(\.locale) private var locale

    var body: some View {
        if let notice = access.notice(locale: locale) {
            Label(notice, systemImage: access.phase == .ended ? "lock" : "calendar.badge.clock")
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(AppSpacing.section)
                .frame(maxWidth: .infinity, alignment: .leading)
                .premiumSurface()
                .accessibilityElement(children: .combine)
        }
    }
}
