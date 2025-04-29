//
//  VersionManager.swift
//  Globulon
//
//  Created by David Holeman on 4/29/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

@MainActor
class VersionManager: ObservableObject {
    
    static let shared = VersionManager()

    @Published var isVersionUpdate = false
    
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    static var build: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    static var release: String {
        return String(format: "%@.%@", version, build)
    }
    static var releaseDesc: String {
        return "\(version) (\(build))"
    }

    func print() {
        Swift.print(">>> App Version: \(Self.version), Build: \(Self.build), Release: \(Self.release)")
        Swift.print(">>> App Version String: \(Self.releaseDesc)")
    }
    
    func saveRelease() {
        UserDefaults.standard.set(Self.release, forKey: "app_release")
        LogEvent.print(module: "VersionManager.saveRelease()", message: "release saved: \(Self.release)")
    }
    
    func retrieveRelease() -> String {
        let savedRelease = UserDefaults.standard.string(forKey: "app_release") ?? ""
        /*
        if savedRelease.isEmpty {
            LogEvent.print(module: "VersionManager.retrieveRelease()", message: "blank")
        } else {
            LogEvent.print(module: "VersionManager.retrieveRelease()", message: "\(savedRelease)")
        }
        */
        return savedRelease
    }
    
    func isNewRelease() -> Bool {
        let savedRelease = retrieveRelease()

        if savedRelease.isEmpty {
            LogEvent.print(module: "VersionManager.isNewRelease()", message: "Saved app release is empty. Current release: \(Self.release)")
            return true
        }

        let isNew = Self.release.compare(savedRelease, options: .numeric) == .orderedDescending
        if isNew {
            LogEvent.print(module: "VersionManager.isNewRelease()", message: "Newer app release detected. Old: \(savedRelease), New: \(Self.release)")
        } else {
            LogEvent.print(module: "VersionManager.isNewRelease()", message: "No new app release. Current release: \(Self.release)")
        }

        return isNew
    }
    func checkRelease() -> Bool {
        if isNewRelease() {
            var result = retrieveRelease()
            if result.isEmpty {
                result = "\"\""
            }
            LogEvent.print(module: "VersionManager.checkRelease()", message: "A newer release was detected:  Old release: \(result) New release: \(Self.release)")
            saveRelease() // Save the current release since it's new
            return true
        } else {
            LogEvent.print(module: "VersionManager.checkRelease()", message: "\(Self.release) is not a new release.")
        }
        return false
    }
    
    func resetRelease() {
        UserDefaults.standard.removeObject(forKey: "app_release")
        LogEvent.print(module: "VersionManager.restRelease()", message: "app_release reset")

    }
    
}
