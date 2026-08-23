//
//  MigrationManager.swift
//  Skein
//

import Cocoa

@MainActor
struct MigrationManager {
    let appState: AppState
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
}

// MARK: - Migrate All

extension MigrationManager {
    /// Performs all migrations.
    static func migrateAll(appState: AppState) {
        let manager = MigrationManager(appState: appState)

        do {
            try performAll(blocks: [
                manager.migrate2_0_0,
                manager.migrate0_8_0,
                manager.migrate0_10_0,
                manager.migrate1_1_0,
            ])
        } catch {
            logError(error)
        }

        let results = [
            manager.migrate0_10_1(),
            manager.migrate0_11_10(),
        ]

        for result in results {
            switch result {
            case .success:
                break
            case .successButShowAlert(let alert):
                alert.runModal()
            case .failureAndLogError(let error):
                logError(error)
            }
        }
    }

    private static func logError(_ error: any Error) {
        Logger.migration.error("Migration failed with error: \(error)")
    }
}

// MARK: - Migrate 0.8.0

extension MigrationManager {
    /// Performs all migrations for the `0.8.0` release, catching any thrown
    /// errors and rethrowing them as a combined error.
    private func migrate0_8_0() throws {
        guard !Defaults.bool(forKey: .hasMigrated0_8_0) else {
            return
        }
        try MigrationManager.performAll(blocks: [
            migrateHotkeys0_8_0,
            migrateControlItems0_8_0,
            migrateSections0_8_0,
        ])
        Defaults.set(true, forKey: .hasMigrated0_8_0)
        Logger.migration.info("Successfully migrated to 0.8.0 settings")
    }

    // MARK: Migrate Hotkeys

    /// Migrates the user's saved hotkeys from the old method of storing
    /// them in their corresponding menu bar sections to the new method
    /// of storing them as stand-alone data in the `0.8.0` release.
    private func migrateHotkeys0_8_0() throws {
        let sectionsArray: [[String: Any]]
        do {
            guard let array = try getMenuBarSectionArray() else {
                return
            }
            sectionsArray = array
        } catch {
            throw MigrationError.hotkeyMigrationError(error)
        }

        // get the hotkey data from the hidden and always-hidden sections,
        // if available, and create equivalent key combinations to assign
        // to the corresponding hotkeys
        for name: MenuBarSection.Name in [.hidden, .alwaysHidden] {
            guard
                let sectionDict = sectionsArray.first(where: { $0["name"] as? String == name.deprecatedRawValue }),
                let hotkeyDict = sectionDict["hotkey"] as? [String: Int],
                let key = hotkeyDict["key"],
                let modifiers = hotkeyDict["modifiers"]
            else {
                continue
            }
            let keyCombination = KeyCombination(
                key: KeyCode(rawValue: key),
                modifiers: Modifiers(rawValue: modifiers)
            )
            let hotkeySettingsManager = appState.settingsManager.hotkeySettingsManager
            if case .hidden = name {
                if let hotkey = hotkeySettingsManager.hotkey(withAction: .toggleHiddenSection) {
                    hotkey.keyCombination = keyCombination
                }
            } else if case .alwaysHidden = name {
                if let hotkey = hotkeySettingsManager.hotkey(withAction: .toggleAlwaysHiddenSection) {
                    hotkey.keyCombination = keyCombination
                }
            }
        }
    }

    // MARK: Migrate Control Items

    /// Migrates the control items from their old serialized representations
    /// to their new representations in the `0.8.0` release.
    private func migrateControlItems0_8_0() throws {
        let sectionsArray: [[String: Any]]
        do {
            guard let array = try getMenuBarSectionArray() else {
                return
            }
            sectionsArray = array
        } catch {
            throw MigrationError.controlItemMigrationError(error)
        }

        var newSectionsArray = [[String: Any]]()

        for name in MenuBarSection.Name.allCases {
            guard
                var sectionDict = sectionsArray.first(where: { $0["name"] as? String == name.deprecatedRawValue }),
                var controlItemDict = sectionDict["controlItem"] as? [String: Any],
                // remove the "autosaveName" key from the dictionary
                let autosaveName = controlItemDict.removeValue(forKey: "autosaveName") as? String
            else {
                continue
            }

            let identifier = switch name {
            case .visible:
                ControlItem.Identifier.skeinIcon.deprecatedRawValue
            case .hidden:
                ControlItem.Identifier.hidden.deprecatedRawValue
            case .alwaysHidden:
                ControlItem.Identifier.alwaysHidden.deprecatedRawValue
            }

            // add the "identifier" key to the dictionary
            controlItemDict["identifier"] = identifier

            // migrate the old autosave name to the new autosave name in UserDefaults
            StatusItemDefaults.migrate(key: .preferredPosition, from: autosaveName, to: identifier)
            StatusItemDefaults.migrate(key: .visible, from: autosaveName, to: identifier)

            // replace the old "controlItem" dictionary with the new one
            sectionDict["controlItem"] = controlItemDict
            // add the section to the new array
            newSectionsArray.append(sectionDict)
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: newSectionsArray)
            Defaults.set(data, forKey: .sections)
        } catch {
            throw MigrationError.controlItemMigrationError(error)
        }
    }

    /// Migrates away from storing the menu bar sections in UserDefaults
    /// for the `0.8.0` release.
    private func migrateSections0_8_0() {
        Defaults.set(nil, forKey: .sections)
    }
}

