//
//  NewEventView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI

struct NewEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var eventStore: EventStore
    
    @State private var eventName = ""
    @State private var notes = ""
    @State private var selectedDate = Date()
    @State private var selectedCategory: EventCategory = .event
    @State private var showNameError = false
    @State private var currentPlaceholderIndex = 0
    @State private var placeholderTimer: Timer?
    
    private let placeholders = [
        ("🎂", "John's Birthday"),
        ("✈️", "Trip to Norway"),
        ("💍", "Wedding Anniversary"),
        ("🎉", "New Year Party"),
        ("🎓", "Graduation Day")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Grab Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Header
            HStack {
                Text("New Event")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Event Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Event Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ZStack(alignment: .leading) {
                            if eventName.isEmpty {
                                HStack(spacing: 4) {
                                    Text(placeholders[currentPlaceholderIndex].0)
                                    Text(placeholders[currentPlaceholderIndex].1)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .transition(.opacity)
                            }
                            
                            TextField("", text: $eventName)
                                .textFieldStyle(.plain)
                                .padding()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        
                        if showNameError {
                            Text("Event name cannot be empty")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
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
                    
                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
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
                                ForEach(Array(EventCategory.allCases.prefix(4))) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(Array(EventCategory.allCases.dropFirst(4))) { category in
                                    CategoryButton(
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
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
            }
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            )
            .scrollDismissesKeyboard(.never)
            
            Spacer()
            
            // Bottom Buttons
            HStack(spacing: 12) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray4))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        showNameError = true
                    } else {
                        let newEvent = Event(
                            name: trimmedName,
                            date: selectedDate,
                            category: selectedCategory,
                            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
                        )
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            eventStore.addEvent(newEvent)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Add")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .animation(nil, value: eventName)
        .onAppear {
            startPlaceholderAnimation()
        }
        .onDisappear {
            stopPlaceholderAnimation()
        }
        .onChange(of: eventName) { newValue in
            if newValue.isEmpty {
                startPlaceholderAnimation()
            } else {
                stopPlaceholderAnimation()
            }
        }
    }
    
    private func startPlaceholderAnimation() {
        stopPlaceholderAnimation()
        placeholderTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPlaceholderIndex = (currentPlaceholderIndex + 1) % placeholders.count
            }
        }
    }
    
    private func stopPlaceholderAnimation() {
        placeholderTimer?.invalidate()
        placeholderTimer = nil
    }
}

struct CategoryButton: View {
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
        case .payment: return Color.yellow
        case .other: return Color.gray
        }
    }
}

#Preview {
    NewEventView()
        .environmentObject(EventStore())
}
