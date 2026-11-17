import Foundation

enum L10n {
    static func tr(_ key: String, locale: Locale) -> String {
        let language = locale.language.languageCode?.identifier == "en" ? "en" : "es"
        guard
            let path = Bundle.main.path(forResource: language, ofType: "lproj"),
            let bundle = Bundle(path: path),
            let stringsPath = bundle.path(forResource: "Localizable", ofType: "strings"),
            let table = NSDictionary(contentsOfFile: stringsPath) as? [String: String],
            let value = table[key]
        else { return key }
        return value
    }

    static func format(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        String(format: tr(key, locale: locale), locale: locale, arguments: arguments)
    }
}
