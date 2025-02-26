//
//  SettingsInfoView.swift
//  OpExShellV1
//
//  Created by David Holeman on 8/2/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct SettingsInfoView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        VStack {
            HStack() {
                Text("User Settings")
                    .font(.title)
                Spacer()
            }
        }
        .padding(.leading, 16)
        
        VStack {
            HStack() {
                Text("Version..........:")
                Text("\(AppInfo.version) (\(AppInfo.build))")
                Spacer()
            }
            .padding(.bottom, 8)
            
//            HStack() {
//                Text("authMode.........:")
//                Text(AppSettings.login.isKeychainLoginEnabled ? "local" : "remote")
//                Spacer()
//            }
        
            HStack() {
                Text("isBiometricID....:")
                Text(String(UserSettings.init().isBiometricID))
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("userMode.........:")
                Text("\(UserSettings.init().userMode.description)")
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("isTerms..........:")
                Text(String(UserSettings.init().isTerms))
                Spacer()
            }
            HStack() {
                Text("isOnboarded......:")
                Text(String(UserSettings.init().isOnboarded))
                Spacer()
            }
            HStack() {
                Text("isWelcomed.......:")
                Text(String(UserSettings.init().isWelcomed))
                Spacer()
            }
            HStack() {
                Text("isPrivacy........:")
                Text(String(UserSettings.init().isPrivacy))
                Spacer()
            }
            HStack() {
                Text("isLicensed.......:")
                Text(String(UserSettings.init().isLicensed))
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("landingPage......:")
                Text(UserSettings.init().landingPage.description)
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("articlesLocation.:")
                Text(UserSettings.init().articlesLocation.description)
                Spacer()
            }
            HStack() {
                Text("articlesDate.....:")
                Text(formatDate(date: UserSettings.init().articlesDate))
                Spacer()
            }

            .padding(.bottom, 8)

            Spacer()
            
            Button(action: {

                self.presentationMode.wrappedValue.dismiss()
            }
            ) {
                HStack {
                    Image(systemName: "arrow.left")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .padding()
                        .background(Color("btnPrev"))
                        .cornerRadius(30)
                    Text("Exit").foregroundColor(.blue)
                    Spacer()
                }
            }
            .padding(0)
            Spacer().frame(height: 30)

        }
        .font(.system(size: 14, design: .monospaced))
        .foregroundColor(.primary)
        .padding(.top, 8)
        .padding(.leading, 16)

    }
}

#Preview {
    SettingsInfoView()
        .environmentObject(UserSettings())
}
