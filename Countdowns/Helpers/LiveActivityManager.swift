//
//  LiveActivityManager.swift
//  Countdowns
//
//  Created by Burak Donat on 1/14/26.
//

import Foundation
import ActivityKit
import SwiftUI
import Combine

// MARK: - Activity Attributes (must match widget extension)
struct CountdownsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var eventDate: Date
        var isEnded: Bool
    }

    var eventId: String
    var eventName: String
    var categoryRawValue: String
    var categoryIcon: String
}

// MARK: - Live Activity Manager
@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var activeActivities: [String: Activity<CountdownsWidgetAttributes>] = [:]
    
    private var checkTimer: Timer?
    private let oneHourInSeconds: TimeInterval = 3600
    private let postEventDisplayDuration: TimeInterval = 3600
    
    private init() {
        restoreExistingActivities()
    }
    
    // MARK: - Public Methods
    
    func updateLiveActivities(for events: [Event]) {
        let now = Date()
        
        for event in events {
            let timeUntilEvent = event.date.timeIntervalSince(now)
            
            // Event is less than 1 hour away but more than 2 seconds - show countdown
            if timeUntilEvent > 2 && timeUntilEvent <= oneHourInSeconds {
                startLiveActivityIfNeeded(for: event)
            }
            // Event is about to start (< 2 seconds) or has started - mark as ended
            else if timeUntilEvent <= 2 && timeUntilEvent > -postEventDisplayDuration {
                markActivityAsEnded(for: event)
            }
            // Event started more than postEventDisplayDuration ago - end activity
            else if timeUntilEvent <= -postEventDisplayDuration {
                endLiveActivity(for: event)
            }
        }
        
        // End activities for events that no longer exist
        cleanupOrphanedActivities(existingEventIds: Set(events.map { $0.id.uuidString }))
    }
    
    func startLiveActivityIfNeeded(for event: Event) {
        let eventIdString = event.id.uuidString
        
        // Check if activity already exists - update it instead
        if activeActivities[eventIdString] != nil {
            updateExistingActivity(for: event)
            return
        }
        
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let attributes = CountdownsWidgetAttributes(
            eventId: eventIdString,
            eventName: event.name,
            categoryRawValue: event.category.rawValue,
            categoryIcon: event.category.icon
        )
        
        let contentState = CountdownsWidgetAttributes.ContentState(
            eventDate: event.date,
            isEnded: false
        )
        
        let content = ActivityContent(state: contentState, staleDate: event.date.addingTimeInterval(300))
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            activeActivities[eventIdString] = activity
            print("Started Live Activity for event: \(event.name)")
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    /// Update an existing Live Activity with new event data
    func updateExistingActivity(for event: Event) {
        let eventIdString = event.id.uuidString
        
        guard let activity = activeActivities[eventIdString] else {
            return
        }
        
        let contentState = CountdownsWidgetAttributes.ContentState(
            eventDate: event.date,
            isEnded: false
        )
        
        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: event.date.addingTimeInterval(300))
            )
            print("Updated Live Activity for event: \(event.name)")
        }
    }
    
    /// Restart a Live Activity (end and start new one)
    func restartLiveActivity(for event: Event) async {
        let eventIdString = event.id.uuidString
        
        // End existing activity if any
        if let activity = activeActivities[eventIdString] {
            await activity.end(nil, dismissalPolicy: .immediate)
            activeActivities.removeValue(forKey: eventIdString)
            print("Ended existing Live Activity for restart: \(event.name)")
        }
        
        // Check if event should have a Live Activity
        let now = Date()
        let timeUntilEvent = event.date.timeIntervalSince(now)
        
        if timeUntilEvent > 0 && timeUntilEvent <= oneHourInSeconds {
            // Start new activity
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                return
            }
            
            let attributes = CountdownsWidgetAttributes(
                eventId: eventIdString,
                eventName: event.name,
                categoryRawValue: event.category.rawValue,
                categoryIcon: event.category.icon
            )
            
            let contentState = CountdownsWidgetAttributes.ContentState(
                eventDate: event.date,
                isEnded: false
            )
            
            let content = ActivityContent(state: contentState, staleDate: event.date.addingTimeInterval(300))
            
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                activeActivities[eventIdString] = activity
                print("Restarted Live Activity for event: \(event.name)")
            } catch {
                print("Failed to restart Live Activity: \(error.localizedDescription)")
            }
        }
    }
    
    func markActivityAsEnded(for event: Event) {
        let eventIdString = event.id.uuidString
        
        guard let activity = activeActivities[eventIdString] else {
            return
        }
        
        let endedState = CountdownsWidgetAttributes.ContentState(
            eventDate: event.date,
            isEnded: true
        )
        
        Task {
            await activity.update(
                ActivityContent(state: endedState, staleDate: Date().addingTimeInterval(postEventDisplayDuration))
            )
        }
    }
    
    func endLiveActivity(for event: Event) {
        endLiveActivity(forEventId: event.id.uuidString)
    }
    
    func endLiveActivity(forEventId eventId: String) {
        guard let activity = activeActivities[eventId] else {
            return
        }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            await MainActor.run {
                activeActivities.removeValue(forKey: eventId)
            }
            print("Ended Live Activity for event ID: \(eventId)")
        }
    }
    
    func endAllActivities() {
        for (eventId, activity) in activeActivities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            activeActivities.removeValue(forKey: eventId)
        }
    }
    
    // MARK: - Private Methods
    
    private func restoreExistingActivities() {
        for activity in Activity<CountdownsWidgetAttributes>.activities {
            activeActivities[activity.attributes.eventId] = activity
        }
    }
    
    private func cleanupOrphanedActivities(existingEventIds: Set<String>) {
        let orphanedIds = Set(activeActivities.keys).subtracting(existingEventIds)
        
        for eventId in orphanedIds {
            endLiveActivity(forEventId: eventId)
        }
    }
    
    func startPeriodicUpdates(eventProvider: @escaping () -> [Event]) {
        checkTimer?.invalidate()
        
        // Check every 1 second for more responsive updates
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateLiveActivities(for: eventProvider())
            }
        }
        
        // Initial check
        updateLiveActivities(for: eventProvider())
    }
    
    func stopPeriodicUpdates() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
}
