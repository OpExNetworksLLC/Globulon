//
//  UserSecurityView.swift
//  OpExShellV1
//
//  Created by David Holeman on 8/2/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct UserSecurityView: View {
    
    let myDevice = Biometrics()
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
    
    @State var isAutoLogin: Bool = UserSettings.init().isAutoLogin
    @State var isAutoBiometricLogin: Bool = UserSettings.init().isAutoBiometricLogin

    @State var isBiometricID: Bool = UserSettings.init().isBiometricID
    
    @State var passwordEntry: String = ""
    @State var passwordVerify: String = ""
    @State var passwordLast: String = ""
    
    @State var isPasswordVisible: Bool = false
    
    @State var isPasswordStrengthValue: Int = 0
    @State var isPasswordStrengthLabel: String = "(enter)"
    @State var isPasswordStrengthImage: String = "imgStrengthOff"
    
    @State var isPasswordVerified: Bool = false
    @State var isPasswordVerifiedImage: String = "imgVerifyOff"
    
    @State var isChanged: Bool = false
    
    @State var showKeychainPasswordChangeFailedAlert: Bool = false
    @State var showKeychainPasswordChangeFailedMessage: String = ""
    
    @State var showFirebasePasswordResetSentAlert: Bool = false
    @State var showFirebasePasswordResetSentMessage: String = ""
    @State var showFirebasePasswordResetFailedAlert: Bool = false
    @State var showFirebasePasswordResetFailedMessage: String = ""
    
    /// An entry to correspond to each field tag for sequenced entry.  Set the field to true if you want it to become first responder
    @State var fieldFocus = [false, false]
    @State var isHidePassword = true
    
    @FocusState private var focusedField: InputPasswordField?
    enum InputPasswordField: Hashable {
        case passwordEntry
        case passwordVerify
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    VStack(alignment: .leading) {
                        Text("Security Settings!")
                            .font(.system(size: 24, weight: .bold))
                            .padding([.leading, .trailing], 16)
                            .padding(.bottom, 1)
                        Text("Secure access to your app...")
                            .font(.system(size: 14))
                            .padding([.leading, .trailing], 16)
                        Spacer()
                    }
                    .frame(width: UIScreen.main.bounds.width - 36, height: 120, alignment: .leading)
                    
                    Section(header: Text("Login Settings")) {

                        Toggle(isOn: self.$isBiometricID) {
                            Text("Biometric ID")
                                .foregroundColor(.primary)
                        }
                        .onChange(of: isBiometricID) {
                            userSettings.isBiometricID = isBiometricID
                            
                            /// by relationship of isBiometricID false then isAutoBiometricLogin is false
                            ///
                            if isBiometricID == false {
                                userSettings.isAutoBiometricLogin = false
                            }
                            isChanged = true
                        }
                        .onAppear {
                            isBiometricID = userSettings.isBiometricID
                        }
                        .disabled(myDevice.canEvaluatePolicy() == false)
                        .padding(.trailing, 8)
                        
                        // TODO: AutoLogin
                        // ...
                        
                        if isBiometricID {
                            Toggle(isOn: self.$isAutoBiometricLogin) {
                                Text("Auto biometric login")
                            }
                            .onChange(of: isAutoBiometricLogin) {
                                userSettings.isAutoBiometricLogin = isAutoBiometricLogin
                                isChanged = true
                            }
                            .onAppear {
                                isAutoBiometricLogin = userSettings.isAutoBiometricLogin
                            }
                            .padding(.trailing, 8)
                        }
                        
                        
                    }
                    .offset(x: -8)
                    .padding(.trailing, -16)
                    // end section
                    
                    Section(header: Text("Reset Password")) {
                        #if KEYCHAIN_ENABLED
                        //if AppSettings.login.isKeychainLoginEnabled {
                            Group {
                                HStack {
                                    Text("PASSWORD \(isPasswordStrengthLabel)")
                                        .onChange(of: passwordEntry) {
                                            // check strength
                                            let strength = passwordStrengthCheck(string: passwordEntry)
                                            isPasswordStrengthLabel = strength.label
                                        }
                                        .font(.caption)
                                    Spacer()
                                    Button(action: {
                                        isHidePassword.toggle()
                                    }) {
                                        Text(isHidePassword ? "Show" : "Hide")
                                            .font(.caption)
                                    }
                                    
                                }

                                HStack {
                                    if isHidePassword {
                                        SecureField("password", text: $passwordEntry)
                                        .disableAutocorrection(true)
                                        .autocapitalization(.none)
                                        .focused($focusedField, equals: .passwordEntry)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .passwordVerify
                                        }
                                        .onTapGesture {
                                            focusedField = .passwordEntry
                                        }
                                        .onChange(of: passwordEntry) {
                                            // check strength
                                            let strength = passwordStrengthCheck(string: passwordEntry)
                                            isPasswordStrengthImage = strength.image
                                            if strength.value == 0 {isPasswordVerified = false}
                                            
                                        }
                                        .frame(height: 40)
                                        .overlay(
                                            Rectangle() // This creates the underline effect
                                                .frame(height: 0.75)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .padding(.top, 30)
                                        )
                                    } else {
                                        TextField("password", text: $passwordEntry)
                                        .disableAutocorrection(true)
                                        .autocapitalization(.none)
                                        .focused($focusedField, equals: .passwordEntry)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .passwordVerify
                                        }
                                        .onTapGesture {
                                            focusedField = .passwordEntry
                                        }
                                        .onChange(of: passwordEntry) {
                                            // check strength
                                            let strength = passwordStrengthCheck(string: passwordEntry)
                                            isPasswordStrengthImage = strength.image
                                            if strength.value == 0 {isPasswordVerified = false}
                                            
                                        }
                                        .frame(height: 40)
                                        .overlay(
                                            Rectangle() // This creates the underline effect
                                                .frame(height: 0.75)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .padding(.top, 30)
                                        )
                                    }

                                    Image(isPasswordStrengthImage)
                                        .imageScale(.large)
                                        .frame(width: 32, height: 32, alignment: .center)
                                }
                                
                                HStack {
                                    if isHidePassword {
                                        SecureField("password verify", text: $passwordVerify)
                                        .disableAutocorrection(true)
                                        .autocapitalization(.none)
                                        .focused($focusedField, equals: .passwordVerify)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = nil
                                        }
                                        .onTapGesture {
                                            focusedField = .passwordVerify
                                        }
                                        .onChange(of: passwordVerify) {
                                            // check validity
                                            if passwordVerify == passwordEntry && passwordStrengthCheck(string: passwordEntry).value > 0 {
                                                isPasswordVerified = true
                                                isPasswordVerifiedImage = "imgVerifyOn"
                                            } else {
                                                isPasswordVerified = false
                                                isPasswordVerifiedImage = "imgVerifyOff"
                                            }
                                        }
                                        .frame(height: 40)
                                        .overlay(
                                            Rectangle() // This creates the underline effect
                                                .frame(height: 0.75)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .padding(.top, 30)
                                        )

                                    } else {
                                        TextField("password verify", text: $passwordVerify)
                                        .disableAutocorrection(true)
                                        .autocapitalization(.none)
                                        .focused($focusedField, equals: .passwordVerify)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = nil
                                        }
                                        .onTapGesture {
                                            focusedField = .passwordVerify
                                        }
                                        .onChange(of: passwordVerify) {
                                            // check validity
                                            if passwordVerify == passwordEntry && passwordStrengthCheck(string: passwordEntry).value > 0 {
                                                isPasswordVerified = true
                                                isPasswordVerifiedImage = "imgVerifyOn"
                                            } else {
                                                isPasswordVerified = false
                                                isPasswordVerifiedImage = "imgVerifyOff"
                                            }
                                        }
                                        .frame(height: 40)
                                        .overlay(
                                            Rectangle() // This creates the underline effect
                                                .frame(height: 0.75)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .padding(.top, 30)
                                        )

                                    }
                                    
                                    Image(isPasswordStrengthImage)
                                        .imageScale(.large)
                                        .frame(width: 32, height: 32, alignment: .center)
                                }
                                
                                
                            } // end group
                        //}
                        #endif
                        
                        #if FIREBASE_ENABLED
                        //if AppSettings.login.isFirebaseLoginEnabled {
                            Group {
                                Button(action: {
                                    /// Send the reset
                                    let userEmail = userSettings.email
                                    Authentication.firebase.passwordReset(email: userEmail) { success, error in
                                        if success {
                                            showFirebasePasswordResetSentMessage = "Reset sent, check your email.  If you don't see in your inbox check your \"Junk\" email folder"
                                            showFirebasePasswordResetSentAlert = true
                                        } else {
                                            showFirebasePasswordResetFailedMessage = error?.localizedDescription ?? ""
                                            showFirebasePasswordResetFailedAlert = true
                                        }
                                    }
                                    
                                    //
                                }) {
                                    Text("Send password reset")
                                }
                                .alert("Reset Sent", isPresented: $showFirebasePasswordResetSentAlert) {
                                    Button("Ok", role: .cancel) { self.dismiss() }
                                } message: {
                                    Text(showFirebasePasswordResetSentMessage)
                                }
                                .alert("Reset Problem", isPresented: $showFirebasePasswordResetFailedAlert) {
                                    Button("Ok", role: .cancel) { }
                                } message: {
                                    Text(showFirebasePasswordResetFailedMessage)
                                }

                            }
                        //}
                        #endif
                        
                    }
                    .offset(x: -8)
                    .padding(.trailing, -16)
                    // end Section
                    
                    
                }
                .padding(.top, -16)
                .clipped()
                // end Form
            }
            // end VStack
        }
        .foregroundColor(.primary)
        .background(Color(UIColor.systemGroupedBackground))
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Security")
        .toolbar(content: {
            
            /// Save/Done button
            ///
            Button(action: {
                if isPasswordVerified {
                    
                    /// Save new password
                    ///
                    let userEmail = userSettings.email
                    var userPassword = passwordLast
                    let passwordNew = passwordVerify
                    
                    #if KEYCHAIN_ENABLED
                    //if AppSettings.login.isKeychainLoginEnabled {
                        Authentication.keychain.updatePassword(username: userEmail, passwordOld: userPassword, passwordNew: passwordNew) { success, error in
                            if success {
                                userPassword = passwordNew
                                dismiss()
                            } else {
                                showKeychainPasswordChangeFailedMessage = error?.localizedDescription ?? ""
                                showKeychainPasswordChangeFailedAlert = true
                            }
                        }
                    //}
                    #endif
                    
//                    if AppSettings.login.isFirebaseLoginEnabled {
//                        Authentication.firebase.passwordReset(email: userEmail) { success, error in
//                            if success {
//                                showFirebasePasswordResetSentMessage = "Reset sent, check your email.  If you don't see in your inbox check your \"Junk\" email folder"
//                                showFirebasePasswordResetSentAlert = true
//                            } else {
//                                showFirebasePasswordResetFailedMessage = error?.localizedDescription ?? ""
//                                showFirebasePasswordResetFailedAlert = true
//                            }
//                        }
//                    }
                    
                }
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text(isChanged ? "Save": "Done")
                    .foregroundColor(.blue)
            }
            .alert("Change Problem", isPresented: $showKeychainPasswordChangeFailedAlert) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text(showKeychainPasswordChangeFailedMessage)
            }
//            .alert("Reset Sent", isPresented: $showFirebasePasswordResetSentAlert) {
//                Button("Ok", role: .cancel) { self.dismiss() }
//            } message: {
//                Text(showFirebasePasswordResetSentMessage)
//            }
//            .alert("Reset Problem", isPresented: $showFirebasePasswordResetFailedAlert) {
//                Button("Ok", role: .cancel) { }
//            } message: {
//                Text(showFirebasePasswordResetFailedMessage)
//            }
        })
        .onAppear {
            /// Load up when the view appears so that if you make a change and come back while still in the setting menu the values are current.
            
            // TODO: AutoLogin
            // ...
            
            /*
            isAutoBiometricLogin = userSettings.isAutoBiometricLogin
            */
            isBiometricID = userSettings.isBiometricID
            isChanged = false
            
            let userEmail = userSettings.email
            
            #if KEYCHAIN_ENABLED
            //if AppSettings.login.isKeychainLoginEnabled {
                Authentication.keychain.retrievePassword(username: userEmail) { success, password, error in
                    if success {
                        passwordEntry = password
                        passwordVerify = password
                        passwordLast = password
                    } else {
                        showKeychainPasswordChangeFailedMessage = error?.localizedDescription ?? ""
                        showKeychainPasswordChangeFailedAlert = true
                    }
                }
            //}
            #endif
            
            //            if AppSettings.login.isFirebaseLoginEnabled {
            //                /// Firebase only permits a reset for security reasons if you want to change your password.
            //                Authentication.firebase.passwordReset(email: userEmail) { success, error in
            //                    if success {
            //                        showFirebasePasswordResetSentMessage = "Reset sent, check your email.  If you don't see in your inbox check your \"Junk\" email folder"
            //                        showFirebasePasswordResetSentAlert = true
            //                    } else {
            //                        showFirebasePasswordResetFailedMessage = error?.localizedDescription ?? ""
            //                        showFirebasePasswordResetFailedAlert = true
            //                    }
            //                }
            //            }
            
        }
        // end NavigationView
    }
    // end View
}
        
struct UserSecurityView_Previews: PreviewProvider {
    static var previews: some View {
        UserSecurityView()
            .environmentObject(AppStatus())
            .environmentObject(UserSettings())
    }
}
