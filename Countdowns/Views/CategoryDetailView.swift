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
                        Text(category.localizedName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(eventCountText(events.count))
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
        category.displayColor
    }

    private func eventCountText(_ count: Int) -> String {
        if count == 1 {
            return LocalizationManager.localizedString("1 event")
        }
        return LocalizationManager.localizedFormat("%d events", count)
    }
}

#Preview {
    NavigationView {
        CategoryDetailView(category: .anniversary)
            .environmentObject(EventStore())
    }
}
