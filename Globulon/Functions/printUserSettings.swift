//
//  printUserSettings.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func printUserSettings(description: String, indent: String) -> String {
    
    let appDescription = "[" + AppSettings.appName + "]" + " "
    var settingsString = "\n"
    
    settingsString = settingsString + appDescription + "\n"
    settingsString = settingsString + appDescription + description + ":\n"
    settingsString = settingsString + appDescription + indent + "isBiometricID ---> " + String(describing: UserDefaults.standard.object(forKey: "isBiometricID") as? Bool ?? false) + "\n"
    settingsString = settingsString + appDescription + indent + "isIntroduced ----> " + String(UserDefaults.standard.object(forKey: "isIntroduced") as? Bool ?? false) + "\n"
    settingsString = settingsString + appDescription + indent + "isTracking ------> " + String(UserDefaults.standard.object(forKey: "isTracking") as? Bool ?? false) + "\n"
    settingsString = settingsString + appDescription + indent + "isOnboarded -----> " + String(UserDefaults.standard.object(forKey: "isOnboarded") as? Bool ?? false) + "\n"
    settingsString = settingsString + appDescription + indent + "isTerms ---------> " + String(UserDefaults.standard.object(forKey: "isTerms") as? Bool ?? false) + "\n"
    settingsString = settingsString + appDescription + indent + "isWelcomed ------> " + String(UserDefaults.standard.object(forKey: "isWelcomed") as? Bool ?? false) + "\n"
    settingsString = settingsString + appDescription + indent + "isPrivacy -------> " + String(UserDefaults.standard.object(forKey: "isPrivacy") as? Bool ?? false) + "\n"
    settingsString = settingsString + appDescription + indent + "isLicense -------> " + String(UserDefaults.standard.object(forKey: "isLicensed") as? Bool ?? false) + "\n"
    settingsString = settingsString + appDescription + indent + "isGDPRPolicy ----> " + String(UserDefaults.standard.object(forKey: "isGDPRPolicy") as? Bool ?? false) + "\n"
   
    let landingPage = LandingPageEnum(rawValue: UserDefaults.standard.integer(forKey: "landingPage")) ?? .home
    settingsString = settingsString + appDescription + indent + "landingPage -----> " + "\(landingPage)" + "\n"
    
    // Retrieve the date from UserDefaults
    if let storedDate = (UserDefaults.standard.object(forKey: "articlesDate") as? Date) {
        // Use the storedDate
        settingsString = settingsString + appDescription + indent + "articlesDate ----> \(storedDate)" + "\n"

    } else {
        // Set zero date
        let storedDate = DateInfo.zeroDate
        settingsString = settingsString + appDescription + indent + "articlesDate ----> \(storedDate)" + "\n"
    }

    let articlesLocation = ArticleLocations(rawValue: UserDefaults.standard.integer(forKey: "articlesLocation")) ?? .local
    settingsString = settingsString + appDescription + indent + "articlesLocation > " + "\(articlesLocation)" + "\n"
    settingsString = settingsString + appDescription + indent + "isFaqExpanded ---> " + String(UserDefaults.standard.object(forKey: "isFaqExpanded") as? Bool ?? false) + "\n"
    
    settingsString = settingsString + appDescription + indent + "phoneCell -------> " + String(UserDefaults.standard.object(forKey: "phoneCell") as? String ?? "") + "\n"

    let userMode = UserModeEnum(rawValue: UserDefaults.standard.integer(forKey: "userMode")) ?? .development
    settingsString = settingsString + appDescription + indent + "userMode --------> " + "\(userMode)" + "\n"
    
    settingsString = settingsString + appDescription + indent + "database --------> " + String(UserDefaults.standard.object(forKey: "lastSchemaVersion") as? String ?? "") + "\n"
    
    // Retrieve the date
    if let storedDate = (UserDefaults.standard.object(forKey: "lastAuth") as? Date) {
        // Use the storedDate
        settingsString = settingsString + appDescription + indent + "lastAuth --------> \(storedDate)" + "\n"

    } else {
        // Set zero date
        let storedDate = DateInfo.zeroDate
        settingsString = settingsString + appDescription + indent + "lastAuth --------> \(storedDate)" + "\n"
    }
    
    // TODO: This is looking for the enum
    //let trackingSampleRate = TrackingSampleRateEnum(rawValue: UserDefaults.standard.integer(forKey: "trackingSampleRate")) ?? .five
    //settingsString = settingsString + appDescription + indent + "sampleRate ------> " + "\(trackingSampleRate.rawValue)" + "\n"
    //settingsString = settingsString + appDescription + indent + "minSamples ------> " + String(Int(UserDefaults.standard.object(forKey: "trackingTripEntriesMin") as? Int ?? 0)) + "\n"
    //settingsString = settingsString + appDescription + indent + "tipSeparator-----> " + String(Int(UserDefaults.standard.object(forKey: "trackingTripSeparator") as? Int ?? 0)) + "\n"
    // TODO: This is looking for the enum
    //let trackingSpeedThreshold = TrackingSpeedThresholdEnum(rawValue: UserDefaults.standard.double(forKey: "trackingSpeedThreshold")) ?? .mph05
    //settingsString = settingsString + appDescription + indent + "speedThreshold --> " + "\(trackingSpeedThreshold.rawValue)" + "\n"
    
    
    settingsString = settingsString + appDescription + indent + "" + "\n"
        
    return settingsString
}
