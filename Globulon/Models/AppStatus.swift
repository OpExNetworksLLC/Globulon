//
//  AppStatus.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

/// Various global app states
///
class AppStatus: ObservableObject {
    
    /// Set the current xxxPageView from the relevant Enum
    ///
    @Published var currentOnboardPageView: OnboardPageView = .onboardStartView
    @Published var currentIntroPageView: IntroPageView = .introStartView
    
    @Published var isShowSideMenu: Bool = false
    @Published var selectedTab: Int = 0
    
}

class TripManager: ObservableObject {
    
    @Published var monthDatestamp: String?
    @Published var originationTimestamp: Date?
    @Published var journalEntryTimestamp: Date?
    
    @Published var latitude: Double?
    @Published var longitude: Double?
}

