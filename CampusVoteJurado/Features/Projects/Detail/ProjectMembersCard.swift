import SwiftUI

struct ProjectMembersCard: View {
    let members: [ProjectDetail.Member]

    var body: some View {
        if !members.isEmpty {
            ProjectDetailCard {
                ProjectDetailLabel(title: "INTEGRANTES")
                ForEach(members) { member in
                    Text([member.firstName, member.lastName].compactMap { $0 }
                        .filter { !$0.isEmpty }.joined(separator: " "))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