// MARK: - Migrate 0.10.0

extension MigrationManager {
    /// Performs all migrations for the `0.10.0` release, catching any thrown
    /// errors and rethrowing them as a combined error.
    private func migrate0_10_0() throws {
        guard !Defaults.bool(forKey: .hasMigrated0_10_0) else {
            return
        }
        try MigrationManager.performAll(blocks: [
            migrateControlItems0_10_0,
        ])
        Defaults.set(true, forKey: .hasMigrated0_10_0)
        Logger.migration.info("Successfully migrated to 0.10.0 settings")
    }

    private func migrateControlItems0_10_0() throws {
        for identifier in ControlItem.Identifier.allCases {
            StatusItemDefaults.migrate(
                key: .preferredPosition,
                from: identifier.deprecatedRawValue,
                to: identifier.rawValue
            )
        }
    }
}

// MARK: - Migrate 0.10.1

extension MigrationManager {
    /// Performs all migrations for the `0.10.1` release.
    private func migrate0_10_1() -> MigrationResult {
        guard !Defaults.bool(forKey: .hasMigrated0_10_1) else {
            return .success
        }
        let result = migrateControlItems0_10_1()
        switch result {
        case .success, .successButShowAlert:
            Defaults.set(true, forKey: .hasMigrated0_10_1)
            Logger.migration.info("Successfully migrated to 0.10.1 settings")
        case .failureAndLogError:
            break
        }
        return result
    }

    private func migrateControlItems0_10_1() -> MigrationResult {
        var needsResetPreferredPositions = false

        for identifier in ControlItem.Identifier.allCases {
            if
                StatusItemDefaults[.visible, identifier.rawValue] == false,
                StatusItemDefaults[.preferredPosition, identifier.rawValue] == nil
            {
                needsResetPreferredPositions = true
            }
            StatusItemDefaults[.visible, identifier.rawValue] = nil
        }

        if needsResetPreferredPositions {
            for identifier in ControlItem.Identifier.allCases {
                StatusItemDefaults[.preferredPosition, identifier.rawValue] = nil
            }

            let alert = NSAlert()
            alert.messageText = "Due to a bug in the 0.10.0 release, the data for Skein's menu bar items was corrupted and their positions had to be reset."
            alert.informativeText = "Our sincerest apologies for the inconvenience."

            return .successButShowAlert(alert)
        }

        return .success
    }
}

// MARK: - Migrate 0.11.10

extension MigrationManager {
    private func migrate0_11_10() -> MigrationResult {
        guard !Defaults.bool(forKey: .hasMigrated0_11_10) else {
            return .success
        }
        let result = migrateAppearanceConfiguration0_11_10()
        switch result {
        case .success, .successButShowAlert:
            Defaults.set(true, forKey: .hasMigrated0_11_10)
            Logger.migration.info("Successfully migrated to 0.11.10 settings")
        case .failureAndLogError:
            break
        }
        return result
    }

