import Foundation

/// Lee el String Catalog compilado para el idioma elegido en Preferencias.
/// Las vistas SwiftUI localizan sus literales con el Locale del entorno; esto
/// cubre las cadenas construidas en tiempo de ejecución y los errores propios.
enum L10n {
    static func tr(_ key: String, locale: Locale) -> String {
        let language = locale.language.languageCode?.identifier == "en" ? "en" : "es"
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func format(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        String(format: tr(key, locale: locale), locale: locale, arguments: arguments)
    }
}
