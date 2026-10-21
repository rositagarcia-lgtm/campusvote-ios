import SwiftUI

extension ProfileView {
    var activeFair: Fair? {
        fairsStore.activeFairs.first?.fair
    }

    var signedInUser: User? {
        if case .signedIn(let user) = session.phase { return user }
        return nil
    }

    var greetingName: String {
        let first = (profile?.firstName ?? signedInUser?.firstName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let last = (profile?.lastName ?? signedInUser?.lastName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if first.isEmpty { return last }
        if last.isEmpty || first.localizedCaseInsensitiveContains(last) { return first }
        return "\(first) \(last)"
    }

    var initials: String {
        let first = profile?.firstName ?? signedInUser?.firstName ?? ""
        let last = profile?.lastName ?? signedInUser?.lastName ?? ""
        let letters = [first, last].compactMap { $0.first }.map { String($0) }
        let text = letters.joined().uppercased()
        return text.isEmpty ? "·" : text
    }

    var institutionCode: String {
        let code = profile?.institutionalId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return code.isEmpty ? "—" : code
    }

    var institutionName: String {
        let name = (fairsStore.organizationName ?? InstitutionAppearance.name ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "—" : name
    }

    var institutionSite: String {
        let site = fairsStore.siteName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return site.isEmpty ? "—" : site
    }

    var institutionBadge: String? {
        switch InstitutionAppearance.kindLabel {
        case "Instituto de Educación Superior": return "Superior"
        case "Universidad": return "Universidad"
        case "Colegio": return "Colegio"
        case "Empresa": return "Empresa"
        case "Asociación": return "Asociación"
        default:
            let label = InstitutionAppearance.kindLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return label.isEmpty ? nil : label
        }
    }

    var focusCategory: String? {
        let names = projectsStore.pending.compactMap(\.categoryName).filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }
        let counts = Dictionary(grouping: names, by: { $0 }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    var pendingLine: String {
        let count = projectsStore.summary.pending
        if projectsStore.isLoading && projectsStore.projects.isEmpty {
            return L10n.tr("Cargando proyectos...", locale: locale)
        }
        if count == 0 {
            return L10n.tr("No tienes proyectos pendientes.", locale: locale)
        }
        if let focusCategory {
            return count == 1
                ? L10n.format("Tienes 1 proyecto pendiente en %@.", locale: locale, focusCategory)
                : L10n.format("Tienes %d proyectos pendientes en %@.", locale: locale, count, focusCategory)
        }
        return count == 1
            ? L10n.tr("Tienes 1 proyecto pendiente.", locale: locale)
            : L10n.format("Tienes %d proyectos pendientes.", locale: locale, count)
    }

    var progressValue: CGFloat {
        let total = projectsStore.summary.total
        guard total > 0 else { return 0 }
        return CGFloat(projectsStore.summary.rated) / CGFloat(total)
    }

    var activeFairDate: String? {
        guard let raw = activeFair?.startsAt, raw.count >= 10 else { return nil }
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        input.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = input.date(from: String(raw.prefix(10))) else { return nil }
        let output = DateFormatter()
        output.dateStyle = .short
        output.locale = locale
        output.timeZone = TimeZone(secondsFromGMT: 0)
        return output.string(from: date)
    }

    var rubricLine: String {
        if let focusCategory {
            return L10n.format("Califica y comenta los proyectos de la categoría %@.", locale: locale, focusCategory)
        }
        return L10n.tr("Califica y comenta los proyectos de tu feria.", locale: locale)
    }
}