    private func migrateAppearanceConfiguration0_11_10() -> MigrationResult {
        guard let oldData = Defaults.data(forKey: .menuBarAppearanceConfiguration) else {
            return .failureAndLogError(.appearanceConfigurationMigrationError(.missingConfiguration))
        }
        do {
            let oldConfiguration = try decoder.decode(MenuBarAppearanceConfigurationV1.self, from: oldData)
            let newConfiguration = with(MenuBarAppearanceConfigurationV2.defaultConfiguration) { configuration in
                let partialConfiguration = MenuBarAppearancePartialConfiguration(
                    hasShadow: oldConfiguration.hasShadow,
                    hasBorder: oldConfiguration.hasBorder,
                    borderColor: oldConfiguration.borderColor,
                    borderWidth: oldConfiguration.borderWidth,
                    tintKind: oldConfiguration.tintKind,
                    tintColor: oldConfiguration.tintColor,
                    tintGradient: oldConfiguration.tintGradient
                )
                configuration.lightModeConfiguration = partialConfiguration
                configuration.darkModeConfiguration = partialConfiguration
                configuration.staticConfiguration = partialConfiguration
                configuration.shapeKind = oldConfiguration.shapeKind
                configuration.fullShapeInfo = oldConfiguration.fullShapeInfo
                configuration.splitShapeInfo = oldConfiguration.splitShapeInfo
                configuration.isInset = oldConfiguration.isInset
            }
            let newData = try encoder.encode(newConfiguration)
            Defaults.set(newData, forKey: .menuBarAppearanceConfigurationV2)
        } catch {
            return .failureAndLogError(.appearanceConfigurationMigrationError(.otherError(error)))
        }
        return .success
    }
}

// MARK: - Migrate 1.1.0

extension MigrationManager {
    /// Performs all migrations for the `1.1.0` release, catching any thrown
    /// errors and rethrowing them as a combined error.
    private func migrate1_1_0() throws {
        guard !Defaults.bool(forKey: .hasMigrated1_1_0) else {
            return
        }
        try MigrationManager.performAll(blocks: [
            migrateSkeinIcon1_1_0,
        ])
        Defaults.set(true, forKey: .hasMigrated1_1_0)
        Logger.migration.info("Successfully migrated to 1.1.0 settings")
    }

    /// Migrates a saved Skein icon that names the retired ice cube image set
    /// to the snowflake image set that replaced it.
    ///
    /// The retired name is no longer a case of `ControlItemImageSet.Name`, so a
    /// saved icon that uses it can no longer be decoded. Left alone, the decode
    /// failure is only logged and the icon quietly reverts to the default,
    /// discarding a choice the user made. Any other icon that fails to decode is
    /// past repair and would be discarded the same way, so both are rewritten.
    private func migrateSkeinIcon1_1_0() throws {
        guard
            let data = Defaults.data(forKey: .skeinIcon),
            (try? decoder.decode(ControlItemImageSet.self, from: data)) == nil
        else {
            return
        }
        Defaults.set(try encoder.encode(ControlItemImageSet.snowflakeSkeinIcon), forKey: .skeinIcon)
        Logger.migration.info("Replaced an unreadable Skein icon with the snowflake icon")
    }
}

// MARK: - Migrate 2.0.0

extension MigrationManager {
    /// The defaults domain the app used before it was renamed to Skein.
    private static let frostDefaultsDomain = "com.vchun.Frost"

    /// Defaults keys whose stored name embedded the old product name.
    ///
    /// The values are untouched; only the key each one is filed under changes.
    private static let frostRenamedKeys = [
        "ShowFrostIcon": "ShowSkeinIcon",
        "FrostIcon": "SkeinIcon",
        "CustomFrostIconIsTemplate": "CustomSkeinIconIsTemplate",
        "UseFrostBar": "UseSkeinBar",
        "FrostBarLocation": "SkeinBarLocation",
        "FrostBarPinnedLocation": "SkeinBarPinnedLocation",
    ]

    /// The hotkey action identifier that embedded the old product name.
    private static let frostHotkeyAction = (old: "EnableFrostBar", new: "EnableSkeinBar")

    /// Performs all migrations for the `2.0.0` release, catching any thrown
    /// errors and rethrowing them as a combined error.
    private func migrate2_0_0() throws {
        guard !Defaults.bool(forKey: .hasMigrated2_0_0) else {
            return
        }
        try MigrationManager.performAll(blocks: [
            migrateDefaultsDomain2_0_0,
        ])
        Defaults.set(true, forKey: .hasMigrated2_0_0)
        Logger.migration.info("Successfully migrated to 2.0.0 settings")
    }

