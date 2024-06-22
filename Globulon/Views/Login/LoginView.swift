//
//  LoginView.swift
//  ViDrive
//
//  Created by David Holeman on 2/21/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import LocalAuthentication
import Security

struct LoginView: View {

    /// Login current assumes that the account with a username/password has already been created.  We would need to add logic to create an account.
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var userStatus: UserStatus

    init() {
        LogEvent.print(module: "LoginView", message: "UserStatus().isLoggedIn \(UserStatus().isLoggedIn)")

    }
    
    @State var username: String = ""
    @State var password: String = ""
    
    @State var email: String = ""
    
    @State var isLogoButton: Bool = false
    
    /// An entry to correspond to each field tag for sequenced entry.  Set the field to true if you want it to become first responder.  Since we assume an account has been created we set first responder to the password field since we do not prefill that.
    //@State var fieldFocus = [false, true]
    @State var fieldFocus = [false, false]
    
    @State var isHidePassword = true
    @State var isShowForgotPassword: Bool = false
    @State var isShowCreateAccount: Bool = false

    @State var btnBiometricEnabled = false
    @State var btnBiometricImage = "faceid"
    
    // email verification
    @State var isEmailVerified: Bool = false
    @State var isEmailVerifiedImage: String = "imgVerifyOff"
    
    @State var showLoginFailedAlert: Bool = false
    @State var showLoginFailedMessage: String = ""
    @State var showLoginFirebaseFailedAlert: Bool = false
    @State var showLoginFirebaseFailedMessage: String = ""
    
    @State var showBiometricFailedAlert: Bool = false
    @State var showBiometricFailedMessage: String = ""
    
    @AppStorage("password") var userPassword: String = ""

    
    let myDevice = Biometrics()
        
