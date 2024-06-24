//
//  MasterView.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import Network

struct MasterView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var userStatus: UserStatus
    @EnvironmentObject var appStatus: AppStatus
    
    @State private var isShowLaunchView = true
    @State var isLoggedIn = false
    @State var isTerms: Bool = UserSettings.init().isTerms
    
    var body: some View {

        VStack {
            if isShowLaunchView {
                LaunchView()
            } else if userSettings.isIntroduced == false && AppSettings.isIntroductionEnabled == true {
                IntroLaunchView()
            } else if userSettings.isTerms == false && AppSettings.isTermsEnabled == true {
                //TermsView()
                IntroAcceptTermsView(title: "Terms & Conditions", subtitle: "User assumes all risk and responsibility", webURL: AppValues.licenseURL, isAccepted: $isTerms)
            } else if userSettings.isTracking == false {
                //AuthTrackingView()
                PermissionsView()
            } else if userSettings.isOnboarded == false && AppSettings.isOnboardingEnabled == true {
                OnboardLaunchView()
            } else if userSettings.isWelcomed == false && AppSettings.isWelcomeEnabled == true {
                WelcomeView()
            } else if isLoggedIn == false && AppSettings.isLoginEnabled == true {
                LoginView().navigationBarHidden(true)
            } else {
                MainView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isIntroduced")), perform: { _ in
            userSettings.isIntroduced = true
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isTracking")), perform: { _ in
            userSettings.isTracking = true
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
            LogEvent.print(module: "MasterView.onReceive isOnboarded", message: "User successfully onboarded and logged in.")
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isWelcomed")), perform: { _ in
            userSettings.isWelcomed = true
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isLoggedIn")), perform: { _ in
            userStatus.isLoggedIn = true
            isLoggedIn = true
            LogEvent.print(module: "MasterView.onReceive isLoggedIn", message: "User successfull logged in, userStatus.isLoggedIn = \(userStatus.isLoggedIn)")
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isLoggedOut")), perform: { _ in
            userStatus.isLoggedIn = false
            isLoggedIn = false
            LogEvent.print(module: "MasterView.onReceive", message: "User successfully LOGGED OUT, appVariables.isLoggedIn = \(userStatus.isLoggedIn)")
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isReset")), perform: { _ in
            userSettings.isOnboarded = false
            userSettings.isTerms = false
            userSettings.isWelcomed = false
            userSettings.isIntroduced = false
            //appStatus.isLoggedIn = false
            isLoggedIn = false
            //appStatus.currentPageView = .onboardStartView
            appStatus.currentIntroPageView = .introStartView
            LogEvent.print(module: "MasterView.onReceive isReset", message: "User declined terms, appStatus.isLoggedIn = \(isLoggedIn)")
        })
        
//        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("isInternetAvailable")), perform: { _ in
//            
//            print(">>> network status changed.")
//            
//        })


    }
}

#Preview {
    MasterView()
        .environmentObject(UserSettings())
        .environmentObject(AppStatus())
}
