//
//  OnboardCompleteView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct OnboardCompleteView: View {
    
    //let myDevice = BiometricAuthType()
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        HStack {
            Spacer().frame(width: 16)
            
            VStack(alignment: .leading) {
                Group {
                    Spacer().frame(height: 50)
                    HStack {
                        Button(action: {
                            appStatus.currentOnboardPageView = .onboardPasswordView
                        }
                        ) {
                            HStack {
                                btnPreviousView()
                            }
                        }
                        Spacer()
                    } // end HStack
                    .padding(.bottom, 16)
                    Text("Onboard Complete")
                        .font(.system(size: 24))
                        .fontWeight(.regular)
                        .padding(.bottom, 16)
                    Text("Congratulations.  You have completed the steps necessary to access the app.")
                } // end group
                
                Spacer().frame(height: 30)
                
                Group {
                    Text("Next we will take you through some welcome screens then you can begin enjoying the app.")

                } // end group
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        /// The onboarding process is complete.  Since we have already created login info we do not need to go through the login.
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isOnboarded"), object: nil)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("next")
                            .foregroundColor(Color("btnNextOnboarding"))
                        Image(systemName: "arrow.right")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .padding()
                            .background(Color("btnNextOnboarding"))
                            .cornerRadius(30)
                    }
                } // end HStack
                
                Spacer().frame(height: 30)
            } // end VStack
            Spacer().frame(width: 16)
        } // end HStack
        .background(Color("viewBackgroundColorOnboarding"))
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            /// Set the biometricID flag to true as part of the onboarding process.  This is needs to occur before the login view so we know wheter to present the biometric options on the login screen later.
            //if myDevice.isBiometric() == true { userSettings.isBiometricID = true }
        }
        
    } // end view
} // end struc_


struct OnboardCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardCompleteView()
            .environmentObject(AppStatus())
            .environmentObject(UserSettings())
    }
}

