//
//  ContentView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(LocalizationManager.languageKey) private var appLanguage = AppLanguage.english.rawValue

    var body: some View {
        MainTabView()
            .id(appLanguage)
            .environment(\.locale, Locale(identifier: appLanguage))
            .task {
                _ = await NotificationManager.shared.requestAuthorizationIfNeeded()
            }
            .onAppear {
                LocalizationManager.setLanguage(appLanguage)
            }
            .onChange(of: appLanguage) { newValue in
                LocalizationManager.setLanguage(newValue)
            }
    }
}

#Preview {
    ContentView()
}
