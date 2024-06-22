//
//  IntroLaunchView.swift
//  ViDrive
//
//  Created by David Holeman on 2/23/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct IntroLaunchView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var appStatus: AppStatus
    @State var isTerms: Bool = UserSettings.init().isTerms
    
    var body: some View {
        switch appStatus.currentIntroPageView {
        case .introStartView:
            IntroStartView()
        case .introAcceptTermsView:
            IntroAcceptTermsView(title: "Terms & Conditions", subtitle: "User assumes all risk and responsibility", webURL: AppValues.licenseURL, isAccepted: $isTerms)
        case .introCompleteView:
            IntroCompleteView()
        }
    } // end View

} // end OnboardLaunchView

#Preview {
    IntroLaunchView()
        .environmentObject(AppStatus())
        .environmentObject(UserSettings())
}
