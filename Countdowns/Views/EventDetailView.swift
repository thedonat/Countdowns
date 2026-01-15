//
//  EventDetailView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI
import Combine

struct EventDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var eventStore: EventStore
    
    let event: Event
    @State private var eventName: String
    @State private var notes: String
    @State private var location: String
    @State private var selectedDate: Date
    @State private var selectedCategory: EventCategory
    @State private var showDeleteAlert = false
    @State private var showSaveConfirm = false
    @State private var timeRemaining: TimeInterval = 0
    
    init(event: Event) {
        self.event = event
        _eventName = State(initialValue: event.name)
        _notes = State(initialValue: event.notes ?? "")
        _location = State(initialValue: event.location ?? "")
        _selectedDate = State(initialValue: event.date)
        _selectedCategory = State(initialValue: event.category)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Countdown Timer
                if timeRemaining > 0 {
                    let days = Int(timeRemaining) / 86400
                    let hours = (Int(timeRemaining) % 86400) / 3600
                    let minutes = (Int(timeRemaining) % 3600) / 60
                    let seconds = Int(timeRemaining) % 60
                    
                    HStack(spacing: 12) {
                        EventCountdownBox(value: days, label: "Days", color: categoryColor)
                        EventCountdownBox(value: hours, label: "Hours", color: categoryColor)
                        EventCountdownBox(value: minutes, label: "Mins", color: categoryColor)
                        EventCountdownBox(value: seconds, label: "Secs", color: categoryColor)
                    }
                    .padding(.horizontal)
                } else {
                    Text("Today")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(categoryColor)
                        .padding()
                }
                
                // Event Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Event Name", text: $eventName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date & Time")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                // Category
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ForEach(Array(EventCategory.allCases.prefix(5))) { category in
                                EventCategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            ForEach(Array(EventCategory.allCases.dropFirst(5))) { category in
                                EventCategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Image(systemName: "mappin")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))

                        TextField("Add location...", text: $location)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(.horizontal)

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Add a note...", text: $notes, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    showSaveConfirm = true
                }
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Event", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                eventStore.deleteEvent(event)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(event.name)\"? This action cannot be undone.")
        }
        .alert("Save Changes?", isPresented: $showSaveConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Save", role: .none) {
                saveEvent()
            }
        } message: {
            Text("Do you want to save the changes to this event?")
        }
        .onAppear {
            updateTimeRemaining()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTimeRemaining()
        }
    }
    
    private func saveEvent() {
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedName.isEmpty {
            var updatedEvent = event
            updatedEvent.name = trimmedName
            updatedEvent.date = selectedDate
            updatedEvent.category = selectedCategory
            updatedEvent.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            updatedEvent.location = trimmedLocation.isEmpty ? nil : trimmedLocation

            eventStore.updateEvent(updatedEvent)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = event.date.timeIntervalSinceNow
    }
    
    private var categoryColor: Color {
        switch selectedCategory {
        case .event: return Color.purple
        case .birthday: return Color.pink
        case .travel: return Color.blue
        case .wedding: return Color.red
        case .holiday: return Color(red: 0.4, green: 0.3, blue: 0.2) // Brown
        case .anniversary: return Color.green
        case .family: return Color.pink.opacity(0.7) // Lighter pink
        case .payment: return Color.yellow
        }
    }
}

struct EventCountdownBox: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct EventCategoryButton: View {
    let category: EventCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : categoryColor)
                
                Text(category.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.systemGray5)
                    }
                }
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryColor: Color {
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

#Preview {
    NavigationView {
        EventDetailView(event: Event(name: "Test Event", date: Date(), category: .event))
            .environmentObject(EventStore())
    }
}
