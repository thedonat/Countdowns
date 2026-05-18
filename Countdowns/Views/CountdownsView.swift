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
    @State private var showSuccessAnimation = false
    @State private var showAddConfirmation = false
    @State private var selectedSuggestion: Event?
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quick Add Suggestions
                    // Temporarily hidden
                    if false && !eventStore.quickAddSuggestions.isEmpty {
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
                                                    selectedSuggestion = suggestion
                                                    showAddConfirmation = true
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
            .alert(
                LocalizationManager.localizedString("Add Event?"),
                isPresented: $showAddConfirmation,
                presenting: selectedSuggestion
            ) { suggestion in
                Button(LocalizationManager.localizedString("Cancel"), role: .cancel) {
                    selectedSuggestion = nil
                }
                Button(LocalizationManager.localizedString("Add")) {
                    if let suggestion = selectedSuggestion {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            eventStore.addEvent(suggestion)
                        }
                        // Show success animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSuccessAnimation = true
                        }
                        // Hide after 1.5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showSuccessAnimation = false
                            }
                        }
                        selectedSuggestion = nil
                    }
                }
            } message: { suggestion in
                Text(LocalizationManager.localizedFormat("Do you want to add \"%@\"?", suggestion.name))
            }
        }
        .overlay(
            // Success Animation Overlay
            Group {
                if showSuccessAnimation {
                    SuccessTickView()
                        .transition(.scale.combined(with: .opacity))
                }
            },
            alignment: .center
        )
        .onReceive(timer) { _ in
            // Force view update for countdown timers
        }
    }
}

struct SuccessTickView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 80, height: 80)
            
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
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
                .background(event.category.displayColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(event.name)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            
            Text(DateFormatter.abbreviatedDate.string(from: event.date))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .frame(width: 140, height: 160)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    .background(event.category.displayColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Event Name and Category
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(event.category.localizedName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action Buttons
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .frame(width: 30, height: 30)
                        .background(Color(.systemBackground).opacity(0.6))
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
            }
            
            // Countdown Timer - 4 boxes
            if timeRemaining > 0 {
                let days = Int(timeRemaining) / 86400
                let hours = (Int(timeRemaining) % 86400) / 3600
                let minutes = (Int(timeRemaining) % 3600) / 60
                let seconds = Int(timeRemaining) % 60

                HStack(spacing: 8) {
                    CountdownBox(value: days, label: "Days", color: event.category.displayColor)
                    CountdownBox(value: hours, label: "Hours", color: event.category.displayColor)
                    CountdownBox(value: minutes, label: "Mins", color: event.category.displayColor)
                    CountdownBox(value: seconds, label: "Secs", color: event.category.displayColor)
                }
            } else if Calendar.current.isDateInToday(event.date) {
                // Event started today
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(event.category.displayColor)

                    Text(LocalizationManager.localizedFormat("Started at %@", DateFormatter.abbreviatedTime.string(from: event.date)))
                        .font(.headline)
                        .foregroundColor(event.category.displayColor)
                }
                .padding(.vertical, 8)
            }
            
            // Date
            HStack {
                Spacer()
                Text(DateFormatter.abbreviatedDate.string(from: event.date))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [event.category.displayColor.opacity(0.1), event.category.displayColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
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
            Text(LocalizationManager.localizedFormat("Are you sure you want to delete \"%@\"? This action cannot be undone.", event.name))
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = event.timeRemaining
    }
    
}

struct CountdownBox: View {
    let value: Int
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
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
