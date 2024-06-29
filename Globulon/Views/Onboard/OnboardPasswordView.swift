//
//  OnboardPasswordView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import LocalAuthentication
import Security

struct OnboardPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    
    //@ObservedObject var appStatus = AppStatus()
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
    
    @State var passwordEntry: String = ""
    @State var passwordVerify: String = ""
    
    @State var isPasswordVisible: Bool = false
    
    @State var isPasswordStrengthValue: Int = 0
    @State var isPasswordStrengthLabel: String = "(enter)"
    @State var isPasswordStrengthImage: String = "imgStrengthOff"
    
    @State var isPasswordVerified: Bool = false
    @State var isPasswordVerifiedImage: String = "imgVerifyOff"
    
    /// An entry to correspond to each field tag for sequenced entry.  Set the field to true if you want it to become first responder
    @State var fieldFocus = [true, false]
    @State var isHidePassword = true
    
    @State var showKeychainAddUserFailedAlert: Bool = false
    @State var showKeychainAddUserFailedMessage: String = ""
    @State var showFirebaseAddUserFailedAlert: Bool = false
    @State var showFirebaseAddUserFailedMessage: String = ""
    
    @State var showFirebaseAlreadyInUseAlert: Bool = false
    @State var showFirebaseAlreadyInUsedMessage: String = ""
    
    var email: String = UserSettings.init().email
    
    var body: some View {
        HStack {
            Spacer().frame(width: 16)
            
            VStack(alignment: .leading) {
                Group {
                    Spacer().frame(height: 50)
                    HStack {
                        Button(action: {
                            appStatus.currentOnboardPageView = .onboardEmailView  // go back a page
                        }
                        ) {
                            HStack {
                                btnPreviousView()
                            }
                        }
                        Spacer()
                    } // end HStack
                    .padding(.bottom, 16)
                    
                    Text("Password")
                        .font(.system(size: 24))
                        .fontWeight(.regular)
                        .padding(.bottom, 16)
                    Text("Please enter a password. You can change the password any time in settings.")
                        .font(.system(size: 16))

                }
                
                Spacer().frame(height: 30)

                Group {
                    VStack(alignment: .leading, content: {
                        Text("ACCOUNT")
                            .font(.caption)
                        Text(email)
                            .font(.system(size: 16))

                    })
                }
                
                Spacer().frame(height: 32)

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
                        //SecureField("Enter password", text: $passwordEntry)
                        TextFieldEx (
                            label: "password",
                            text: $passwordEntry,
                            focusable: $fieldFocus,
                            isSecureTextEntry: $isHidePassword,
                            returnKeyType: .next,
                            autocorrectionType: .no,
                            tag: 0
                        )
                        .frame(height: 40)
                        .padding(.vertical, 0)
                        .overlay(Rectangle().frame(height: 0.5).padding(.top, 30))
                        .onChange(of: passwordEntry) {
                            // check strength
                            let strength = passwordStrengthCheck(string: passwordEntry)
                            isPasswordStrengthImage = strength.image
                            if strength.value == 0 {isPasswordVerified = false}
                            
                        }
                        Image(isPasswordStrengthImage)
                            .imageScale(.large)
                            .frame(width: 32, height: 32, alignment: .center)
                    }
                    
                    Spacer().frame(height: 32)
                    
                    HStack {
                        //SecureField("Verify Password", text: $passwordVerify)
                        TextFieldEx (
                            label: "verify password",
                            text: $passwordVerify,
                            focusable: $fieldFocus,
                            isSecureTextEntry: $isHidePassword,
                            returnKeyType: .done,
                            autocorrectionType: .no,
                            tag: 1
                        )
                        .frame(height: 40)
                        .padding(.vertical, 0)
                        .overlay(Rectangle().frame(height: 0.5).padding(.top, 30))
                        //.foregroundColor(inputColor)
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
//                        .onSubmit {
//                            // Dismiss the keyboard when the "Done" button is pressed
//                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                        }
                        
                        Image(isPasswordVerifiedImage)
                            .imageScale(.large)
                            .frame(width: 32, height: 32, alignment: .center)
                    }
                } // end group
                
                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        // save values
                        // 1. email
                        /*
                        UserDefaults.standard.setValue(userSettings.email, forKey: "username")
                        UserDefaults.standard.set(true, forKey: "hasLoginKey")
                        */

                        // 2. password
                        /*
                        do {

                            // This is a new account, create a new keychain item with the account name.
                            let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName,
                                                                    account: userSettings.email,
                                                                    accessGroup: KeychainConfiguration.accessGroup)

                            // Save the password for the new item.
                            try passwordItem.savePassword(passwordVerify)
                            print("new password saved: '\(passwordVerify)'")

                        } catch {
                            fatalError("Error updating keychain - \(error)")
                        }
                        */
                        
//                        if AppSettings.login.isKeychainLoginEnabled {
//                            _ = Authentication.keychain.addUser(username: email, password: passwordVerify)
//                        }
                        
                        if AppSettings.login.isKeychainLoginEnabled {
                            
                            //TODO:  Delete keychain user
                            Authentication.keychain.deleteUser(username: email) { success, error in
                                if success {
                                    LogEvent.print(module: "Authentication.keychain.deleteUser", message: "\(email) deleted successfully.")
                                    /// Add the new user
//                                    Authentication.keychain.addUser(username: newUsername, password: password) { success, userID, error in
//                                        if success {
//                                            /// do stuff
//                                            LogEvent.print(module: "Authentication.keychain.changeUser", message: "\(oldUsername) added successfully.")
//                                            completion(true, error)
//                                        } else {
//                                            LogEvent.print(module: "Authentication.keychain.changeUser", message: "Error adding account \(error!)")
//                                            completion(false, error)
//                                        }
//                                    }
                                    
                                } else {
                                    LogEvent.print(module: "Authentication.keychain.changeUser", message: "Error deleting old account \(error!)")
//                                    completion(false, error)
                                }
                            }
                            
                            
                            
                            Authentication.keychain.addUser(username: email, password: passwordVerify) { success, userID, error in
                                if success {
                                    /// do stuff
                                    LogEvent.print(module: "LoginView.Authentication.keychain.addUser", message: "\(email) added toKeychain")
                                    /// On to the next view
                                    appStatus.currentOnboardPageView = .onboardCompleteView

                                } else {
                                    /// Handle failure to add user
                                    showKeychainAddUserFailedMessage = error?.localizedDescription ?? ""
                                    showKeychainAddUserFailedAlert = true

                                }
                            }
                        }
                        
                        if AppSettings.login.isFirebaseLoginEnabled {
                            Authentication.firebase.addUser(email: email, password: passwordVerify) {
                                success, userID, error in
                                if success {
                                    /// Do stuff
                                    LogEvent.print(module: "LoginView.Authentication.firebase.addUser", message: "\(email) added toKeychain")
                                    /// On to the next view
                                    appStatus.currentOnboardPageView = .onboardCompleteView

                                } else {
                                    
                                    print("** email address already in use: \(String(describing: error))")

                                    // check for this error first
                                    if String(describing: error).contains("ERROR_EMAIL_ALREADY_IN_USE") {

                                        showFirebaseAlreadyInUsedMessage = "This login is already in use."
                                        showFirebaseAlreadyInUseAlert = true
                                        
                                    } else {
                                        /// Handle failure to add user
                                        showFirebaseAddUserFailedMessage = error?.localizedDescription ?? ""
                                        showFirebaseAddUserFailedAlert = true
                                    }
                                }
                            }

                        }
                        
                    }) {
                        Text("Next")
                            .font(.system(size: 17))
                            .foregroundColor(isPasswordVerified ? Color("btnNextOnboarding") : .gray)
                        Image(systemName: "arrow.right")
                            .resizable()
                            .foregroundColor(isPasswordVerified ? .white : .white)
                            .frame(width: 30, height: 30)
                            .padding()
                            .background(isPasswordVerified ? Color("btnNextOnboarding") : Color(UIColor.systemGray5))
                            .cornerRadius(30)
                    }
                    .disabled(isPasswordVerified ? false : true)
                    .alert("Account Firebase Problem", isPresented: $showFirebaseAddUserFailedAlert) {
                        Button("Ok", role: .cancel) { }
                    } message: {
                        Text(showFirebaseAddUserFailedMessage)
                    }
                    .alert(isPresented: $showFirebaseAlreadyInUseAlert) {
                        Alert(
                            title: Text("Account already in use"),
                            message: Text("If this is your account do you want to try to log in.  If not choose a different email address to use."),
                            primaryButton: .destructive(Text("Login")) {
                                DispatchQueue.main.asyncAfter(deadline: .now()) {
                                    NotificationCenter.default.post(name: Notification.Name("isOnboarded"), object: nil)
                                }
                                self.presentationMode.wrappedValue.dismiss()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    .alert("Account Keychain Problem", isPresented: $showKeychainAddUserFailedAlert) {
                        Button("Ok", role: .cancel) { }
                    } message: {
                        Text(showKeychainAddUserFailedMessage)
                    }

                }  // end HStack
                
                Spacer().frame(height: 30)
            } // end VStack
            Spacer().frame(width: 16)
        } // end HStack
        .background(Color("viewBackgroundColorOnboarding"))
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
        .onTapGesture { self.hideKeyboard() }
    } // end view
} // end struc


struct OnboardPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardPasswordView()
            .environmentObject(AppStatus())
            .environmentObject(UserSettings())
    }
}

