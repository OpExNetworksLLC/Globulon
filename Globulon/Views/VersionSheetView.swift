//
//  VersionSheetView.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct VersionSheetView: View {
    @Binding var isShowVersionSheet: Bool
    
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var userStatus: UserStatus
    
    @State private var tapCount = 0
    @State private var isThresholdReached = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Version Details:")
                        .padding(.bottom, 8)
                    Text("Version : \(VersionManager.releaseDesc))")
                        .font(.system(size: 14, design: .monospaced))
                    #if FIREBASE_ENABLED
                        Text("AuthMode: remote (firebase)")
                        .font(.system(size: 14, design: .monospaced))
                    #elseif KEYCHAIN_ENABLED
                        Text("AuthMode: local (keychain)")
                        .font(.system(size: 14, design: .monospaced))
                    #endif
                    Text("UserMode: \(userSettings.userMode.description)")
                        .font(.system(size: 14, design: .monospaced))
                    Text("Articles: \(articlesLocation())")
                        .font(.system(size: 14, design: .monospaced))
                    Text("Schema  : \(CurrentModelSchema.versionIdentifier)")
                        .font(.system(size: 14, design: .monospaced))
                        .padding(.bottom, 8)
                    
                    Text("LoggedIn: \(userStatus.isLoggedIn)")
                        .font(.system(size: 14, design: .monospaced))
                    Text("lastAuth: \(formatDateShortUS(userSettings.lastAuth))")
                        .font(.system(size: 14, design: .monospaced))
                        .padding(.bottom, 8)
                    
                    #if FIREBASE_ENABLED
                    /// This setting was dione directly for testing purposes so not part of userSettings.
                    Text("firebaseInstallationID: \(userSettings.firebaseInstallationID)")
                        .font(.system(size: 14, design: .monospaced))
                    #endif

                    Spacer()
                }
                .presentationDetents([.medium, .large])
                .padding(.top, 32)
                .onTapGesture {
                    if timer == nil {
                        // Start the timer when the first tap is detected
                        startTimer()
                    }

                    tapCount += 1

                    if tapCount == 5 {
                        isThresholdReached = true
                        resetTapTracking()
                    }
                }
                .alert("Change UserMode", isPresented: $isThresholdReached) {
                    Button("Production", role: .cancel) {
                        userSettings.userMode = .production
                    }
                    Button("Development", role: .none) {
                        userSettings.userMode = .development
                    }
                    Button("Test", role: .none) {
                        userSettings.userMode = .test
                    }
                } message: {
                    Text("Please choose an option to proceed.")
                }
                Spacer()
            }
            
            Spacer()
            
            Button(action: {
                isShowVersionSheet = false
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
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [self] _ in
            Task { @MainActor in
                resetTapTracking()
            }
        }
    }

    private func resetTapTracking() {
        Task {
            tapCount = 0
            timer?.invalidate()
            timer = nil
        }
    }
    
}
#Preview {
    VersionSheetView(isShowVersionSheet: .constant(true) )
}

