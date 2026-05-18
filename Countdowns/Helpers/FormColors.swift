//
//  FormColors.swift
//  Countdowns
//
//  Created by Burak Donat on 1/14/26.
//

import SwiftUI

enum FormColors {
    static func inputBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6).opacity(0.6)
    }

    static func unselectedCategoryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6).opacity(0.6)
    }
}
