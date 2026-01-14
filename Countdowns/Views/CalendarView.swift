//
//  CalendarView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI
import Combine

struct CalendarView: View {
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Calendar Widget
                    VStack(spacing: 16) {
                        // Month Header
                        HStack {
                            Text(DateFormatter.monthYear.string(from: currentMonth))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation {
                                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                                    }
                                }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Calendar Grid
                        CalendarGridView(
                            month: currentMonth,
                            selectedDate: $selectedDate,
                            events: eventStore.events
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Upcoming Events
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming Events")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        let selectedEvents = eventStore.events(for: selectedDate)
                        
                        if selectedEvents.isEmpty {
                            Text("No events on this date")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(selectedEvents) { event in
                                    UpcomingEventRow(event: event)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Also show general upcoming events
                        let upcoming = eventStore.upcomingEvents(limit: 5)
                        if !upcoming.isEmpty && selectedEvents.isEmpty {
                            Divider()
                                .padding(.horizontal)
                            
                            ForEach(upcoming) { event in
                                UpcomingEventRow(event: event)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CalendarGridView: View {
    let month: Date
    @Binding var selectedDate: Date
    let events: [Event]
    
    private let calendar = Calendar.current
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday Headers
            HStack {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Days
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        hasEvent: hasEvent(on: date),
                        isCurrentMonth: calendar.isDate(date, equalTo: month, toGranularity: .month)
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
    }
    
    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstDay = calendar.dateInterval(of: .month, for: month)?.start else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysToSubtract = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDay) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = startDate
        
        for _ in 0..<42 { // 6 weeks
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return days
    }
    
    private func hasEvent(on date: Date) -> Bool {
        events.contains { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvent: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday ? .blue :
                        isCurrentMonth ? .primary : .secondary
                    )
                
                if hasEvent {
                    Circle()
                        .fill(isSelected ? .white : .blue)
                        .frame(width: 4, height: 4)
                } else {
                    Spacer()
                        .frame(height: 4)
                }
            }
            .frame(width: 40, height: 50)
            .background(
                isSelected ?
                Color.blue :
                (isToday ? Color.blue.opacity(0.1) : Color.clear)
            )
            .clipShape(Circle())
        }
        .opacity(isCurrentMonth ? 1 : 0.3)
    }
}

struct UpcomingEventRow: View {
    let event: Event
    @EnvironmentObject var eventStore: EventStore
    @State private var timeRemaining: TimeInterval = 0
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.category.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(categoryColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)

                Text(DateFormatter.monthDay.string(from: event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                if timeRemaining > 0 {
                    let days = Int(timeRemaining) / 86400
                    Text("\(days)d")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            updateTimeRemaining()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTimeRemaining()
        }
        .alert("Delete Event", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    eventStore.deleteEvent(event)
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(event.name)\"? This action cannot be undone.")
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = event.timeRemaining
    }
    
    private var categoryColor: Color {
        switch event.category {
        case .birthday: return Color.pink
        case .travel: return Color.blue
        case .event: return Color.purple
        case .wedding: return Color.red
        case .holiday: return Color.orange
        case .anniversary: return Color.green
        case .payment: return Color.yellow
        case .other: return Color.gray
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(EventStore())
        .environmentObject(ThemeManager())
}
