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
            .filter { shouldShowEvent($0) }
            .sorted { $0.date < $1.date }
    }
    
    func events(for category: EventCategory) -> [Event] {
        events
            .filter { $0.category == category && shouldShowEvent($0) }
            .sorted { $0.date < $1.date }
    }
    
    func events(for date: Date) -> [Event] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date) && shouldShowEvent(event)
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
        events.filter { $0.category == category && shouldShowEvent($0) }.count
    }

    private func shouldShowEvent(_ event: Event) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Gelecekteki eventleri her zaman göster
        if event.date > now {
            return true
        }

        // Geçmiş eventleri kontrol et
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        // Eğer event bugün geçmişse ama gece yarısına kadar zaman varsa göster
        if event.date >= todayStart && event.date <= todayEnd && now < todayEnd {
            return true
        }

        // Diğer geçmiş eventleri gizle
        return false
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
        let currentYear = calendar.component(.year, from: now)
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
                category: .family
            ))
        }

        // Women's Day (March 8)
        if let womensDay = calendar.date(from: DateComponents(year: currentYear, month: 3, day: 8)),
           womensDay > now {
            suggestions.append(Event(
                name: "Women's Day",
                date: womensDay,
                category: .family
            ))
        }
        // Next year's Women's Day if current year has passed
        if let womensDayNext = calendar.date(from: DateComponents(year: currentYear + 1, month: 3, day: 8)) {
            suggestions.append(Event(
                name: "Women's Day",
                date: womensDayNext,
                category: .family
            ))
        }

        // Mother's Day (Second Sunday in May)
        if let mothersDay = findNthWeekdayInMonth(year: currentYear, month: 5, weekday: 1, nth: 2),
           mothersDay > now {
            suggestions.append(Event(
                name: "Mother's Day",
                date: mothersDay,
                category: .family
            ))
        }
        // Next year's Mother's Day
        if let mothersDayNext = findNthWeekdayInMonth(year: currentYear + 1, month: 5, weekday: 1, nth: 2) {
            suggestions.append(Event(
                name: "Mother's Day",
                date: mothersDayNext,
                category: .family
            ))
        }

        // Father's Day (Third Sunday in June)
        if let fathersDay = findNthWeekdayInMonth(year: currentYear, month: 6, weekday: 1, nth: 3),
           fathersDay > now {
            suggestions.append(Event(
                name: "Father's Day",
                date: fathersDay,
                category: .family
            ))
        }
        // Next year's Father's Day
        if let fathersDayNext = findNthWeekdayInMonth(year: currentYear + 1, month: 6, weekday: 1, nth: 3) {
            suggestions.append(Event(
                name: "Father's Day",
                date: fathersDayNext,
                category: .family
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

    private func findNthWeekdayInMonth(year: Int, month: Int, weekday: Int, nth: Int) -> Date? {
        let calendar = Calendar.current

        // Get the first day of the month
        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return nil
        }

        // Find the first occurrence of the desired weekday
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToAdd = (weekday - firstWeekday + 7) % 7

        guard let firstOccurrence = calendar.date(byAdding: .day, value: daysToAdd, to: firstOfMonth) else {
            return nil
        }

        // Add weeks to get the nth occurrence
        let weeksToAdd = nth - 1
        return calendar.date(byAdding: .weekOfMonth, value: weeksToAdd, to: firstOccurrence)
    }
}
