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
    @State private var selectedWidgetCategory: EventCategory?
    
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
                
                Section(header: Text("Widget"), footer: Text("Select a category to filter events in the Extra Large widget. Leave empty to show all events.")) {
                    Picker("Widget Category", selection: Binding(
                        get: { eventStore.getSelectedCategoryForWidget() },
                        set: { newValue in
                            eventStore.setSelectedCategoryForWidget(newValue)
                            selectedWidgetCategory = newValue
                        }
                    )) {
                        Text("All Events").tag(nil as EventCategory?)
                        ForEach(EventCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category as EventCategory?)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                selectedWidgetCategory = eventStore.getSelectedCategoryForWidget()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(EventStore())
        .environmentObject(ThemeManager())
}
