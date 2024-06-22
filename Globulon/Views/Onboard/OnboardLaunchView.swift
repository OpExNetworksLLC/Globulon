//
//  OnboardLaunchView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct OnboardLaunchView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var appStatus: AppStatus
    
    var body: some View {
        switch appStatus.currentOnboardPageView {
        case .onboardStartView:
            OnboardStartView()
//        case .onboardTermsView:
//            OnboardTermsView()
        case .onboardAccountView:
            OnboardAccountView()
        case .onboardEmailView:
            OnboardEmailView()
        case .onboardPasswordView:
            OnboardPasswordView()
        case .onboardCompleteView:
            OnboardCompleteView()
        }
    } // end View

} // end OnboardLaunchView

#Preview {
    OnboardLaunchView()
        .environmentObject(AppStatus())
}
