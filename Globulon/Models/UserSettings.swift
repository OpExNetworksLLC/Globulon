//
//  UserSettings.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

/// These are settings the user or developer can change if exposed.  These settings can also be changed in code.  Each of thse settings store a
/// value in UserDefaults and can be accessed in a variety of ways and contexts.  If the value is first initialized a default value is set.  Changes to
/// a seting are saved by code here if set to a new value in the app
///
/// example(s):
///
///   Save a value:
///   ```
///   @EnvironmentObject var appSettings: AppSettings
///   appSettings.username = "Joe"
///   appSettings.isTracking = true
///   appSettings.landingPage = .home
///   ```
///   
///   ```
///   init() {
///     UserSettings.init().userMode = .development
///   }
///   ```
///
///
///   There are several ways and contexts in which one retieves values from settings.
///   Retrieve a value directly:
///
///   ```
///   let value = appSettings.username
///   ```
///   
///   ```
///   UserSettings.init().landingPage.description
///   ```
///
class UserSettings: ObservableObject {
    
    init() {
        self.username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
        
        self.isIntroduced = UserDefaults.standard.object(forKey: "isIntroduced") as? Bool ?? false
        self.isTracking = UserDefaults.standard.object(forKey: "isTracking") as? Bool ?? false
        self.isOnboarded = UserDefaults.standard.object(forKey: "isOnboarded") as? Bool ?? false
        self.isTerms = UserDefaults.standard.object(forKey: "isTerms") as? Bool ?? false
        self.isWelcomed = UserDefaults.standard.object(forKey: "isWelcomed") as? Bool ?? false
        self.isAccount = UserDefaults.standard.object(forKey: "isAccount") as? Bool ?? false
        self.isPrivacy = UserDefaults.standard.object(forKey: "isPrivacy") as? Bool ?? false
        self.isLicensed = UserDefaults.standard.object(forKey: "isLicensed") as? Bool ?? false
        self.isTracking = UserDefaults.standard.object(forKey: "isTracking") as? Bool ?? false

        self.isAutoBiometricLogin = UserDefaults.standard.object(forKey: "isAutoBiometricLogin") as? Bool ?? false
        
        self.isBiometricID = UserDefaults.standard.object(forKey: "isBiometricID") as? Bool ?? false
        
        self.landingPage = LandingPageEnum(rawValue: UserDefaults.standard.integer(forKey: "landingPage")) ?? .home
        
        self.isFaqExpanded = UserDefaults.standard.object(forKey: "isFaqExpanded") as? Bool ?? false

        self.avatar = UIImage(data: UserDefaults.standard.object(forKey: "avatar") as? Data ?? AppDefaults.avatar.pngData()!) ?? AppDefaults.avatar
        
        self.alias = UserDefaults.standard.object(forKey: "alias") as? String ?? ""
        self.birthday = UserDefaults.standard.object(forKey: "birthday") as? Date ?? DateInfo.zeroDate
        
        self.email = UserDefaults.standard.object(forKey: "email") as? String ?? ""
        
        self.firstname = UserDefaults.standard.object(forKey: "firstname") as? String ?? ""
        self.lastname = UserDefaults.standard.object(forKey: "lastname") as? String ?? ""
        self.phoneCell = UserDefaults.standard.object(forKey: "phoneCell") as? String ?? ""

        self.articlesDate = UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
        
        self.articlesLocation = ArticleLocations(rawValue: UserDefaults.standard.integer(forKey: "articlesLocation")) ?? .local
        
        self.userMode = UserModeEnum(rawValue: UserDefaults.standard.integer(forKey: "userMode")) ?? .development

        /// GPS Tracking
        self.trackingSampleRate = UserDefaults.standard.object(forKey: "trackingSampleRate") as? Int ?? AppDefaults.gps.sampleRate
        self.trackingTripSeparator = UserDefaults.standard.object(forKey: "trackingTripSeparator") as? Int ?? AppDefaults.gps.tripSeparator
        self.trackingSpeedThreshold = UserDefaults.standard.object(forKey: "trackingSpeedThreshold") as? Double ?? AppDefaults.gps.speedThreshold
        self.trackingTripEntriesMin = UserDefaults.standard.object(forKey: "trackingTripEntriesMin") as? Int ?? AppDefaults.gps.tripEntriesMin
        self.tripGPSHistoryLimit = UserDefaults.standard.object(forKey: "tripGPSHistoryLimit") as? Int ?? AppDefaults.gps.tripGPSHistoryLimit
        self.tripHistoryLimit = UserDefaults.standard.object(forKey: "tripHistoryLimit") as? Int ?? AppDefaults.gps.tripHistoryLimit

        self.isTripReprocessingAllowed = UserDefaults.standard.object(forKey: "isTripReprocessingAllowed") as? Bool ?? true

        /// Firebase
        self.firebaseInstallationID = UserDefaults.standard.object(forKey: "firebaseInstallationID") as? String ?? ""
    }
    
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
            logChange(forKey: "username", value: username)
        }
    }
    @Published var isOnboarded: Bool {
        didSet {
            UserDefaults.standard.set(isOnboarded, forKey: "isOnboarded")
            logChange(forKey: "isOnboarded", value: isOnboarded)
        }
    }
    @Published var isTerms: Bool {
        didSet {
            UserDefaults.standard.set(isTerms, forKey: "isTerms")
            logChange(forKey: "isTerms", value: isTerms)
        }
    }
    @Published var isWelcomed: Bool {
        didSet {
            UserDefaults.standard.set(isWelcomed, forKey: "isWelcomed")
            logChange(forKey: "isWelcomed", value: isWelcomed)
        }
    }
    @Published var isAccount: Bool {
        didSet {
            UserDefaults.standard.set(isAccount, forKey: "isAccount")
            logChange(forKey: "isAccount", value: isAccount)
        }
    }
    @Published var isPrivacy: Bool {
        didSet {
            UserDefaults.standard.set(isPrivacy, forKey: "isPrivacy")
            logChange(forKey: "isPrivacy", value: isPrivacy)
        }
    }
    @Published var isLicensed: Bool {
        didSet {
            UserDefaults.standard.set(isLicensed, forKey: "isLicensed")
            logChange(forKey: "isLicensed", value: isLicensed)
        }
    }
    @Published var isIntroduced: Bool {
        didSet {
            UserDefaults.standard.set(isIntroduced, forKey: "isIntroduced")
            logChange(forKey: "isIntroduced", value: isIntroduced)
        }
    }
    @Published var isTracking: Bool {
        didSet {
            UserDefaults.standard.set(isTracking, forKey: "isTracking")
            logChange(forKey: "isTracking", value: isTracking)
        }
    }

    /// GPS Tracking:
    ///
    @Published var trackingSampleRate: Int {
        didSet {
            UserDefaults.standard.set(trackingSampleRate, forKey: "trackingSampleRate")
            logChange(forKey: "trackingSampleRate", value: trackingSampleRate)
        }
    }
    @Published var trackingTripSeparator: Int {
        didSet {
            UserDefaults.standard.set(trackingTripSeparator, forKey: "trackingTripSeparator")
            logChange(forKey: "trackingTripSeparator", value: trackingTripSeparator)
        }
    }
    @Published var trackingSpeedThreshold: Double {
        didSet {
            UserDefaults.standard.set(trackingSpeedThreshold, forKey: "trackingSpeedThreshold")
            logChange(forKey: "trackingSpeedThreshold", value: trackingSpeedThreshold)
        }
    }
    @Published var trackingTripEntriesMin: Int {
        didSet {
            UserDefaults.standard.set(trackingTripEntriesMin, forKey: "trackingTripEntriesMin")
            logChange(forKey: "trackingTripEntriesMin", value: trackingTripEntriesMin)
        }
    }
    
    @Published var tripGPSHistoryLimit: Int {
        didSet {
            UserDefaults.standard.set(tripGPSHistoryLimit, forKey: "tripGPSHistoryLimit")
            logChange(forKey: "tripGPSHistoryLimit", value: tripGPSHistoryLimit)
        }
    }
    
    @Published var tripHistoryLimit: Int {
        didSet {
            UserDefaults.standard.set(tripHistoryLimit, forKey: "tripHistoryLimit")
            logChange(forKey: "tripHistoryLimit", value: tripHistoryLimit)
        }
    }
    
    @Published var isTripReprocessingAllowed: Bool {
        didSet {
            UserDefaults.standard.set(isTripReprocessingAllowed, forKey: "isTripReprocessingAllowed")
            logChange(forKey: "isTripReprocessingAllowed", value: isTripReprocessingAllowed)
        }
    }
    /// end Tracking
    
    // TODO: AutoLogin
    @Published var isAutoBiometricLogin: Bool {
        didSet {
            UserDefaults.standard.set(isAutoBiometricLogin, forKey: "isAutoBiometricLogin")
            logChange(forKey: "isAutoBiometricLogin", value: isAutoBiometricLogin)
        }
    }
    
    @Published var isBiometricID: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricID, forKey: "isBiometricID")
            logChange(forKey: "isBiometricID", value: isBiometricID)
        }
    }
    
    @Published var isFaqExpanded: Bool {
        didSet {
            UserDefaults.standard.set(isFaqExpanded, forKey: "isFaqExpanded")
            logChange(forKey: "isFaqExpanded", value: isFaqExpanded)
        }
    }
    
    @Published var avatar: UIImage {
        didSet {
            /// Convert to data using .pngData() on the image so it will store.  It won't take the UIImage straight up.
            let pngRepresentation = avatar.pngData()
            UserDefaults.standard.set(pngRepresentation, forKey: "avatar")
            logChange(forKey: "avatar", value: avatar)
        }
    }
    
    @Published var alias: String {
        didSet {
            UserDefaults.standard.set(alias, forKey: "alias")
            logChange(forKey: "alias", value: alias)
        }
    }
    @Published var birthday: Date {
        didSet {
            UserDefaults.standard.set(birthday, forKey: "birthday")
            logChange(forKey: "birthday", value: birthday)
        }
    }
    
    @Published var email: String {
        didSet {
            UserDefaults.standard.set(email, forKey: "email")
            logChange(forKey: "email", value: email)
        }
    }
    
    @Published var firstname: String {
        didSet {
            UserDefaults.standard.set(firstname, forKey: "firstname")
            logChange(forKey: "firstname", value: firstname)
        }
    }
    @Published var lastname: String {
        didSet {
            UserDefaults.standard.set(lastname, forKey: "lastname")
            logChange(forKey: "lastname", value: lastname)
        }
    }
    @Published var phoneCell: String {
        didSet {
            UserDefaults.standard.set(phoneCell, forKey: "phoneCell")
            logChange(forKey: "phoneCell", value: phoneCell)
        }
    }
    @Published var articlesDate: Date {
        didSet {
            UserDefaults.standard.set(articlesDate, forKey: "articlesDate")
            logChange(forKey: "articlesDate", value: articlesDate)
        }
    }

    @Published var articlesLocation: ArticleLocations {
        didSet {
            UserDefaults.standard.set(articlesLocation.rawValue, forKey: "articlesLocation")
            logChange(forKey: "articlesLocation", value: articlesLocation)
        }
    }

    @Published var landingPage: LandingPageEnum {
        didSet {
            UserDefaults.standard.set(landingPage.rawValue, forKey: "landingPage")
            logChange(forKey: "landingPage", value: landingPage)
        }
    }

    @Published var userMode: UserModeEnum {
        didSet {
            UserDefaults.standard.set(userMode.rawValue, forKey: "userMode")
            logChange(forKey: "userMode", value: userMode)
        }
    }
    
    /// Firebase
    @Published var firebaseInstallationID: String {
        didSet {
            UserDefaults.standard.set(firebaseInstallationID, forKey: "firebaseInstallationID")
            logChange(forKey: "firebaseIntallationID", value: firebaseInstallationID)
        }
    }

    func logChange(forKey: String, value: Any) {
        LogEvent.print(module: "UserSettings", message: "Saving: \(forKey) = \(value)")
    }
   
    static var appLogo = "appLogo"
    static var appLogoBlack = "appLogoBlack"
    static var appLogoWhite = "appLogoWhite"
    static var appLogoDarkMode = "appLogoDarkMode"
    static var appLogoTransparent = "appLogoTransparent"
}
