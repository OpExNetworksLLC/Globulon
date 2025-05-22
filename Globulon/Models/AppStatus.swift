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
    
    /// Indicate where to start in the order of OnboardPageView enum
    @Published var currentOnboardPageView: OnboardPageView = .onboardStartView
    
    /// Indicate where to start in the order of the IntroPageView enum
    @Published var currentIntroPageView: IntroPageView = .introStartView
    
    /// Is the side menu showing or not
    @Published var isShowSideMenu: Bool = false
    
    /// Which app MainView tab is selected
    @Published var selectedTab: Int = 0
    
}
