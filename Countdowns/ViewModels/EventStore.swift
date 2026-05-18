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
    private let deletedSuggestionsKey = "DeletedSuggestions"
    // App Group ID used for sharing data with widgets
    private let appGroupID = "group.appgroup.com"
    private let liveActivityPostEventDuration: TimeInterval = 3600
    
    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    init() {
        loadEvents()
        setupLiveActivityUpdates()
    }
    
    private func setupLiveActivityUpdates() {
        Task { @MainActor in
            LiveActivityManager.shared.startPeriodicUpdates { [weak self] in
                return self?.liveActivityEvents() ?? []
            }
        }
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
        // Check if this event needs a live activity
        Task { @MainActor in
            LiveActivityManager.shared.updateLiveActivities(for: self.liveActivityEvents())
        }
        scheduleNotification(for: event)
    }
    
    func deleteEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        saveEvents()
        
        // If deleted event is a quick add suggestion, mark it as deleted
        if let suggestionType = getSuggestionType(date: event.date, category: event.category) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year], from: event.date)
            if let year = components.year {
                let suggestionId = "\(suggestionType)_\(year)"
                markSuggestionAsDeleted(suggestionId)
            }
        }
        
        // End live activity if exists
        Task { @MainActor in
            LiveActivityManager.shared.endLiveActivity(for: event)
        }
        NotificationManager.shared.removeNotification(for: event)
    }
    
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
            // Restart live activity with updated event data
            Task { @MainActor in
                await LiveActivityManager.shared.restartLiveActivity(for: event)
            }
            scheduleNotification(for: event)
        }
    }
    
    func eventCount(for category: EventCategory) -> Int {
        events.filter { $0.category == category && shouldShowEvent($0) }.count
    }

    func rescheduleNotifications() {
        NotificationManager.shared.removeAllEventNotifications()
        for event in events {
            scheduleNotification(for: event)
        }
    }

    private func liveActivityEvents() -> [Event] {
        let now = Date()
        let cutoff = now.addingTimeInterval(-liveActivityPostEventDuration)
        return events
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
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

    private func scheduleNotification(for event: Event) {
        let leadHours = NotificationManager.shared.leadHours()
        Task {
            let allowed = await NotificationManager.shared.requestAuthorizationIfNeeded()
            guard allowed else { return }
            NotificationManager.shared.removeNotification(for: event)
            NotificationManager.shared.scheduleNotification(for: event, leadHours: leadHours)
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

        func nextFixedDate(month: Int, day: Int) -> Date? {
            let candidates = [currentYear, currentYear + 1]
            for year in candidates {
                if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
                   date > now {
                    return date
                }
            }
            return nil
        }

        // New Year
        if let newYear = nextFixedDate(month: 1, day: 1) {
            suggestions.append(Event(
                name: LocalizationManager.localizedString("New Year"),
                date: newYear,
                category: .holiday
            ))
        }

        // Valentine's Day (Anniversary)
        if let valentines = nextFixedDate(month: 2, day: 14) {
            suggestions.append(Event(
                name: LocalizationManager.localizedString("Valentine's Day"),
                date: valentines,
                category: .anniversary
            ))
        }

        // Eid al-Fitr (Ramadan Bayramı) - March 20
        if let eidAlFitr = nextFixedDate(month: 3, day: 20) {
            suggestions.append(Event(
                name: LocalizationManager.localizedString("Eid al-Fitr"),
                date: eidAlFitr,
                category: .holiday
            ))
        }

        // Mother's Day (Second Sunday in May)
        let mothersDayCurrent = findNthWeekdayInMonth(year: currentYear, month: 5, weekday: 1, nth: 2)
        let mothersDayNext = findNthWeekdayInMonth(year: currentYear + 1, month: 5, weekday: 1, nth: 2)
        if let mothersDay = mothersDayCurrent, mothersDay > now {
            suggestions.append(Event(
                name: LocalizationManager.localizedString("Mother's Day"),
                date: mothersDay,
                category: .family
            ))
        } else if let mothersDay = mothersDayNext {
            suggestions.append(Event(
                name: LocalizationManager.localizedString("Mother's Day"),
                date: mothersDay,
                category: .family
            ))
        }

        // Father's Day (Third Sunday in June)
        let fathersDayCurrent = findNthWeekdayInMonth(year: currentYear, month: 6, weekday: 1, nth: 3)
        let fathersDayNext = findNthWeekdayInMonth(year: currentYear + 1, month: 6, weekday: 1, nth: 3)
        if let fathersDay = fathersDayCurrent, fathersDay > now {
            suggestions.append(Event(
                name: LocalizationManager.localizedString("Father's Day"),
                date: fathersDay,
                category: .family
            ))
        } else if let fathersDay = fathersDayNext {
            suggestions.append(Event(
                name: LocalizationManager.localizedString("Father's Day"),
                date: fathersDay,
                category: .family
            ))
        }

        // World Cup 2026 (Opening Day)
        if let worldCup2026 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11)),
           worldCup2026 > now {
            suggestions.append(Event(
                name: LocalizationManager.localizedString("World Cup 2026"),
                date: worldCup2026,
                category: .event
            ))
        }

        // Filter out past dates, already added events, and deleted suggestions, sort by date, and return
        return suggestions
            .filter { suggestion in
                // Filter out past dates
                guard !suggestion.isPast else { return false }
                
                // Check if this suggestion was deleted
                let suggestionComponents = calendar.dateComponents([.year, .month, .day], from: suggestion.date)
                if let suggestionType = getSuggestionType(date: suggestion.date, category: suggestion.category),
                   let year = suggestionComponents.year {
                    let suggestionId = "\(suggestionType)_\(year)"
                    if isSuggestionDeleted(suggestionId) {
                        return false
                    }
                }
                
                // Check if this suggestion is already in the events list
                // Compare by suggestion type (based on date pattern and category) instead of name
                // to handle language changes
                let suggestionType = getSuggestionType(date: suggestion.date, category: suggestion.category)
                
                return !events.contains { event in
                    let eventComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
                    let eventType = getSuggestionType(date: event.date, category: event.category)
                    
                    // Match if same type and same year
                    return eventType == suggestionType &&
                           eventComponents.year == suggestionComponents.year
                }
            }
            .sorted { $0.date < $1.date }
    }
    
    // Helper function to identify suggestion type based on date pattern and category
    private func getSuggestionType(date: Date, category: EventCategory) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let month = components.month, let day = components.day else { return nil }
        
        // Fixed date suggestions
        if month == 1 && day == 1 && category == .holiday {
            return "new_year"
        }
        if month == 2 && day == 14 && category == .anniversary {
            return "valentines_day"
        }
        if month == 3 && day == 20 && category == .holiday {
            return "eid_al_fitr"
        }
        if month == 6 && day == 11 && category == .event {
            return "world_cup_2026"
        }
        
        // Variable date suggestions (check if date matches pattern)
        if category == .family {
            // Mother's Day: Second Sunday in May
            if month == 5 {
                let firstOfMay = calendar.date(from: DateComponents(year: components.year, month: 5, day: 1))
                if let firstOfMay = firstOfMay {
                    let firstWeekday = calendar.component(.weekday, from: firstOfMay)
                    let daysToAdd = (1 - firstWeekday + 7) % 7 // Days to first Sunday
                    if let firstSunday = calendar.date(byAdding: .day, value: daysToAdd, to: firstOfMay),
                       let secondSunday = calendar.date(byAdding: .weekOfMonth, value: 1, to: firstSunday) {
                        let secondSundayComponents = calendar.dateComponents([.day], from: secondSunday)
                        if secondSundayComponents.day == day {
                            return "mothers_day"
                        }
                    }
                }
            }
            
            // Father's Day: Third Sunday in June
            if month == 6 {
                let firstOfJune = calendar.date(from: DateComponents(year: components.year, month: 6, day: 1))
                if let firstOfJune = firstOfJune {
                    let firstWeekday = calendar.component(.weekday, from: firstOfJune)
                    let daysToAdd = (1 - firstWeekday + 7) % 7 // Days to first Sunday
                    if let firstSunday = calendar.date(byAdding: .day, value: daysToAdd, to: firstOfJune),
                       let thirdSunday = calendar.date(byAdding: .weekOfMonth, value: 2, to: firstSunday) {
                        let thirdSundayComponents = calendar.dateComponents([.day], from: thirdSunday)
                        if thirdSundayComponents.day == day {
                            return "fathers_day"
                        }
                    }
                }
            }
        }
        
        return nil
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
    
    // Helper functions to track deleted suggestions
    private func markSuggestionAsDeleted(_ suggestionId: String) {
        var deletedSuggestions = getDeletedSuggestions()
        deletedSuggestions.insert(suggestionId)
        UserDefaults.standard.set(Array(deletedSuggestions), forKey: deletedSuggestionsKey)
        sharedUserDefaults?.set(Array(deletedSuggestions), forKey: deletedSuggestionsKey)
    }
    
    private func isSuggestionDeleted(_ suggestionId: String) -> Bool {
        let deletedSuggestions = getDeletedSuggestions()
        return deletedSuggestions.contains(suggestionId)
    }
    
    private func getDeletedSuggestions() -> Set<String> {
        if let array = sharedUserDefaults?.array(forKey: deletedSuggestionsKey) as? [String] ??
            UserDefaults.standard.array(forKey: deletedSuggestionsKey) as? [String] {
            return Set(array)
        }
        return Set<String>()
    }
}
