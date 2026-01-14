//
//  EventStore.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import Foundation
import SwiftUI
import Combine
import WidgetKit

class EventStore: ObservableObject {
    @Published var events: [Event] = []
    
    private let saveKey = "SavedEvents"
    // App Group ID used for sharing data with widgets
    private let appGroupID = "group.appgroup.com"
    
    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    init() {
        loadEvents()
    }
    
    var sortedEvents: [Event] {
        events
            .filter { !$0.isPast }
            .sorted { $0.date < $1.date }
    }
    
    func events(for category: EventCategory) -> [Event] {
        events
            .filter { $0.category == category && !$0.isPast }
            .sorted { $0.date < $1.date }
    }
    
    func events(for date: Date) -> [Event] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    func upcomingEvents(limit: Int = 10) -> [Event] {
        Array(sortedEvents.prefix(limit))
    }
    
    func addEvent(_ event: Event) {
        events.append(event)
        saveEvents()
    }
    
    func deleteEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        saveEvents()
    }
    
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
        }
    }
    
    func eventCount(for category: EventCategory) -> Int {
        events.filter { $0.category == category && !$0.isPast }.count
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            // Save to both standard and shared UserDefaults
            UserDefaults.standard.set(encoded, forKey: saveKey)
            sharedUserDefaults?.set(encoded, forKey: saveKey)
            
            // Reload all widget timelines so they see latest events
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func loadEvents() {
        // Try to load from shared UserDefaults first, then fallback to standard
        if let data = sharedUserDefaults?.data(forKey: saveKey) ?? UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
    }
    
    func setSelectedCategoryForWidget(_ category: EventCategory?) {
        if let category = category {
            sharedUserDefaults?.set(category.rawValue, forKey: "selectedCategory")
        } else {
            sharedUserDefaults?.removeObject(forKey: "selectedCategory")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func getSelectedCategoryForWidget() -> EventCategory? {
        guard let rawValue = sharedUserDefaults?.string(forKey: "selectedCategory") else {
            return nil
        }
        return EventCategory(rawValue: rawValue)
    }
}

// Quick Add Suggestions
extension EventStore {
    var quickAddSuggestions: [Event] {
        let calendar = Calendar.current
        let now = Date()
        var suggestions: [Event] = []
        
        // New Year 2027
        if let newYear2027 = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1)) {
            suggestions.append(Event(
                name: "New Year 2027",
                date: newYear2027,
                category: .holiday
            ))
        }

        // Valentine's Day 2026
        if let valentines2026 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 14)) {
            suggestions.append(Event(
                name: "Valentine's Day",
                date: valentines2026,
                category: .anniversary
            ))
        }

        // Summer Vacation (July 1, 2026)
        if let summerVacation = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)) {
            suggestions.append(Event(
                name: "Summer Vacation",
                date: summerVacation,
                category: .travel
            ))
        }
        
        // Filter out past dates and return
        return suggestions.filter { !$0.isPast }
    }
}
