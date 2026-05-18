//
//  CountdownsApp.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI

@main
struct CountdownsApp: App {
    init() {
        let language = UserDefaults.standard.string(forKey: LocalizationManager.languageKey)
            ?? AppLanguage.english.rawValue
        LocalizationManager.setLanguage(language)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