    var body: some View {
        HStack() {
            Spacer().frame(width: 16)
            
            VStack(alignment: .leading) {
                
                Spacer().frame(height: 90)
                HStack {
                    Button(action: {
                        isLogoButton.toggle()
                    }) {
                        Image(colorScheme == .dark ? AppValues.logos.appLogoDarkMode : AppValues.logos.appLogoTransparent)
                            .resizable()
                            .frame(width: 124, height: 124, alignment: .center)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Version : \(AppInfo.version) (\(AppInfo.build))")
                            .font(.system(size: 10, design: .monospaced))
                        Text(AppSettings.login.isKeychainLoginEnabled ? "AuthMode: Local" : "AuthMode: Remote")
                            .font(.system(size: 10, design: .monospaced))
                        Text("UserMode: \(UserSettings.init().userMode.description)")
                            .font(.system(size: 10, design: .monospaced))
                        Text("Articles: \(articlesFrom())")
                            .font(.system(size: 10, design: .monospaced))

                        Spacer()
                    }
                    .foregroundColor(isLogoButton ? (colorScheme == .dark ? .white : .black) : .clear)
                }
                .frame(height: 124)
                
                Spacer().frame(height: 90)
                
                Group {
                    
                    /// start
                    
                    HStack {
                        TextField(
                            "Email address",
                            text: $username,
                            onEditingChanged: {(editingChanged) in
                                if editingChanged {
                                    // check validity
                                    if isValidEmail(string: username) {
                                        isEmailVerified = true
                                    } else {
                                        isEmailVerified = false
                                    }
                                    
                                } else {

                                }
                            }
                        )
                        //.offset(x: -16)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .textCase(.lowercase)
                        .textContentType(.emailAddress)
                        .foregroundColor(Color.primary)
                        .onAppear {
                            //email = userSettings.email
                            // force lowercase
                            username = username.lowercased()
                            // check validity
                            if isValidEmail(string: username) {
                                isEmailVerified = true
                            } else {
                                isEmailVerified = false
                            }
                        }
                        .onChange(of: username) {
                            // check validity
                            if isValidEmail(string: username) {
                                isEmailVerified = true
                            } else {
                                isEmailVerified = false
                            }
                            
                            //if email != userSettings.email { isChanged = true }
                            
                        }
                        Image(isEmailVerifiedImage)
                            .imageScale(.large)
                            .frame(width: 32, height: 32, alignment: .center)
                            .onChange(of: email) {
                                isEmailVerified = isValidEmail(string: username)
                                if isEmailVerified {isEmailVerifiedImage = "imgVerifyOn" } else { isEmailVerifiedImage = "imgVerifyOff" }
                            }
                    }
                    .overlay(
                        Rectangle() // This creates the underline effect
                            .frame(height: 0.75)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.top, 40),
                        alignment: .bottomLeading
                    )
                    .padding(.bottom, 16)
                    
                    HStack {
                        if isHidePassword {
                            SecureField(
                                "password",
                                text: $password
                            )
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .foregroundColor(Color.primary)
                        } else {
                            TextField(
                                "password",
                                text: $password
                            )
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .foregroundColor(Color.primary)
                        }

                        Button(action: {
                            isHidePassword.toggle()
                        }) {
                            Image(systemName: isHidePassword ? "eye.slash" : "eye")
                                .imageScale(.medium)
                                .frame(width: 32, height: 32, alignment: .center)
                                .foregroundColor(colorScheme == .dark ? .white : .gray)
                        }
                    }
                    .overlay(
                        Rectangle() // This creates the underline effect
                            .frame(height: 0.75)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.top, 40),
                        alignment: .bottomLeading
                    )
                    
                    /// end
                    
//                    TextFieldEx (
//                        label: "password",
//                        text: $password,
//                        focusable: $fieldFocus,
//                        isSecureTextEntry: $isHidePassword,
//                        returnKeyType: .done,
//                        autocorrectionType: .no,
//                        //textColor: UIColor(Color("colorTextFixed")),
//                        textColor: UIColor(Color.primary),
//                        tag: 1
//                    )
//                    .frame(height: 40)
//                    .padding(.vertical, 0)
//                    //                    .overlay(Rectangle().frame(height: 0.5).padding(.top, 30).foregroundColor(Color("colorTextFixed")))
//                    //                    .foregroundColor(Color("colorTextFixed"))
//                    .overlay(Rectangle().frame(height: 0.5).padding(.top, 30).foregroundColor(Color.primary))
//                    .foregroundColor(Color.primary)
                }
                // end group
                
                Spacer().frame(height: 50)
                
                HStack {
                    /// Show button only if biometrics are enabled
                    if btnBiometricEnabled {
                        Button(action: {
                            
                            Authentication.biometric.authenticateUser { success, error in
                                if success {
                                    /// Biometric authentication succeeded
                                    ///
                                    
                                    /// The biometric auth succeeded but the user has not been logged into firebase.
                                    ///
                                    if AppSettings.login.isFirebaseLoginEnabled {
                                        /// let's ensure we have the username and password to work with
                                        print("^^firebase login info:")
                                        print("^^username: \(username)")
                                        print("^^userPassword:\(userPassword)")
                                        print("^^password: \(password)")
                                        
                                        Authentication.firebase.authUser(email: username, password: userPassword) {
                                            success, userID, error in
                                            if success {
                                                self.authenticated()
                                            } else {
                                                showLoginFirebaseFailedMessage = error?.localizedDescription ?? ""
                                                showLoginFirebaseFailedAlert = true
                                            }
                                        }
                                    }
                                    
                                    DispatchQueue.main.async(){
                                        UserSettings.init().isBiometricID = true  // set directly since we can't bring in published variables
                                        self.authenticated()
                                    }
                                    
                                } else {
                                    /// Biometric authentication failed
                                    ///
                                    showBiometricFailedMessage = error?.localizedDescription ?? ""
                                    showBiometricFailedAlert.toggle()
                                }
                            }
                            
                            //userSettings.isBiometricID = true
                        } ) {
                            Image(systemName: btnBiometricImage)
                                .resizable()
                                //.foregroundColor(Color("btnColorFixed"))
                                .foregroundColor(Color.primary)
                                .font(Font.title.weight(.thin))
                                .frame(width: 60, height: 60, alignment: .center)
                        }
                    } else { Spacer().frame(width: 60, height: 60) }
                    
                    Spacer()
                    
                    /// Login:  Here we are doing a standard username/password login
                    VStack {
                        Spacer()
                        Button(action: {
                            if username.isEmpty, password.isEmpty {
                                showLoginFailedAlert = true
                            }
                            
                            /// Local keychain authentication
                            if AppSettings.login.isKeychainLoginEnabled {
                                if Authentication.keychain.authUser(username: username, password: password) {
                                    self.authenticated()
                                } else {
                                    showLoginFailedMessage = "Invalid username/password"
                                    showLoginFailedAlert = true
                                }
                            }
                            
                            /// Firebase remote authentication
                            if AppSettings.login.isFirebaseLoginEnabled {
                                Authentication.firebase.authUser(email: username, password: password) {
                                    success, userID, error in
                                    if success {
                                        self.authenticated()
                                    } else {
                                        showLoginFirebaseFailedMessage = error?.localizedDescription ?? ""
                                        showLoginFirebaseFailedAlert = true
                                    }
                                }
                            }
                            
                        }) { Text("Login")
                                //.foregroundColor(Color("btnColorFixed"))
                                .foregroundColor(Color.primary)
                                .font(.system(size: 24, weight: .medium, design: .default))
                        }
                        .alert("Login Problem", isPresented: $showLoginFailedAlert) {
                            Button("Ok", role: .cancel) { }
                        } message: {
                            Text(showLoginFailedMessage)
                        }
                        .alert("Login Problem (firebase)", isPresented: $showLoginFirebaseFailedAlert) {
                            Button("Ok", role: .cancel) { }
                        } message: {
                            Text(showLoginFirebaseFailedMessage)
                        }

                    }
                }
                .frame(height: 60)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    
                    if userSettings.email == "" {
                        Button(action: {
                            isShowCreateAccount.toggle()
                            // TODO: goto create account
                        }) {
                            Text("create account")
                                //.foregroundColor(Color("btnColorFixed"))
                                .foregroundColor(Color.primary)
                                .font(.system(size: 14, weight: .light, design: .default))
                                .frame(height: 30)
                        }
                        .padding(.bottom, 16)
                    }
                    
                    Button(action: {
                        isShowForgotPassword.toggle()
                    }) {
                        Text("forgot password")
                            //.foregroundColor(Color("btnColorFixed"))
                            .foregroundColor(Color.primary)
                            .font(.system(size: 14, weight: .light, design: .default))
                            //.frame(height: 30)
                    }
                    .sheet(isPresented: $isShowForgotPassword) {
                        NavigationView {
                            ForgotPasswordView()
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button(action: {
                                            isShowForgotPassword.toggle()
                                        }) {
                                            ImageNavCancel()
                                        }
                                    }
                                    ToolbarItem(placement: .principal) {
                                        Text("reset password")
                                    }
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button(action: {
                                            isShowForgotPassword.toggle()
                                        }, label: {
                                            TextNavCancel()
                                        })
                                    }
                                }
                        }
                    }
                }
                    Spacer().frame(height: 60)
            } // end VStack

            Spacer().frame(width: 16)
        }
        //.background(AppValues.backgroundGradient.login)
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            /// Bring up local stored username
            if let storedUsername = UserDefaults.standard.value(forKey: "email") as? String {
                username = storedUsername
            }

            /// Show biometric options if the device supports them and if there has been a successful login first
            if myDevice.isBiometric() {
                switch myDevice.biometricType() {
                case .faceID:
                    btnBiometricImage = "faceid"
                    btnBiometricEnabled = true
                case .touchID:
                    btnBiometricImage = "touchid"
                    btnBiometricEnabled = true
                default:
                    // Biometric type didn't match allowed cases so disable
                    btnBiometricEnabled = false
                    }
            } else {
                /// if we can't evaluate the biometric capability then /disable
                btnBiometricEnabled = false
                UserSettings().isBiometricID = false
            }

            /// Once biometric is enabled by the user via iOS and the isBiometricID is set by the app this will autologin via biometrics
            ///
            if userSettings.isAutoBiometricLogin {
                if UserStatus().isLoggedIn == false {
                    /// if the setting to allow biometric login is set then try to login using biometrics.
                    if UserSettings.init().isBiometricID  && myDevice.isBiometric() == true {
                        Authentication.biometric.authenticateUser { success, error in
                            if success {
                                /// Biometric authentication succeded
                                
                                /// If firebase authentication make an attempt to login
                                ///
                                if AppSettings.login.isFirebaseLoginEnabled {
                                    /// let's ensure we have the username and password to work with
                                    print("^firebase login after biometric success")
                                    print("^userUsername: \(username)")
                                    print("^userPassword: \(password)")
                                }
                                
                                
                                ///  Finish out
                                DispatchQueue.main.async(){
                                    UserSettings.init().isBiometricID = true  // set directly since we can't bring in published variables
                                    self.authenticated()
                                }
                                
                            } else {
                                /// Biometric authenticiation failed
                                ///
                                showBiometricFailedMessage = error?.localizedDescription ?? ""
                                showBiometricFailedAlert.toggle()
                            }
                        }
                    }
                }
            }
            ///
            /// end auto login via biometrics

            processOnAppear()
            
        } // end HStack
        //.background(AppValues.backgroundGradient.login)
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
        
        .onTapGesture { self.hideKeyboard() }
        
        .alert("Biometric Problem", isPresented: $showBiometricFailedAlert) {
            Button("Ok", role: .cancel) { }
        } message: {
            Text(showBiometricFailedMessage)
        }
        
    }
    
    /// Return to the main thread once authenticated
    ///
    func authenticated() {
//        userPassword = password
        
        /// We update the email address with the latest username entry that succeeded
        ///
        userSettings.email = username
        
        /// If firebase authentication make an attempt to login
        ///
        if AppSettings.login.isFirebaseLoginEnabled {
            /// let's ensure we have the username and password to work with
            print("^firebase login info:")
            print("^username: \(username)")
            print("^userPassword: \(userPassword)")
            print("^password: \(password)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            NotificationCenter.default.post(name: Notification.Name("isLoggedIn"), object: nil)
        }
        self.presentationMode.wrappedValue.dismiss()
    }
    
    /// Perform and/or launch any processes or tasks before the user interacts with the app
    ///
    func processOnAppear() {
        
        LogEvent.print(module: "LoginView.processOnAppear()", message: "starting...")
        
        // Do stuff
        
        LogEvent.print(module: "LoginView.processOnAppear()", message: "...finished")
    }
    
}

#Preview {
    LoginView()
        .environmentObject(UserSettings())
}
