//
//  Event.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import Foundation

struct Event: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var date: Date
    var category: EventCategory
    var notes: String?
    var location: String?

    init(id: UUID = UUID(), name: String, date: Date, category: EventCategory, notes: String? = nil, location: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.category = category
        self.notes = notes
        self.location = location
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: date)
        return max(0, components.day ?? 0)
    }
    
    var timeRemaining: TimeInterval {
        max(0, date.timeIntervalSinceNow)
    }
    
    var isPast: Bool {
        date < Date()
    }
}

enum EventCategory: String, Codable, CaseIterable, Identifiable {
    case event = "Event"
    case birthday = "Birthday"
    case travel = "Travel"
    case wedding = "Wedding"
    case holiday = "Holiday"
    case anniversary = "Anniversary"
    case family = "Family"
    case payment = "Payment"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .birthday: return "birthday.cake"
        case .travel: return "airplane"
        case .event: return "calendar"
        case .wedding: return "heart.fill"
        case .holiday: return "star"
        case .anniversary: return "sparkles"
        case .family: return "heart.circle"
        case .payment: return "creditcard"
        case .other: return "mappin"
        }
    }
    
    var color: String {
        switch self {
        case .event: return "purple"
        case .birthday: return "pink"
        case .travel: return "blue"
        case .wedding: return "red"
        case .holiday: return "coral"
        case .anniversary: return "green"
        case .family: return "pink"
        case .payment: return "yellow"
        }
    }
}
