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
                Text(String(userSettings.isBiometricID))
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("userMode.........:")
                Text("\(userSettings.userMode.description)")
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("isTerms..........:")
                Text(String(userSettings.isTerms))
                Spacer()
            }
            HStack() {
                Text("isIntroduced.....:")
                Text(String(userSettings.isIntroduced))
                Spacer()
            }
            HStack() {
                Text("isGDPRConsent....:")
                Text(String(userSettings.isGDPRConsentGranted))
                Spacer()
            }
            HStack() {
                Text("isPermissions....:")
                Text(String(userSettings.isPermissions))
                Spacer()
            }
            HStack() {
                Text("isOnboarded......:")
                Text(String(userSettings.isOnboarded))
                Spacer()
            }
            HStack() {
                Text("isWelcomed.......:")
                Text(String(userSettings.isWelcomed))
                Spacer()
            }
            .padding(.bottom, 8)
            
            HStack() {
                Text("isPrivacy........:")
                Text(String(UserSettings.init().isPrivacy))
                Spacer()
            }
            
            /*
            HStack() {
                Text("isLicensed.......:")
                Text(String(UserSettings.init().isLicensed))
                Spacer()
            }
            .padding(.bottom, 8)
            */
            
            HStack() {
                Text("landingPage......:")
                Text(userSettings.landingPage.description)
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("articlesLocation.:")
                Text(userSettings.articlesLocation.description)
                Spacer()
            }
            HStack() {
                Text("articlesDate.....:")
                Text(formatDate(date: userSettings.articlesDate))
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("database schema..:")
                Text(SchemaVersionStore.getDesc())
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
