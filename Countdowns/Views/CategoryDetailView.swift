//
//  CategoryDetailView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI
import Combine

struct CategoryDetailView: View {
    let category: EventCategory
    @EnvironmentObject var eventStore: EventStore
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var events: [Event] {
        eventStore.events(for: category)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Category Header
                HStack(spacing: 16) {
                    Image(systemName: category.icon)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                colors: [categoryColor.opacity(0.8), categoryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Events List
                if events.isEmpty {
                    VStack(spacing: 16) {
                        Text("No events in this category")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(events) { event in
                            DetailedEventCard(event: event)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top)),
                                    removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .trailing))
                                ))
                        }
                    }
                    .padding(.horizontal)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: events.map { $0.id })
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            // Force view update for countdown timers
        }
    }
    
    private var categoryColor: Color {
        switch category {
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

struct DetailedEventCard: View {
    let event: Event
    @EnvironmentObject var eventStore: EventStore
    @Environment(\.colorScheme) var colorScheme
    @State private var timeRemaining: TimeInterval = 0
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: event.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(categoryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                    
                    Text(event.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            
            // Countdown Timer
            HStack(spacing: 20) {
                if timeRemaining > 0 {
                    let days = Int(timeRemaining) / 86400
                    let hours = (Int(timeRemaining) % 86400) / 3600
                    let minutes = (Int(timeRemaining) % 3600) / 60
                    let seconds = Int(timeRemaining) % 60
                    
                    CountdownItem(value: days, label: "Days")
                    CountdownItem(value: hours, label: "Hours")
                    CountdownItem(value: minutes, label: "Mins")
                    CountdownItem(value: seconds, label: "Secs")
                } else {
                    Text("Today")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(categoryColor)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Date
            HStack {
                Spacer()
                Text(DateFormatter.abbreviatedDate.string(from: event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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

struct CountdownItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        CategoryDetailView(category: .anniversary)
            .environmentObject(EventStore())
    }
}
