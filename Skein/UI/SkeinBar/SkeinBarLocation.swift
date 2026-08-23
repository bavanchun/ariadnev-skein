//
//  SkeinBarLocation.swift
//  Skein
//

import SwiftUI

/// Locations where the Skein Bar can appear.
enum SkeinBarLocation: Int, CaseIterable, Identifiable {
    /// The Skein Bar will appear in different locations based on context.
    case dynamic = 0

    /// The Skein Bar will appear centered below the mouse pointer.
    case mousePointer = 1

    /// The Skein Bar will appear centered below the Skein icon.
    case skeinIcon = 2

    var id: Int { rawValue }

    /// Localized string key representation.
    var localized: LocalizedStringKey {
        switch self {
        case .dynamic: "Dynamic"
        case .mousePointer: "Mouse pointer"
        case .skeinIcon: "Frost icon"
        }
    }
}
