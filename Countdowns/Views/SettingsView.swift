//
//  SettingsView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var eventStore: EventStore
    @AppStorage("notificationLeadHours") private var notificationLeadHours: Int = 4
    @AppStorage(LocalizationManager.languageKey) private var appLanguage = AppLanguage.english.rawValue
    @AppStorage("weekStart") private var weekStart: Int = 2
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    Picker("Color Scheme", selection: Binding(
                        get: {
                            themeManager.colorScheme == .light ? "light" :
                            themeManager.colorScheme == .dark ? "dark" : "system"
                        },
                        set: { newValue in
                            switch newValue {
                            case "light":
                                themeManager.colorScheme = .light
                            case "dark":
                                themeManager.colorScheme = .dark
                            default:
                                themeManager.colorScheme = nil
                            }
                        }
                    )) {
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                        Text("System").tag("system")
                    }
                }

                Section(header: Text("Language")) {
                    Picker("App Language", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                }

                Section(header: Text("Week Start")) {
                    Picker("Start of Week", selection: $weekStart) {
                        Text("Monday").tag(2)
                        Text("Sunday").tag(1)
                    }
                }

                Section(header: Text("Notifications")) {
                    Picker("Reminder Time", selection: $notificationLeadHours) {
                        ForEach([1, 2, 4, 6, 12, 24], id: \.self) { hours in
                            Text(reminderLabel(for: hours)).tag(hours)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: notificationLeadHours) { _ in
            eventStore.rescheduleNotifications()
        }
    }

    private func reminderLabel(for hours: Int) -> String {
        let hoursText = hours == 1
            ? LocalizationManager.localizedString("1 hour")
            : LocalizationManager.localizedFormat("%d hours", hours)
        if hours == 4 {
            return LocalizationManager.localizedFormat("%@ (Default)", hoursText)
        }
        return hoursText
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .environmentObject(EventStore())
}
