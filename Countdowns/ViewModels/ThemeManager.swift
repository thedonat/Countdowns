//
//  ThemeManager.swift
//  Countdowns
//
//  Created by Burak Donat on 1/13/26.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @AppStorage("colorScheme") private var colorSchemeRawValue: String = "system"
    
    var colorScheme: ColorScheme? {
        get {
            switch colorSchemeRawValue {
            case "light":
                return .light
            case "dark":
                return .dark
            default:
                return nil // system
            }
        }
        set {
            switch newValue {
            case .light:
                colorSchemeRawValue = "light"
            case .dark:
                colorSchemeRawValue = "dark"
            case .none:
                colorSchemeRawValue = "system"
            @unknown default:
                colorSchemeRawValue = "system"
            }
            objectWillChange.send()
        }
    }
    
    func toggle() {
        switch colorScheme {
        case .light:
            colorScheme = .dark
        case .dark:
            colorScheme = .light
        case .none:
            // If system, default to dark
            colorScheme = .dark
        @unknown default:
            colorScheme = .dark
        }
    }
}
