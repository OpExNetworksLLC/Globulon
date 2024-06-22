//
//  OnboardTermsView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct OnboardTermsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    //@ObservedObject var appStatus = AppStatus()
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
        
    @State var isTerms: Bool = UserSettings.init().isTerms
    @State var isRead: Bool = false
    
    var body: some View {
        HStack {
            Spacer().frame(width: 16)
            VStack(alignment: .leading) {
                
                Group {
                    Spacer().frame(height: 50)
                    HStack {
                        Button(action: {
                            appStatus.currentOnboardPageView = .onboardStartView // go back a page
                        }
                        ) {
                            btnPreviousView()
                        }
                        Spacer()
                    } // end HStack
                    .padding(.bottom, 16)
                    
                    Text("Terms & Conditions")
                        .font(.system(size: 24))
                        .fontWeight(.regular)
                        .padding(.bottom, 16)
                    Text("Review the terms and conditions.  You must scroll to the end to accept")
                        .font(.system(size: 16))
                }

                Spacer().frame(height: 30)
                
                HStack {
                    HTMLStringView(htmlContent: termsData.content)
                        .opacity(0.8)
//                        .overlay(
//                            GeometryReader { proxy in
//                                Color.clear.onAppear { print(proxy.size.height)}
//                            })
                }
                
                Spacer().frame(height: 30)
                
                HStack {
                    /// Declined button
                    Button(action: {
                        /// Set these becaue in the onboard flow someone can go backwards and decline
                        isTerms = false
                        userSettings.isTerms = false
                        /// TODO:  bail here if the user declines.   confirm they want to bail?  An alert pop up maybe
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isReset"), object: nil)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Color("btnNextOnboarding"))
                                .cornerRadius(30)
                            Text("Decline")
                                .foregroundColor(Color("btnPrevOnboarding"))
                        }
                    }
                    .padding(0)

                    
                    Spacer()

                    Button(action: {
                        /// Save setting here since we do not have to a separate terms page breakout since this terms acceptance is specific to this flow
                        isTerms = true
                        userSettings.isTerms = true
                        appStatus.currentOnboardPageView = .onboardAccountView
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Text("Accept")
                                .foregroundColor(Color("btnNextOnboarding"))
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Color("btnNextOnboarding"))
                                .cornerRadius(30)
                        }
                    }
                } // end HStack
                Spacer().frame(height: 30)
            } // end VStack
            Spacer().frame(width: 16)
        } // end HStack
        .background(Color("viewBackgroundColorOnboarding"))
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {isTerms = userSettings.isTerms}
        
    } // end view
} // end struct


struct OnboardTermsView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardTermsView()
            .environmentObject(AppStatus())
            .environmentObject(UserSettings())
    }
}
