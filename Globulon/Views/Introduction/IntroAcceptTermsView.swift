//
//  IntroAcceptTermsView.swift
//  Globulon
//
//  Created by David Holeman on 02/26/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct IntroAcceptTermsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var userSettings: UserSettings
    
    var title: String
    var subtitle: String
    var webURL: String
    @Binding var isAccepted: Bool

    @State var isTerms: Bool = UserSettings.init().isTerms
    @State var isRead: Bool = false
    
    //@Binding var isReviewed: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                
                Spacer().frame(height: 16)
                
                Text("\(title)")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .padding(.bottom, 2)
                Text("\(subtitle)")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .padding(.bottom, 24)
                
                //----
                //SwiftUIWebView(url: URL(string: webURL))
                SwiftUIWebView(localHTMLFileName: nil, url: URL(string: webURL))
                    .padding(8)
                    //.border(colorScheme == .dark ? .white : .black)
                    .border(.gray)
                //----
                
                //Spacer()
                Spacer().frame(height: 30)
                
                /// Decline/Accept
                ///
                HStack {
                    /// Declined button
                    Button(action: {
                        /// Set these becaue in the onboard flow someone can go backwards and decline
                        isTerms = false
                        userSettings.isTerms = false
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
                                .background(Color("btnNextIntroduction"))
                                .cornerRadius(30)
                            Text("Decline").foregroundColor(Color("btnPrevIntroduction"))
                        }
                    }
                    .padding(0)
                    
                    
                    Spacer()
                    
                    
                    Button(action: {
                        /// Save setting here since we do not have to a separate terms page breakout since this terms acceptance is specific to this flow
                        isTerms = true
                        userSettings.isTerms = true
                        
                        /// Go on to the next page in the intro if you want to show the intro is complete view or exit in the following code through notification.  If we go to the last intro page then skip the notification code so it goes vs. exits.
                        ///
                        /// appStatus.currentIntroPageView = .introCompleteView
                        
                        /// The intro process is complete.  Since we have already created login info we do not need to go through the login.
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isIntroduced"), object: nil)
                        }
                        
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Text("Accept")
                                .foregroundColor(Color("btnNextIntroduction"))
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Color("btnNextIntroduction"))
                                .cornerRadius(30)
                        }
                    }
                }
                // end HStack
                Spacer().frame(height: 32)
            }
            .padding(.leading, 16)
            // end VStack
            Spacer().frame(width: 16)
        }
        .edgesIgnoringSafeArea(.bottom)

    }
    // end view
}
// end struct

#Preview {
    IntroAcceptTermsView(title: "Terms & Conditions ELUA", subtitle: "User assumes all risk and responsibilty", webURL: AppSettings.licenseURL, isAccepted: .constant(true))
}
