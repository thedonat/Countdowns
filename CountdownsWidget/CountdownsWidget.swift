//
//  CountdownsWidget.swift
//  CountdownsWidget
//
//  Created by Burak Donat on 1/14/26.
//

import WidgetKit
import SwiftUI

// MARK: - Shared DateFormatters for widgets

extension DateFormatter {
    static let widgetAbbreviatedDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let widgetMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

// MARK: - Shared Entry & Provider

struct CountdownsEntry: TimelineEntry {
    let date: Date
    let events: [Event]
    let selectedCategory: EventCategory?

    var nearestEvent: Event? {
        events.first
    }

    var upcomingEvents: [Event] {
        Array(events.prefix(5))
    }

    var categoryEvents: [Event] {
        if let category = selectedCategory {
            return events.filter { $0.category == category }
        }
        return events
    }
}

struct CountdownsProvider: TimelineProvider {
    typealias Entry = CountdownsEntry

    // App Group ID must match both app & widget entitlements
    private let appGroupID = "group.appgroup.com"
    private let saveKey = "SavedEvents"

    func placeholder(in context: Context) -> CountdownsEntry {
        CountdownsEntry(
            date: Date(),
            events: [
                Event(name: "Sample Event", date: Date().addingTimeInterval(86400), category: .event)
            ],
            selectedCategory: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownsEntry) -> Void) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownsEntry>) -> Void) {
        let entry = createEntry()

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> CountdownsEntry {
        let events = loadEvents()
            .filter { !$0.isPast }
            .sorted { $0.date < $1.date }

        // Load selected category from shared UserDefaults (set from the app)
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        let selectedCategoryRaw = sharedDefaults?.string(forKey: "selectedCategory")
        let selectedCategory = selectedCategoryRaw.flatMap { EventCategory(rawValue: $0) }

        return CountdownsEntry(
            date: Date(),
            events: events,
            selectedCategory: selectedCategory
        )
    }

    private func loadEvents() -> [Event] {
        // Önce App Group üzerinden okumayı dene, olmazsa standart UserDefaults'tan dene
        let sharedDefaults = UserDefaults(suiteName: appGroupID)

        let data =
            sharedDefaults?.data(forKey: saveKey) ??
            UserDefaults.standard.data(forKey: saveKey)

        guard
            let data,
            let decoded = try? JSONDecoder().decode([Event].self, from: data)
        else {
            return []
        }
        return decoded
    }
}

// MARK: - 1) Nearest Event Widget (Small & Medium)

struct NearestEventWidget: Widget {
    let kind: String = "NearestEventWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownsProvider()) { entry in
            NearestEventWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Event")
        .description("Shows the nearest upcoming event.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NearestEventWidgetView: View {
    let entry: CountdownsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallNearestEventView(entry: entry)
        case .systemMedium:
            MediumNearestEventView(entry: entry)
        default:
            SmallNearestEventView(entry: entry)
        }
    }
}

struct SmallNearestEventView: View {
    let entry: CountdownsEntry

    var body: some View {
        Group {
            if let event = entry.nearestEvent {
                let categoryColor = categoryColor(for: event.category)
                let (value, label) = primaryCountdown(for: event)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Icon at top-left
                    Image(systemName: event.category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(categoryColor)
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    // Large number with full label
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(value)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(categoryColor)
                            .minimumScaleFactor(0.5)
                        
                        Text(label)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(categoryColor.opacity(0.8))
                    }
                    
                    Spacer().frame(height: 2)
                    
                    // Event name at bottom
                    Text(event.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                EmptyStateView(title: "No Events", subtitle: "Add events to see countdowns")
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            }
        }
    }
}

struct MediumNearestEventView: View {
    let entry: CountdownsEntry

