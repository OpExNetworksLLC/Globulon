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
    
    @Published var currentOnboardPageView: OnboardPageView = .onboardStartView
    @Published var currentIntroPageView: IntroPageView = .introStartView
    
    @Published var isShowSideMenu: Bool = false
    @Published var selectedTab: Int = 0
    
}
