//
//  MainTabView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var eventStore = EventStore()
    @StateObject private var themeManager = ThemeManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CountdownsView()
                .environmentObject(eventStore)
                .environmentObject(themeManager)
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Countdowns")
                }
                .tag(0)
            
            CategoriesView()
                .environmentObject(eventStore)
                .environmentObject(themeManager)
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Categories")
                }
                .tag(1)
            
            CalendarView()
                .environmentObject(eventStore)
                .environmentObject(themeManager)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)
            
            SettingsView()
                .environmentObject(themeManager)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

#Preview {
    MainTabView()
}
