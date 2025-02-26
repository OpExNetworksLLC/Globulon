//
//  IntroLaunchView.swift
//  Globulon
//
//  Created by David Holeman on 02/26/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
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
            IntroAcceptTermsView(title: "Terms & Conditions ELUA", subtitle: "User assumes all risk and responsibility", webURL: AppSettings.licenseURL, isAccepted: $isTerms)
        case .introCompleteView:
            IntroCompleteView()
        }
    } // end View

}

#Preview {
    IntroLaunchView()
        .environmentObject(AppStatus())
        .environmentObject(UserSettings())
}
