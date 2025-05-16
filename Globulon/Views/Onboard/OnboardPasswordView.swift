//
//  OnboardPasswordView.swift
//  Globulon
//
//  Created by David Holeman on 02/25/26.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import LocalAuthentication
import Security

struct OnboardPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    
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
    
    @State var isHidePassword = true
    
    @State var showKeychainAddUserFailedAlert: Bool = false
    @State var showKeychainAddUserFailedMessage: String = ""
    @State var showFirebaseAddUserFailedAlert: Bool = false
    @State var showFirebaseAddUserFailedMessage: String = ""
    
    @State var showFirebaseAlreadyInUseAlert: Bool = false
    @State var showFirebaseAlreadyInUsedMessage: String = ""
    
    var email: String = UserSettings.init().email
    
    @FocusState private var focusedField: InputOnboardPasswordField?
    enum InputOnboardPasswordField: Hashable {
        case passwordEntry
        case passwordVerify
    }
    
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
                        if isHidePassword {
                            SecureField("password", text: $passwordEntry)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .passwordEntry)
                            .submitLabel(.next)
//                            .onSubmit {
//                                focusedField = .passwordVerify
//                            }
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
//                            .onSubmit {
//                                focusedField = .passwordVerify
//                            }
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
                    
                    Spacer().frame(height: 32)
                    
                    HStack {
                        if isHidePassword {
                            SecureField("password verify", text: $passwordVerify)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .passwordVerify)
                            .submitLabel(.next)
//                            .onSubmit {
//                                focusedField = nil
//                            }
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
                            .submitLabel(.done)
//                            .onSubmit {
//                                focusedField = nil
//                            }
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
                                        
                }
                .onAppear {
                    focusedField = .passwordEntry
                }
                // end group
                
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
                        
                        #if KEYCHAIN_ENABLED
                            
                            // Delete user for clean up
                            Authentication.keychain.deleteUser(username: email) { success, error in
                                if success {
                                    LogManager.event(module: "Authentication.keychain.deleteUser", message: "\(email) deleted successfully.")
                                    
                                } else {
                                    LogManager.event(module: "Authentication.keychain.changeUser", message: "Error deleting old account \(error!)")
                                }
                            }
                            
                            // Add user to keychain
                            Authentication.keychain.addUser(username: email, password: passwordVerify) { success, userID, error in
                                if success {
                                    /// do stuff
                                    LogManager.event(module: "LoginView.Authentication.keychain.addUser", message: "\(email) added toKeychain")
                                    /// On to the next view
                                    appStatus.currentOnboardPageView = .onboardCompleteView

                                } else {
                                    /// Handle failure to add user
                                    showKeychainAddUserFailedMessage = error?.localizedDescription ?? ""
                                    showKeychainAddUserFailedAlert = true

                                }
                            }
                        //}
                        #endif
                        
                        #if FIREBASE_ENABLED
                        //if AppSettings.login.isFirebaseLoginEnabled {
                            Authentication.firebase.addUser(email: email, password: passwordVerify) {
                                success, userID, error in
                                if success {
                                    LogManager.event(module: "LoginView.Authentication.firebase.addUser", message: "\(email) added toKeychain")
                                    
                                    /// Do additional stuff
                                    
                                    
                                    /// TODO: Storing firebase credentials:  Adding to local keychain
                                    /// TODO:  Make this driven by a dev or app flag to turn on or off.
                                    /// Delete user for clean up
                                    Authentication.keychain.deleteUser(username: email) { success, error in
                                        if success {
                                            LogManager.event(module: "Authentication.keychain.deleteUser", message: "\(email) deleted successfully.")
                                            
                                        } else {
                                            LogManager.event(module: "Authentication.keychain.changeUser", message: "Error deleting old account \(error!)")
                                        }
                                    }
                                    
                                    /// Add user to keychain
                                    Authentication.keychain.addUser(username: email, password: passwordVerify) { success, userID, error in
                                        if success {
                                            /// do stuff
                                            LogManager.event(module: "LoginView.Authentication.keychain.addUser", message: "\(email) added toKeychain")
                                            /// On to the next view
                                            appStatus.currentOnboardPageView = .onboardCompleteView

                                        } else {
                                            /// Handle failure to add user
                                            showKeychainAddUserFailedMessage = error?.localizedDescription ?? ""
                                            showKeychainAddUserFailedAlert = true

                                        }
                                    }
                            
                                    /// On to the next view
                                    appStatus.currentOnboardPageView = .onboardCompleteView

                                } else {
                                    
                                    print("** email address already in use: \(String(describing: error))")
                                    
                                    /// TODO: Storing firebase credentials:  Adding to local keychain
                                    /// TODO:  Make this driven by a dev or app flag to turn on or off.
                                    /// Delete user for clean up
                                    Authentication.keychain.deleteUser(username: email) { success, error in
                                        if success {
                                            LogManager.event(module: "Authentication.keychain.deleteUser", message: "\(email) deleted successfully.")
                                            
                                        } else {
                                            LogManager.event(module: "Authentication.keychain.changeUser", message: "Error deleting old account \(error!)")
                                        }
                                    }
                                    
                                    /// Add user to keychain
                                    Authentication.keychain.addUser(username: email, password: passwordVerify) { success, userID, error in
                                        if success {
                                            /// do stuff
                                            LogManager.event(module: "LoginView.Authentication.keychain.addUser", message: "\(email) added toKeychain")
                                            /// On to the next view
                                            appStatus.currentOnboardPageView = .onboardCompleteView

                                        } else {
                                            /// Handle failure to add user
                                            showKeychainAddUserFailedMessage = error?.localizedDescription ?? ""
                                            showKeychainAddUserFailedAlert = true

                                        }
                                    }

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

                        //}
                        #endif
                        
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
        .onSubmit {
            switch focusedField {
            case .passwordEntry:
                focusedField = .passwordVerify
            default:
                print("Creating account…")
            }
        }
    } // end view
} // end struc


struct OnboardPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardPasswordView()
            .environmentObject(AppStatus())
            .environmentObject(UserSettings())
    }
}

