//
//  ForgotPasswordView.swift
//  ViDrive
//
//  Created by David Holeman on 2/21/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var appSettings:  AppSettings
    
    @State var email: String = UserSettings.init().email
    
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
        //NavigationView {
        HStack {
            Spacer().frame(width: 16)
            
            if AppSettings.login.isFirebaseLoginEnabled {
                
                /// Authentication is remote
                ///
                VStack(alignment: .leading) {
                    Spacer().frame(height: 60)
                    Text("We will send a password reset to the address below.")
                    //.foregroundColor(Color("colorTextFixed"))
                    Spacer().frame(height: 30)
                    Group {
                        Text("EMAIL ADDRESS")
                            .font(.caption)
                        //.foregroundColor(Color("colorTextFixed"))
                        HStack {
                            /// Email address
                            TextFieldEx (
                                label: "email address",
                                text: $email,
                                focusable: $fieldFocus,
                                returnKeyType: .done,
                                autocapitalizationType: Optional.none,
                                keyboardType: .emailAddress,
                                textContentType: UITextContentType.emailAddress,
                                //textColor: UIColor(Color("colorTextFixed")),
                                tag: 0
                            )
                            .frame(height: 40)
                            .padding(.vertical, 0)
                            .overlay(Rectangle().frame(height: 0.5).padding(.top, 30))
                            .onAppear {
                                /// Check validity
                                if isValidEmail(string: email) {
                                    isEmailVerified = true
                                } else {
                                    isEmailVerified = false
                                }
                            }
                            .onChange(of: email) {
                                email = email.lowercased()
                                /// Check validity
                                if isValidEmail(string: email) {
                                    isEmailVerified = true
                                } else {
                                    isEmailVerified = false
                                }
                            }.foregroundColor(Color("colorTextFixed"))
                            
                            
                            Image(isEmailVerifiedImage)
                                .imageScale(.large)
                                .frame(width: 32, height: 32, alignment: .center)
                                .onChange(of: email) {
                                    isEmailVerified = isValidEmail(string: email)
                                    if isEmailVerified {isEmailVerifiedImage = "imgVerifyOn" } else { isEmailVerifiedImage = "imgVerifyOff" }
                                }
                                .onChange(of: isEmailVerified) {
                                    if isEmailVerified {isEmailVerifiedImage = "imgVerifyOn"} else {isEmailVerifiedImage = "imgVerifyOff"}
                                }
                            
                        } // end HStack
                    } // end Group
                    
                    Spacer().frame(height: 30)
                    HStack {
                        Spacer()
                        Button(action: {
                            
                            /// Keychain password reset
                            if AppSettings.login.isKeychainLoginEnabled {
                                showKeychainPasswordResetFailedMessage = "Currently unable to reset passwords created using keychain authentication"
                                showKeychainPasswordResetFailedAlert = true
                            }
                            
                            /// Firebase password reset
                            if AppSettings.login.isFirebaseLoginEnabled {
                                Authentication.firebase.passwordReset(email: email) { success, error in
                                    if success {
                                        showFirebasePasswordResetSentMessage = "Reset sent, check your email.  If you don't see in your inbox check your \"Junk\" email folder"
                                        showFirebasePasswordResetSentAlert = true
                                    } else {
                                        showFirebasePasswordResetFailedMessage = error?.localizedDescription ?? ""
                                        showFirebasePasswordResetFailedAlert = true
                                    }
                                }
                            }
                            
                        }
                        ) {
                            HStack {
                                Text("submit")
                                    .foregroundColor(isEmailVerified ? .black : .gray)
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
                    } // end HStack
                    Spacer()
                } // end VStack
                
            }
            
            if AppSettings.login.isKeychainLoginEnabled {
                /// Authentication is local
                ///
                VStack(alignment: .leading) {
                   
                    Text("This app uses local keychain authentication and if you have forgotten it there is no way to recover it.  You will have to delete the app and it's data and start fresh.")
                        .padding(.bottom, 16)
                    
                    Spacer()

                }
                
            }
            
            Spacer().frame(width: 16)
        } // end HStack
        //.background(AppValues.backgroundGradient.forgotPassword)
        
        .edgesIgnoringSafeArea(.bottom)
        
    }
    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ForgotPasswordView()
}
