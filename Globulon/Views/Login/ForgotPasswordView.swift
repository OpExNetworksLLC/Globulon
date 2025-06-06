//
//  ForgotPasswordView.swift
//  Globulon
//
//  Created by David Holeman on 8/4/24.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2025.02.25)
 - Note: 
*/

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var userSettings: UserSettings
    
    @State var email: String = ""
    
    /// An entry to correspond to each field tag for sequenced entry.  Set the field to true if you want it to become first responder
    @State var fieldFocus = [false]
    
    /// email verification
    @State var isEmailVerified: Bool = false
    @State var isEmailVerifiedImage: String = "imgVerifyOff"
    
    /// alerts
    @State var showKeychainPasswordResetFailedAlert: Bool = false
    @State var showKeychainPasswordResetFailedMessage: String = ""
    
    @State var showFirebasePasswordResetSentAlert: Bool = false
    @State var showFirebasePasswordResetSentMessage: String = ""
    @State var showFirebasePasswordResetFailedAlert: Bool = false
    @State var showFirebasePasswordResetFailedMessage: String = ""
    
    
    var body: some View {
        
        VStack {
                     
            #if KEYCHAIN_ENABLED
            HStack {
                VStack(alignment: .leading) {
                    Text("This app uses local keychain authentication. If you have forgotten your password there is no way to recover it.  You will have to delete the app and it's data and start fresh.")
                    Spacer()
                }
                //.foregroundColor(.txtColorFixed)
                Spacer()
            }
            
            .padding(.leading, 16)
            #endif
            
            #if FIREBASE_ENABLED
                VStack(alignment: .leading) {
                    Text("We will send a password reset to the address below.")
                    
                    Spacer().frame(height: 32)
                    
                    VStack {
                        HStack {
                            Text("EMAIL ADDRESS")
                                .font(.caption)
                            Spacer()
                        }
                        
                        HStack {
                            TextField(
                                "Email address",
                                text: $email,
                                onEditingChanged: {(editingChanged) in
                                    if editingChanged {
                                        // check validity
                                        if isValidEmail(string: email) {
                                            isEmailVerified = true
                                        } else {
                                            isEmailVerified = false
                                        }
                                        
                                    } else {
                                        
                                    }
                                }
                            )
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .textCase(.lowercase)
                            .textContentType(.emailAddress)
                            .foregroundColor(.primary)
                            .onAppear {
                                /// Force lowercase
                                email = email.lowercased()
                                /// Check validity
                                if isValidEmail(string: email) {
                                    isEmailVerified = true
                                } else {
                                    isEmailVerified = false
                                }
                            }
                            .onChange(of: email) {
                                // check validity
                                if isValidEmail(string: email) {
                                    isEmailVerified = true
                                } else {
                                    isEmailVerified = false
                                }
                                
                            }
                            Image(isEmailVerifiedImage)
                                .imageScale(.large)
                                .frame(width: 32, height: 32, alignment: .center)
                                .onChange(of: email) {
                                    isEmailVerified = isValidEmail(string: email)
                                    if isEmailVerified {isEmailVerifiedImage = "imgVerifyOn" } else { isEmailVerifiedImage = "imgVerifyOff" }
                                }
                        }
                        .overlay(
                            Rectangle() // This creates the underline effect
                                .frame(height: 0.75)
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .padding(.top, 40),
                            alignment: .bottomLeading
                        )
                        .padding(.bottom, 16)
                        
                        Spacer().frame(height: 30)
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                
                                #if FIREBASE_ENABLED
                                /// Firebase password reset
                                Authentication.firebase.passwordReset(email: email) { success, error in
                                    if success {
                                        showFirebasePasswordResetSentMessage = "Reset sent, check your email.  If you don't see in your inbox check your \"Junk\" email folder"
                                        showFirebasePasswordResetSentAlert = true
                                    } else {
                                        showFirebasePasswordResetFailedMessage = error?.localizedDescription ?? ""
                                        showFirebasePasswordResetFailedAlert = true
                                    }
                                }
                                #endif
                                
                                #if KEYCHAIN_ENABLED
                                /// Keychain password reset
                                showKeychainPasswordResetFailedMessage = "Currently unable to reset passwords created using keychain authentication"
                                showKeychainPasswordResetFailedAlert = true
                                #endif
                            }
                            ) {
                                HStack {
                                    Text("submit")
                                        .foregroundColor(isEmailVerified ? .primary : .gray)
                                    Image(systemName: "arrow.right")
                                        .resizable()
                                        .foregroundColor(isEmailVerified ? .white : .white)
                                        .frame(width: 30, height: 30)
                                        .padding()
                                        .background(isEmailVerified ? Color("btnNext") : Color(UIColor.systemGray5))
                                        .cornerRadius(30)
                                }
                            }
                            .disabled(isEmailVerified ? false : true)
                            .alert("Reset Sent", isPresented: $showFirebasePasswordResetSentAlert) {
                                Button("Ok", role: .cancel) { self.presentationMode.wrappedValue.dismiss() }
                            } message: {
                                Text(showFirebasePasswordResetSentMessage)
                            }
                            .alert("Reset Problem", isPresented: $showFirebasePasswordResetFailedAlert) {
                                Button("Ok", role: .cancel) { }
                            } message: {
                                Text(showFirebasePasswordResetFailedMessage)
                            }
                            .alert("Reset Problem", isPresented: $showKeychainPasswordResetFailedAlert) {
                                Button("Ok", role: .cancel) { }
                            } message: {
                                Text(showKeychainPasswordResetFailedMessage)
                            }
                        }
                        /// end HStack
                    }
                    Spacer()
                }
                .offset(y: -32)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .foregroundColor(.primary)
                .onAppear {
                    /// Bring up local stored username
                    if let storedUsername = UserDefaults.standard.value(forKey: "email") as? String {
                        email = storedUsername
                    }
            }
            #endif
            
        }
        
        /// OPTION:  Uncomment if you want to use a color or gradient background
        /*
        .background(AppSettings.backgroundGradient.forgotPassword)
        .edgesIgnoringSafeArea(.bottom)
        */
                
    }
    
    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ForgotPasswordView()
}