    /// Imports the settings the app stored while it was named Frost.
    ///
    /// Renaming the app changed its bundle identifier, and macOS files
    /// preferences under that identifier. Without this import every setting,
    /// the menu bar layout, and all hotkeys would silently reset on first
    /// launch, because the new domain simply starts empty.
    ///
    /// Values are copied verbatim under their new key names. A key already
    /// present in the new domain is never overwritten, which makes the import
    /// idempotent and stops it from clobbering anything the user changed after
    /// upgrading. The old domain is left in place so downgrading still works.
    private func migrateDefaultsDomain2_0_0() throws {
        guard
            let frostDefaults = UserDefaults.standard
                .persistentDomain(forName: MigrationManager.frostDefaultsDomain)
        else {
            // A fresh install has nothing to import.
            return
        }

        var imported = 0
        for (key, value) in frostDefaults {
            let newKey = MigrationManager.frostRenamedKeys[key] ?? key
            guard UserDefaults.standard.object(forKey: newKey) == nil else {
                continue
            }
            UserDefaults.standard.set(value, forKey: newKey)
            imported += 1
        }

        migrateHotkeyAction2_0_0()

        Logger.migration.info("Imported \(imported) settings from the Frost defaults domain")
    }

    /// Refiles the saved hotkey whose action identifier embedded the old
    /// product name.
    ///
    /// Hotkeys are stored as a dictionary keyed by `HotkeyAction.rawValue`.
    /// That raw value is persisted data, so renaming the case without moving
    /// the stored entry would drop the user's hotkey on the floor.
    private func migrateHotkeyAction2_0_0() {
        let (old, new) = MigrationManager.frostHotkeyAction
        guard
            var hotkeys = Defaults.dictionary(forKey: .hotkeys) as? [String: Data],
            let data = hotkeys[old]
        else {
            return
        }
        if hotkeys[new] == nil {
            hotkeys[new] = data
        }
        hotkeys[old] = nil
        Defaults.set(hotkeys, forKey: .hotkeys)
        Logger.migration.info("Refiled the saved hotkey from \(old) to \(new)")
    }
}

// MARK: - Helpers

extension MigrationManager {
    /// Performs every block in the given array, catching any thrown
    /// errors and rethrowing them as a combined error.
    private static func performAll(blocks: [() throws -> Void]) throws {
        let results = blocks.map { block in
            Result(catching: block)
        }
        let errors = results.compactMap { result in
            if case .failure(let error) = result {
                return error
            }
            return nil
        }
        if !errors.isEmpty {
            throw MigrationError.combinedError(errors)
        }
    }

    /// Returns an array of dictionaries that represent the sections in
    /// the menu bar, as stored in UserDefaults.
    private func getMenuBarSectionArray() throws -> [[String: Any]]? {
        guard let data = Defaults.data(forKey: .sections) else {
            return nil
        }
        let object = try JSONSerialization.jsonObject(with: data)
        guard let array = object as? [[String: Any]] else {
            throw MigrationError.invalidMenuBarSectionsJSONObject(object)
        }
        return array
    }
}

// MARK: - MigrationResult

extension MigrationManager {
    enum MigrationResult {
        case success
        case successButShowAlert(NSAlert)
        case failureAndLogError(MigrationError)
    }
}

// MARK: - Errors

extension MigrationManager {
    enum MigrationError: Error, CustomStringConvertible {
        case invalidMenuBarSectionsJSONObject(Any)
        case hotkeyMigrationError(any Error)
        case controlItemMigrationError(any Error)
        case appearanceConfigurationMigrationError(AppearanceConfigurationMigrationError)
        case combinedError([any Error])

        var description: String {
            switch self {
            case .invalidMenuBarSectionsJSONObject(let object):
                "Invalid menu bar sections JSON object: \(object)"
            case .hotkeyMigrationError(let error):
                "Error migrating hotkeys: \(error)"
            case .controlItemMigrationError(let error):
                "Error migrating control items: \(error)"
            case .appearanceConfigurationMigrationError(let error):
                "Error migrating menu bar appearance configuration: \(error)"
            case .combinedError(let errors):
                "The following errors occurred: \(errors)"
            }
        }
    }

    enum AppearanceConfigurationMigrationError: Error, CustomStringConvertible {
        case otherError(any Error)
        case missingConfiguration

        var description: String {
            switch self {
            case .otherError(let error):
                error.localizedDescription
            case .missingConfiguration:
                "Missing menu bar appearance configuration"
            }
        }
    }
}

// MARK: - ControlItem.Identifier Extension

private extension ControlItem.Identifier {
    var deprecatedRawValue: String {
        switch self {
        case .skeinIcon: "IceIcon"
        case .hidden: "HItem"
        case .alwaysHidden: "AHItem"
        }
    }
}

// MARK: - MenuBarSection.Name Extension

private extension MenuBarSection.Name {
    var deprecatedRawValue: String {
        switch self {
        case .visible: "Visible"
        case .hidden: "Hidden"
        case .alwaysHidden: "Always Hidden"
        }
    }
}

// MARK: - Logger
private extension Logger {
    static let migration = Logger(category: "Migration")
}
