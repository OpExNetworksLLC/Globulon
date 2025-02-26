//
//  OnboardStartView.swift
//  Globulon
//
//  Created by David Holeman on 02/26/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct OnboardStartView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStatus: AppStatus
        
    var body: some View {
        HStack {
            Spacer().frame(width: 16)
            
            VStack(alignment: .leading) {
                
              Spacer().frame(height: 60)
                Image(colorScheme == .dark ? .appLogoDarkMode : .appLogoTransparent)
                //Image(AppValue.appLogo)
                    .resizable()
                    .frame(width: 124, height: 124, alignment: .center)
                    .offset(x: 8)
                    .padding(.bottom, 16)
                Text("Welcome to \(AppSettings.appName)")
                    .font(.system(size: 24))
                    //.fontWeight(.regular)
                    .padding(.bottom, 16)
                Text("Thank you for chosing to use the \(AppSettings.appName) app.  We hope you will enjoy using it.")
                    .padding(.bottom, 16)
                Text("Since you are just getting started we have a short journey to setup your account.  Let's get started.")
                    .padding(.bottom, 16)

                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        /// Goto next page if this button is clicked
                        //appStatus.currentOnboardPageView = .onboardTermsView
                        appStatus.currentOnboardPageView = .onboardAccountView

                    }
                    ) {
                        HStack {
                            Text("Let's get started")
                                .foregroundColor(.txtNextOnboarding)
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(.btnNextOnboarding)
                                .cornerRadius(30)
                        }
                    }
                } // end HStack
                Spacer().frame(height: 30)
            } // end VStack
            Spacer().frame(width: 16)
        } // end HStack
        .background(.viewBackgroundColorOnboarding)
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)

        
    } // end view
} // end struc_


struct OnboardStartView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardStartView()
            .environmentObject(AppStatus())
    }
}
