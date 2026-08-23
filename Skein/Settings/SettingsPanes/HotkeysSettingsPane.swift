//
//  HotkeysSettingsPane.swift
//  Skein
//

import SwiftUI

struct HotkeysSettingsPane: View {
    @EnvironmentObject var appState: AppState

    private var hotkeySettingsManager: HotkeySettingsManager {
        appState.settingsManager.hotkeySettingsManager
    }

    var body: some View {
        SkeinForm {
            SkeinSection("Menu Bar Sections") {
                hotkeyRecorder(forSection: .hidden)
                hotkeyRecorder(forSection: .alwaysHidden)
            }
            SkeinSection("Menu Bar Items") {
                hotkeyRecorder(forAction: .searchMenuBarItems)
            }
            SkeinSection("Other") {
                hotkeyRecorder(forAction: .enableSkeinBar)
                hotkeyRecorder(forAction: .showSectionDividers)
                hotkeyRecorder(forAction: .toggleApplicationMenus)
            }
        }
    }

    @ViewBuilder
    private func hotkeyRecorder(forAction action: HotkeyAction) -> some View {
        if let hotkey = hotkeySettingsManager.hotkey(withAction: action) {
            HotkeyRecorder(hotkey: hotkey) {
                switch action {
                case .toggleHiddenSection:
                    Text("Toggle the hidden section")
                case .toggleAlwaysHiddenSection:
                    Text("Toggle the always-hidden section")
                case .searchMenuBarItems:
                    Text("Search menu bar items")
                case .enableSkeinBar:
                    Text("Enable the Frost Bar")
                case .showSectionDividers:
                    Text("Show section dividers")
                case .toggleApplicationMenus:
                    Text("Toggle application menus")
                }
            }
        }
    }

    @ViewBuilder
    private func hotkeyRecorder(forSection name: MenuBarSection.Name) -> some View {
        if appState.menuBarManager.section(withName: name)?.isEnabled == true {
            if case .hidden = name {
                hotkeyRecorder(forAction: .toggleHiddenSection)
            } else if case .alwaysHidden = name {
                hotkeyRecorder(forAction: .toggleAlwaysHiddenSection)
            }
        }
    }
}