    var body: some View {
        Group {
            if let event = entry.nearestEvent {
                let categoryColor = categoryColor(for: event.category)
                let timeComponents = timeComponents(for: event)
                
                VStack(spacing: 0) {
                    // Top section: Icon + Event name + Date
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: event.category.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(categoryColor)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(event.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            
                            Text(DateFormatter.widgetMonthDay.string(from: event.date))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom section: Countdown breakdown
                    HStack(spacing: 0) {
                        CountdownItem(value: timeComponents.days, label: "days", color: categoryColor)
                        CountdownItem(value: timeComponents.hours, label: "hrs", color: categoryColor)
                        CountdownItem(value: timeComponents.minutes, label: "min", color: categoryColor)
                        CountdownItem(value: timeComponents.seconds, label: "sec", color: categoryColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                EmptyStateView(title: "No Events", subtitle: "Add events to see countdowns")
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            }
        }
    }
}

private struct CountdownItem: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 2) Upcoming Events Widget (Medium)

struct UpcomingEventsWidget: Widget {
    let kind: String = "UpcomingEventsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownsProvider()) { entry in
            UpcomingEventsWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Events")
        .description("Shows upcoming events.")
        .supportedFamilies([.systemMedium])
    }
}

struct UpcomingEventsWidgetView: View {
    let entry: CountdownsEntry

    var body: some View {
        Group {
            if entry.upcomingEvents.isEmpty {
                EmptyStateView(title: "No Upcoming Events", subtitle: nil)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                let firstCategoryColor = categoryColor(for: entry.upcomingEvents.first!.category)

                VStack(alignment: .leading, spacing: 4) {
                    // Header
                    Text("UPCOMING EVENTS")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 6)
                        .padding(.top, 6)

                    // Events list - max 3 events
                    VStack(spacing: 4) {
                        ForEach(entry.upcomingEvents.prefix(3)) { event in
                            UpcomingEventRowView(event: event)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                }
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [firstCategoryColor.opacity(0.2), firstCategoryColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
    }
}

private struct UpcomingEventRowView: View {
    let event: Event
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let categoryColor = categoryColor(for: event.category)
        let (value, label) = primaryCountdownForList(for: event)

        HStack(spacing: 8) {
            // Icon in circle
            Image(systemName: event.category.icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(categoryColor)
                .clipShape(Circle())

            // Event name and date
            VStack(alignment: .leading, spacing: 1) {
                Text(event.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(DateFormatter.widgetMonthDay.string(from: event.date))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer(minLength: 2)

            // Countdown value
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(categoryColor)
                    .minimumScaleFactor(0.7)

                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(cardBackgroundColor(for: event.category))
        .cornerRadius(12)
    }

    private func cardBackgroundColor(for category: EventCategory) -> Color {
        switch category {
        case .birthday: return Color(red: 0.35, green: 0.25, blue: 0.45) // Dark purple-pink
        case .travel: return Color(red: 0.15, green: 0.25, blue: 0.4) // Dark blue
        case .event: return Color(red: 0.3, green: 0.25, blue: 0.4) // Dark purple
        case .wedding: return Color(red: 0.45, green: 0.2, blue: 0.25) // Dark red-pink
        case .holiday: return Color(red: 0.4, green: 0.3, blue: 0.15) // Dark orange
        case .anniversary: return Color(red: 0.15, green: 0.4, blue: 0.35) // Dark teal-green
        case .family: return Color(red: 0.35, green: 0.25, blue: 0.45) // Dark purple-pink
        case .payment: return Color(red: 0.4, green: 0.35, blue: 0.15) // Dark yellow
        case .other: return Color(red: 0.3, green: 0.3, blue: 0.3) // Dark gray
        }
    }
}

// MARK: - 3) Category Events Widget (Category-selectable list)

struct CategoryEventsWidget: Widget {
    let kind: String = "CategoryEventsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownsProvider()) { entry in
            CategoryEventsWidgetView(entry: entry)
        }
        .configurationDisplayName("Category Events")
        .description("Shows events filtered by a selected category.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct CategoryEventsWidgetView: View {
    let entry: CountdownsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            CategoryEventsMediumView(entry: entry)
        case .systemLarge:
            CategoryEventsLargeView(entry: entry)
        default:
            CategoryEventsMediumView(entry: entry)
        }
    }
}

struct CategoryEventsMediumView: View {
    let entry: CountdownsEntry

    var body: some View {
        Group {
            if let firstEvent = entry.categoryEvents.first {
                let category = entry.selectedCategory ?? firstEvent.category
                let categoryColor = categoryColor(for: category)
                let timeComponents = timeComponents(for: firstEvent)
                
                VStack(spacing: 0) {
                    // Top section: Icon + Event name + Date
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: category.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(categoryColor)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(firstEvent.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            
                            Text(DateFormatter.widgetMonthDay.string(from: firstEvent.date))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom section: Countdown breakdown
                    HStack(spacing: 0) {
                        CountdownItem(value: timeComponents.days, label: "days", color: categoryColor)
                        CountdownItem(value: timeComponents.hours, label: "hrs", color: categoryColor)
                        CountdownItem(value: timeComponents.minutes, label: "min", color: categoryColor)
                        CountdownItem(value: timeComponents.seconds, label: "sec", color: categoryColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                EmptyStateView(title: "No Events", subtitle: nil)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            }
        }
    }
}

struct CategoryEventsLargeView: View {
    let entry: CountdownsEntry

    var body: some View {
        Group {
            if entry.categoryEvents.isEmpty {
                EmptyStateView(title: "No Events", subtitle: nil)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                let firstCategoryColor = categoryColor(for: entry.categoryEvents.first!.category)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Header
                    Text("UPCOMING EVENTS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                    
                    // Events list
                    VStack(spacing: 8) {
                        ForEach(entry.categoryEvents.prefix(6)) { event in
                            UpcomingEventRowView(event: event)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [firstCategoryColor.opacity(0.2), firstCategoryColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
    }
}

// MARK: - Shared Small Views

private struct EmptyStateView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundColor(.secondary)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct EventRowView: View {
    let event: Event

    var body: some View {
        let categoryColor = categoryColor(for: event.category)
        let days = daysRemaining(for: event)
        
        HStack(spacing: 12) {
            Image(systemName: event.category.icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(categoryColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(DateFormatter.widgetMonthDay.string(from: event.date))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(days)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(categoryColor)
            
            Text("days")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}


// MARK: - Countdown Text Helper

private enum CountdownFormat {
    case smallLong   // "3 days" / "2 hours" / "5 min" / "Today"
    case medium      // "3d 2h" / "2h 5m" / "5m" / "Today"
    case compact     // "3d" / "2h" / "5m" / "Today"
}

private func countdownText(for event: Event, format: CountdownFormat) -> String {
    let seconds = Int(event.timeRemaining)

    guard seconds > 0 else { return "Today" }

    let days = seconds / 86_400
    let hours = (seconds % 86_400) / 3_600
    let minutes = (seconds % 3_600) / 60

    switch format {
    case .smallLong:
        if days > 0 { return "\(days) day" + (days == 1 ? "" : "s") }
        if hours > 0 { return "\(hours) hour" + (hours == 1 ? "" : "s") }
        if minutes > 0 { return "\(minutes) min" }
        return "Today"

    case .medium:
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "Today"

    case .compact:
        if days > 0 { return "\(days)d" }
        if hours > 0 { return "\(hours)h" }
        if minutes > 0 { return "\(minutes)m" }
        return "Today"
    }
}

// MARK: - Countdown Components Helper

private struct TimeComponents {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
}

private func timeComponents(for event: Event) -> TimeComponents {
    let seconds = Int(event.timeRemaining)
    guard seconds > 0 else {
        return TimeComponents(days: 0, hours: 0, minutes: 0, seconds: 0)
    }
    
    let days = seconds / 86_400
    let hours = (seconds % 86_400) / 3_600
    let minutes = (seconds % 3_600) / 60
    let secs = seconds % 60
    
    return TimeComponents(days: days, hours: hours, minutes: minutes, seconds: secs)
}

private func daysRemaining(for event: Event) -> Int {
    let seconds = Int(event.timeRemaining)
    guard seconds > 0 else { return 0 }
    return seconds / 86_400
}

private func primaryCountdown(for event: Event) -> (value: Int, label: String) {
    let seconds = Int(event.timeRemaining)
    guard seconds > 0 else { return (0, "days") }
    
    let days = seconds / 86_400
    let hours = (seconds % 86_400) / 3_600
    let minutes = (seconds % 3_600) / 60
    
    // Önce gün göster
    if days > 0 {
        return (days, days == 1 ? "day" : "days")
    }
    
    // Gün yoksa saat göster
    if hours > 0 {
        return (hours, hours == 1 ? "hour" : "hours")
    }
    
    // Saat yoksa dakika göster
    return (minutes, minutes == 1 ? "minute" : "minutes")
}

private func primaryCountdownForList(for event: Event) -> (value: Int, label: String) {
    let seconds = Int(event.timeRemaining)
    guard seconds > 0 else { return (0, "days") }
    
    let days = seconds / 86_400
    let hours = (seconds % 86_400) / 3_600
    let minutes = (seconds % 3_600) / 60
    
    // Önce gün göster
    if days > 0 {
        return (days, "days")
    }
    
    // Gün yoksa saat göster
    if hours > 0 {
        return (hours, "hrs")
    }
    
    // Saat yoksa dakika göster
    return (minutes, "min")
}

// MARK: - Category Color Helper

private func categoryColor(for category: EventCategory) -> Color {
    switch category {
    case .birthday: return Color.pink
    case .travel: return Color.blue
    case .event: return Color.purple
    case .wedding: return Color.red
    case .holiday: return Color.orange
    case .anniversary: return Color.green
    case .family: return Color.pink
    case .payment: return Color.yellow
    case .other: return Color.gray
    }
}
