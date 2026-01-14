//
//  SettingsView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
