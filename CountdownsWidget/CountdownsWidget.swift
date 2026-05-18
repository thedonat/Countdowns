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
        upcomingEvents.first
    }

    var upcomingEvents: [Event] {
        Array(events.prefix(6))
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
            .filter { shouldIncludeInWidgets($0) }
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
        return removePastEventsIfNeeded(decoded, sharedDefaults: sharedDefaults)
    }

    private func removePastEventsIfNeeded(
        _ events: [Event],
        sharedDefaults: UserDefaults?
    ) -> [Event] {
        return events.filter { shouldIncludeInWidgets($0) }
    }

    private func shouldIncludeInWidgets(_ event: Event) -> Bool {
        let now = Date()
        if event.date >= now {
            return true
        }
        return Calendar.current.isDateInToday(event.date)
    }
}

// MARK: - 1) Nearest Event Widget (Small)

struct NearestEventWidget: Widget {
    let kind: String = "NearestEventWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownsProvider()) { entry in
            NearestEventWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Event")
        .description("Shows the nearest upcoming event.")
        .supportedFamilies([.systemSmall])
    }
}

struct NearestEventWidgetView: View {
    let entry: CountdownsEntry

    var body: some View {
        SmallNearestEventView(entry: entry)
    }
}

struct SmallNearestEventView: View {
    let entry: CountdownsEntry

    var body: some View {
        Group {
            if let event = entry.upcomingEvents.first {
                let categoryColor = categoryColor(for: event.category)
                let (valueText, label) = primaryCountdown(for: event)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Icon at top-left
                    Image(systemName: event.category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(categoryColor)
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    // Large number with full label or "Today"
                    if let label {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(valueText)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(categoryColor)
                                .minimumScaleFactor(0.5)
                            
                            Text(label)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(categoryColor.opacity(0.8))
                        }
                    } else {
                        Text(valueText)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(categoryColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    
                    Spacer().frame(height: 2)
                    
                    // Event name at bottom
                    Text(event.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(4)
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

private struct CountdownItem: View {
    let value: Int
    let label: LocalizedStringKey
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
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct UpcomingEventsWidgetView: View {
    let entry: CountdownsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.upcomingEvents.isEmpty {
                EmptyStateView(title: "No Upcoming Events", subtitle: nil)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    // Events list - max 3 for medium, max 6 for large
                    let maxEvents = family == .systemLarge ? 6 : 3
                    VStack(spacing: 4) {
                        ForEach(entry.upcomingEvents.prefix(maxEvents)) { event in
                            UpcomingEventRowView(event: event)
                        }
                    }
                    .padding(.horizontal, family == .systemLarge ? 8 : 6)
                    .padding(.vertical, family == .systemLarge ? 8 : 6)
                }
                .containerBackground(for: .widget) {
                    Color.black.opacity(0.85)
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
        let (valueText, label) = primaryCountdownForList(for: event)

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
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.7)

                Text(DateFormatter.widgetMonthDay.string(from: event.date))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer(minLength: 2)

            // Countdown value
            HStack(spacing: 2) {
                Text(valueText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(categoryColor)
                    .minimumScaleFactor(0.7)

                if let label {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(cardBackgroundColor(for: event.category))
        .cornerRadius(12)
    }

    private func cardBackgroundColor(for category: EventCategory) -> Color {
        switch category {
        case .birthday: return Color(red: 0.45, green: 0.28, blue: 0.12) // Dark orange
        case .travel: return Color(red: 0.15, green: 0.25, blue: 0.4) // Dark blue
        case .event: return Color(red: 0.3, green: 0.25, blue: 0.4) // Dark purple
        case .wedding: return Color(red: 0.45, green: 0.2, blue: 0.25) // Dark red-pink
        case .holiday: return Color(red: 0.22, green: 0.16, blue: 0.08) // Dark brown
        case .anniversary: return Color(red: 0.45, green: 0.2, blue: 0.35) // Dark pink
        case .family: return Color(red: 0.15, green: 0.35, blue: 0.25) // Dark green
        case .payment: return Color(red: 0.4, green: 0.35, blue: 0.15) // Dark yellow
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
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

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

private func primaryCountdown(for event: Event) -> (valueText: String, label: String?) {
    let seconds = Int(event.timeRemaining)
    guard seconds > 0 else { return (NSLocalizedString("Today", comment: ""), nil) }
    
    let days = seconds / 86_400
    let hours = (seconds % 86_400) / 3_600
    let minutes = (seconds % 3_600) / 60
    
    // Önce gün göster
    if days > 0 {
        let label = days == 1
            ? NSLocalizedString("day", comment: "")
            : NSLocalizedString("days", comment: "")
        return ("\(days)", label)
    }

    // Aynı günse "Today"
    if Calendar.current.isDateInToday(event.date) {
        return (NSLocalizedString("Today", comment: ""), nil)
    }

    // Gün yoksa saat göster
    if hours > 0 {
        let label = hours == 1
            ? NSLocalizedString("hour", comment: "")
            : NSLocalizedString("hours", comment: "")
        return ("\(hours)", label)
    }
    
    // Saat yoksa dakika göster
    let label = minutes == 1
        ? NSLocalizedString("minute", comment: "")
        : NSLocalizedString("minutes", comment: "")
    return ("\(minutes)", label)
}

private func primaryCountdownForList(for event: Event) -> (valueText: String, label: String?) {
    let seconds = Int(event.timeRemaining)
    guard seconds > 0 else { return (NSLocalizedString("Today", comment: ""), nil) }
    
    let days = seconds / 86_400
    let hours = (seconds % 86_400) / 3_600
    let minutes = (seconds % 3_600) / 60
    
    // Önce gün göster
    if days > 0 {
        return ("\(days)", NSLocalizedString("days", comment: ""))
    }

    // Aynı günse "Today"
    if Calendar.current.isDateInToday(event.date) {
        return (NSLocalizedString("Today", comment: ""), nil)
    }

    // Gün yoksa saat göster
    if hours > 0 {
        return ("\(hours)", NSLocalizedString("hrs", comment: ""))
    }
    
    // Saat yoksa dakika göster
    return ("\(minutes)", NSLocalizedString("min", comment: ""))
}

// MARK: - Category Color Helper

private func categoryColor(for category: EventCategory) -> Color {
    switch category {
    case .event: return Color.purple
    case .birthday: return Color(red: 1.0, green: 0.6, blue: 0.25) // Light orange
    case .travel: return Color.blue
    case .wedding: return Color.red
    case .holiday: return Color(red: 0.4, green: 0.3, blue: 0.2) // Brown
    case .anniversary: return Color.pink.opacity(0.7) // Lighter pink
    case .family: return Color.green
    case .payment: return Color.yellow
    }
}
