//
//  EventCategory+Colors.swift
//  Countdowns
//
//  Created by Burak Donat on 1/14/26.
//

import SwiftUI

extension EventCategory {
    var displayColor: Color {
        switch self {
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
}
