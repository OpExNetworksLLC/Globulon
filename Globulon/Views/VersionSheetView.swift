//
//  VersionSheetView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct VersionSheetView: View {
    @Binding var isVersionSheetDisplayed: Bool
    @StateObject var appStatus = AppStatus()
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Version Details:")
                        .padding(.bottom, 8)
                    Text("Version : \(AppInfo.version) (\(AppInfo.build))")
                        .font(.system(size: 14, design: .monospaced))
                    Text(AppSettings.login.isKeychainLoginEnabled ? "AuthMode: Local" : "AuthMode: Remote")
                        .font(.system(size: 14, design: .monospaced))
                    Text("UserMode: \(UserSettings.init().userMode.description)")
                        .font(.system(size: 14, design: .monospaced))
                    Text("Articles: \(articlesFrom())")
                        .font(.system(size: 14, design: .monospaced))
                    Text("firebaseInstallationID: \(UserSettings.init().firebaseInstallationID)")
                        .font(.system(size: 14, design: .monospaced))

                    Spacer()
                }
                .presentationDetents([.medium, .large])
                .padding(.top, 32)
                Spacer()
            }
            Spacer()
            Button(action: {
                UserSettings.init().userMode = .development
                isVersionSheetDisplayed = false
            }) {
                HStack {
                    Spacer()
                    Text("Enable Development")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    .padding(.vertical, 12)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color("btnPrev"))
            .edgesIgnoringSafeArea(.horizontal)
            .cornerRadius(5)
            .padding(.bottom)
            
            Button(action: {
                isVersionSheetDisplayed = false
            }) {
                HStack {
                    Spacer()
                    Text("Dismiss")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color("btnPrev"))
            .edgesIgnoringSafeArea(.horizontal)
            .cornerRadius(5)
            
        }
        .padding()
    }
}
#Preview {
    VersionSheetView(isVersionSheetDisplayed: .constant(true) )
}

