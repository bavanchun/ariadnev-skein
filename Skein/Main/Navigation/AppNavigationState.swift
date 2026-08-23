//
//  AppNavigationState.swift
//  Skein
//

import Combine

/// The model for app-wide navigation.
@MainActor
final class AppNavigationState: ObservableObject {
    @Published var isAppFrontmost = false
    @Published var isSettingsPresented = false
    @Published var isSkeinBarPresented = false
    @Published var isSearchPresented = false
    @Published var settingsNavigationIdentifier: SettingsNavigationIdentifier = .general
}
