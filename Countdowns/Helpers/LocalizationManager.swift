//
//  LocalizationManager.swift
//  Countdowns
//
//  Created by Burak Donat on 1/18/26.
//

import Foundation
import ObjectiveC

private var localizationBundleKey: UInt8 = 0

private final class LocalizedBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &localizationBundleKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .turkish:
            return "Türkçe"
        }
    }
}

enum LocalizationManager {
    static let languageKey = "appLanguage"

    static func setLanguage(_ languageCode: String) {
        object_setClass(Bundle.main, LocalizedBundle.self)
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(Bundle.main, &localizationBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            objc_setAssociatedObject(Bundle.main, &localizationBundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    static func currentLanguageCode() -> String {
        UserDefaults.standard.string(forKey: languageKey) ?? AppLanguage.english.rawValue
    }

    static func localizedString(_ key: String) -> String {
        let code = currentLanguageCode()
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func localizedFormat(_ key: String, _ args: CVarArg...) -> String {
        let format = localizedString(key)
        return String(format: format, args)
    }
}
