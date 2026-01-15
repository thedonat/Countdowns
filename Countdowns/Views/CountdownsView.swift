//
//  CountdownsView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI
import Combine

struct CountdownsView: View {
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showNewEvent = false
    @State private var showSuggestions = true
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quick Add Suggestions
                    if !eventStore.quickAddSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 8) {
                                Image(systemName: "star")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow)
                                Text("Quick Add Suggestions")
                                    .font(.headline)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.up")
                                    .rotationEffect(.degrees(showSuggestions ? 0 : 180))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showSuggestions.toggle()
                                }
                            }
                            
                            if showSuggestions {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(eventStore.quickAddSuggestions) { suggestion in
                                            QuickAddCard(event: suggestion)
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        eventStore.addEvent(suggestion)
                                                    }
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // My Countdowns Section
                    if !eventStore.sortedEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Countdowns")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(eventStore.sortedEvents) { event in
                                    NavigationLink(destination: EventDetailView(event: event)
                                        .environmentObject(eventStore)) {
                                        EventCard(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top)),
                                        removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .trailing))
                                    ))
                                }
                            }
                            .padding(.horizontal)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: eventStore.sortedEvents.map { $0.id })
                        }
                    } else {
                        // Empty State
                        VStack(spacing: 20) {
                            Spacer()
                                .frame(height: 100)
                            
                            Button(action: {
                                showNewEvent = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            
                            Text("No Events")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Tap + to add your first countdown")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Countdowns")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showNewEvent = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showNewEvent) {
                NewEventView()
                    .environmentObject(eventStore)
                    .environmentObject(themeManager)
            }
        }
        .onReceive(timer) { _ in
            // Force view update for countdown timers
        }
    }
}

struct QuickAddCard: View {
    let event: Event
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: event.category.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(categoryColor(for: event.category))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(event.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(DateFormatter.abbreviatedDate.string(from: event.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .frame(width: 140, height: 160)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func categoryColor(for category: EventCategory) -> Color {
        switch category {
        case .birthday: return Color.pink.opacity(0.8)
        case .travel: return Color.blue.opacity(0.8)
        case .event: return Color.purple.opacity(0.8)
        case .wedding: return Color.red.opacity(0.8)
        case .holiday: return Color(red: 0.4, green: 0.3, blue: 0.2).opacity(0.8) // Brown
        case .anniversary: return Color.green.opacity(0.8)
        case .family: return Color.pink.opacity(0.8)
        case .payment: return Color.yellow.opacity(0.8)
        }
    }
}

struct EventCard: View {
    let event: Event
    @EnvironmentObject var eventStore: EventStore
    @Environment(\.colorScheme) var colorScheme
    @State private var timeRemaining: TimeInterval = 0
    @State private var showDeleteAlert = false

    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon, name, category and action buttons
            HStack {
                // Category Icon
                Image(systemName: event.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(categoryColor(for: event.category))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Event Name and Category
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(event.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 8) {
                    NavigationLink(destination: EventDetailView(event: event)
                        .environmentObject(eventStore)) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }
            
            // Countdown Timer - 4 boxes
            if timeRemaining > 0 {
                let days = Int(timeRemaining) / 86400
                let hours = (Int(timeRemaining) % 86400) / 3600
                let minutes = (Int(timeRemaining) % 3600) / 60
                let seconds = Int(timeRemaining) % 60

                HStack(spacing: 8) {
                    CountdownBox(value: days, label: "Days", color: categoryColor(for: event.category))
                    CountdownBox(value: hours, label: "Hours", color: categoryColor(for: event.category))
                    CountdownBox(value: minutes, label: "Mins", color: categoryColor(for: event.category))
                    CountdownBox(value: seconds, label: "Secs", color: categoryColor(for: event.category))
                }
            } else {
                // Event has started
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(categoryColor(for: event.category))

                    Text("Started")
                        .font(.headline)
                        .foregroundColor(categoryColor(for: event.category))
                }
                .padding(.vertical, 8)
            }
            
            // Date
            HStack {
                Spacer()
                Text(DateFormatter.abbreviatedDate.string(from: event.date))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
        }
        .padding()
        .background(categoryColor(for: event.category).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
        }
    }
    
}

struct CountdownBox: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CountdownsView()
        .environmentObject(EventStore())
}
