//
//  MasterView.swift
//  Globulon
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2025-02-25)
 - Note:
    - Version: 1.0.0 (2025-02-25)
        - (created)
*/

import SwiftUI
import Network

struct MasterView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var userStatus: UserStatus
    @EnvironmentObject var appStatus: AppStatus

    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var carPlayManager = CarPlayManager()
    
    @State private var isShowLaunchView = true
    @State var isLoggedIn = false
    @State var isTerms: Bool = UserSettings.init().isTerms

    init() {

    }
    
    var body: some View {
        VStack {
            if isShowLaunchView {
                LaunchView()
            } else if userSettings.isIntroduced == false && AppSettings.feature.isIntroductionEnabled == true {
                IntroLaunchView()
            } else if userSettings.isTerms == false && AppSettings.feature.isTermsEnabled == true {
                //TermsView()
                IntroAcceptTermsView(title: "Terms & Conditions ELUA", subtitle: "User assumes all risk and responsibility", webURL: AppSettings.licenseURL, isAccepted: $isTerms)
            } else if userSettings.isPermissions == false {
                //AuthTrackingView()
                PermissionsView()
            } else if userSettings.isGDPRConsent == false && AppSettings.feature.isGDPRConsentEnabled == true {
                GDPRConsentView()
            } else if userSettings.isOnboarded == false && AppSettings.feature.isOnboardingEnabled == true {
                OnboardLaunchView()
            } else if userSettings.isWelcomed == false && AppSettings.feature.isWelcomeEnabled == true {
                WelcomeView()
            } else if isLoggedIn == false && AppSettings.feature.isLoginEnabled == true {
                LoginView().navigationBarHidden(true)
            } else {
                MainView()
                    .task {
                        LogManager.event(module: "MainView.task", message: "▶️ starting...")

                        /// On a first or fresh reinstallation of the app the earlier intake steps don't automatically start the LocationManager.
                        /// We wait until here as this is a logical start point to kicking of various processes either for the first time or when
                        /// a user has begun to interact with the app.

                        if  !locationManager.updatesLive {
                            locationManager.startLocationUpdates()
                        }

                        /// Do stuff...
                    
                        LogManager.event(module: "MainView.task", message: "⏹️ ...finished")
                    }
            }
        }
//        .onAppear {
//            checkAutoLogin()
//        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isIntroduced")), perform: { _ in
            userSettings.isIntroduced = true
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isPermissions")), perform: { _ in
            userSettings.isPermissions = true
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isGDPRConsent")), perform: { _ in
            userSettings.isGDPRConsent = true
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isLaunchCompleted")), perform: { _ in
            isShowLaunchView.toggle()
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isTerms")), perform: { _ in
            userSettings.isTerms = true
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isOnboarded")), perform: { _ in
            userSettings.isOnboarded = true
            userStatus.isLoggedIn = true
            isLoggedIn = true
            LogManager.event(module: "MasterView.onReceive isOnboarded", message: "User successfully onboarded and logged in.")
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isWelcomed")), perform: { _ in
            userSettings.isWelcomed = true
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isLoggedIn")), perform: { _ in
            userStatus.isLoggedIn = true
            isLoggedIn = true
            LogManager.event(module: "MasterView.onReceive isLoggedIn", message: "User successfull logged in, userStatus.isLoggedIn = \(userStatus.isLoggedIn)")
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isLoggedOut")), perform: { _ in
            userStatus.isLoggedIn = false
            isLoggedIn = false
            LogManager.event(module: "MasterView.onReceive", message: "User successfully LOGGED OUT, appVariables.isLoggedIn = \(userStatus.isLoggedIn)")
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isReset")), perform: { _ in
            
            //TODO: make into a separate function.  Also create a broader function for a wider reset and one for a full reset of settings.
            //
            userSettings.isIntroduced = false
            userSettings.isOnboarded = false
            userSettings.isPermissions = false
            userSettings.isTerms = false
            userSettings.isWelcomed = false
            userSettings.isIntroduced = false
            userSettings.isGDPRConsent = false
            isLoggedIn = false
            appStatus.currentIntroPageView = .introStartView
            LogManager.event(module: "MasterView.onReceive isReset", message: "User declined terms, appStatus.isLoggedIn = \(isLoggedIn)")
        })
        
//        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isInternetAvailable")), perform: { _ in
//
//            print(">>> network status changed.")
//
//        })


    }
    
    private func checkAutoLogin() {
        
        if userSettings.isAutoLogin {
            isLoggedIn = true
            userStatus.isLoggedIn = true
            
            #if FIREBASE_ENABLED
            /// let's ensure we have the username and password to work with
            /*
            print("^firebase login info:")
            print("^username: \(username)")
            print("^userPassword: \(userPassword)")
            print("^password: \(password)")
            */
            #endif
        }
    }
}

#Preview {
    MasterView()
        .environmentObject(UserSettings())
        .environmentObject(AppStatus())
}
