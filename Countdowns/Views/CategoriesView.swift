//
//  CategoriesView.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(EventCategory.allCases) { category in
                        NavigationLink(destination: CategoryDetailView(category: category)
                            .environmentObject(eventStore)
                            .environmentObject(themeManager)) {
                            CategoryCard(category: category, count: eventStore.eventCount(for: category))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CategoryCard: View {
    let category: EventCategory
    let count: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 32))
                .foregroundColor(categoryColor)
                .frame(width: 60, height: 60)
                .background(categoryColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("\(count) event\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .padding(.top, 8)
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [categoryColor.opacity(0.1), categoryColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.trailing)
            .frame(maxHeight: .infinity, alignment: .center),
            alignment: .trailing
        )
    }
    
    private var categoryColor: Color {
        switch category {
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

#Preview {
    CategoriesView()
        .environmentObject(EventStore())
}
