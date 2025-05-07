//
//  LoginViewV2.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
- Version: 1.0.0 (2025.02.25)
- Note:
*/

import SwiftUI
import LocalAuthentication
import Security

struct LoginViewV2: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var userStatus: UserStatus
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    @State private var isHidePassword = true
    @State private var isShowForgotPassword: Bool = false
    @State private var isShowCreateAccount: Bool = false
    @State private var isEmailVerified = false
    @State private var isEmailVerifiedImage = "imgVerifyOff"
    
    @State private var btnBiometricEnabled = false
    @State private var btnBiometricImage = "faceid"
    
    @State private var isLogoButton: Bool = false
    
    @State private var showAlert: AlertType?
    
    private let biometrics = Biometrics()
    
    var body: some View {
        VStack {
            Spacer().frame(height: 30)
            HeaderView(isLogoButton: $isLogoButton)
            Spacer().frame(height: 90)
            InputFields(username: $username, password: $password, isHidePassword: $isHidePassword, isEmailVerified: $isEmailVerified, isEmailVerifiedImage: $isEmailVerifiedImage)
            Spacer().frame(height: 50)
            ActionsView(username: $username, password: $password, btnBiometricEnabled: $btnBiometricEnabled, btnBiometricImage: $btnBiometricImage, showAlert: $showAlert, authenticateUser: authenticateUser)
            Spacer()
            FooterView(isShowCreateAccount: $isShowCreateAccount, isShowForgotPassword: $isShowForgotPassword)
            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 16)
        .onAppear(perform: setupView)
        .alert(item: $showAlert, content: alertForType)
        .onTapGesture { hideKeyboard() }
    }
    
    // MARK: - Setup and Authentication
    
    private func setupView() {
        loadStoredUsername()
        configureBiometricOptions()
        autoLoginIfEnabled()
    }
    
    private func loadStoredUsername() {
        if let storedUsername = UserDefaults.standard.string(forKey: "email") {
            username = storedUsername
            isEmailVerified = isValidEmail(username)
            isEmailVerifiedImage = isEmailVerified ? "imgVerifyOn" : "imgVerifyOff"
        }
    }
    
    
    private func loadStoredPassword() {
        Authentication.keychain.retrievePassword(username: username) {success, password, error in
            if success {
                self.password = password
            } else if let error = error {
                LogEvent.print(module: "LoginView().loadStoredPassword()", message: "**Error retrieving password: \(error.localizedDescription)")
            } else {
                LogEvent.print(module: "LoginView().loadStoredPassword()", message: "**Password retrieval failed for unknown reasons.")
            }
        }
    }
    
    private func configureBiometricOptions() {
        if biometrics.isBiometricSupported {
            btnBiometricEnabled = AppSettings.feature.isLoginBiometricEnabled
            btnBiometricImage = biometrics.biometricType.imageName
            
            /// Trigger auto biometric login if enabled
            if userSettings.isAutoBiometricLogin {
                Task {
                    let (success, error) = await Authentication.biometric.authenticateUser()
                    if success {
                        authenticateUser(source: .autoBiometric)
                    } else if let error {
                        showAlert = .loginFailed(error.localizedDescription)
                    }
                }
            }
            
        }
    }
    
    private func autoLoginIfEnabled() {
        guard userSettings.isAutoLogin, !userStatus.isLoggedIn else { return }
        authenticateUser(source: .autoLogin)
    }
    
    private func authenticateUser(source: AuthSource) {

        var internalPassword = ""

        switch source {
        case .biometric, .autoLogin, .autoBiometric:
            Authentication.keychain.retrievePassword(username: username) {success, storedPassword, error in
                if success {
                    internalPassword = storedPassword
                } else if let error = error {
                    LogEvent.print(module: "LoginView.authenticateUser()", message: "**Error retrieving password: \(error.localizedDescription)")
                } else {
                    LogEvent.print(module: "LoginView.authenticateUser()", message: "**Password retrieval failed for unknown reasons.")
                }
            }
            break
        case .manual:
            guard !username.isEmpty, !password.isEmpty else {
                showAlert = .loginFailed("Please enter a username and password")
                return
            }
            internalPassword = password
            break
        }

        /// Authentication logic (e.g., Keychain or Firebase) goes here...
        #if KEYCHAIN_ENABLED
        if Authentication.keychain.authUser(username: username, password: internalPassword) {
            finalizeAuthentication()
            return
        } else {
            showAlert = .loginFailed("Invalid username or password.")
        }
        #endif

        #if FIREBASE_ENABLED
        Authentication.firebase.authUser(email: username, password: internalPassword) { success, userID, error in
            if success {
                finalizeAuthentication()
                saveCredentialsToKeychain(internalPassword: internalPassword)
            } else if let error = error as NSError? {
                let (errorCode, errorCase, message, description) = Authentication.firebase.handleEvaluationError(error)
                
                // Log the detailed error for debugging
                print("Firebase Error Code: \(errorCode)")
                print("firebaseUserMessage: \(message)")
                print("Firebase Description: \(description)")

                switch errorCase {
                case .networkError:
                    showAlert = .loginLocally(
                        "\(description)\nDo you want to proceed anyway?",
                        continueAction: {
                            /// User chose to continue
                            finalizeAuthentication()
                        },
                        cancelAction: {
                            /// User chose to cancel.  Don't need to do anything here unless you want to clean up or reset anything
                            /// before trying again
                            ///
                            /// Do stuff if needed...
                        }
                    )
                default:
                    showAlert = .loginFailed(message)
                    break
                }
            }
        }
        #endif
    }
    
    private func finalizeAuthentication() {
        userSettings.email = username
        userStatus.isLoggedIn = true
        
        // do this as we exit the app not here
        //userSettings.lastAuth = Date()
        
        NotificationCenter.default.post(name: Notification.Name("isLoggedIn"), object: nil)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveCredentialsToKeychain(internalPassword: String) {
        Authentication.keychain.addUser(username: username, password: internalPassword) { success, _, error in
            if !success {
                showAlert = .keychainFailed(error?.localizedDescription ?? "Unknown error.")
            }
        }
    }
    
//    private func alertForType(type: AlertType) -> Alert {
//        switch type {
//        case .loginFailed(let message):
//            return Alert(title: Text("Login Problem"), message: Text(message), dismissButton: .default(Text("OK")))
//        case .keychainFailed(let message):
//            return Alert(title: Text("Keychain Problem"), message: Text(message), dismissButton: .default(Text("OK")))
//        }
//    }
    private func alertForType(type: AlertType) -> Alert {
        switch type {
        case .loginFailed(let message):
            return Alert(
                title: Text("Login Problem"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        case .keychainFailed(let message):
            return Alert(
                title: Text("Keychain Problem"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        case .loginLocally(let message,let continueAction, let cancelAction):
            return Alert(
                title: Text("Login Problem"),
                message: Text(message),
                primaryButton: .default(Text("Continue"), action: continueAction),
                secondaryButton: .cancel(Text("Cancel"), action: cancelAction)
            )
        case .confirmation(let message, let continueAction, let cancelAction):
            return Alert(
                title: Text("Confirmation Required"),
                message: Text(message),
                primaryButton: .default(Text("Continue"), action: continueAction),
                secondaryButton: .cancel(Text("Cancel"), action: cancelAction)
            )
        }
    }
    // MARK: - Subviews

    struct HeaderView: View {
        @Binding var isLogoButton: Bool
        
        var body: some View {
            VStack {
                HStack() {
                    VStack {
                        LogoButton(isLogoButton: $isLogoButton)
                    }
                    //.border(Color.black, width: 1)
                    Spacer()
                    VStack {
                        AppInfoView(isLogoButton: $isLogoButton)
                    }
                    .frame(height: 124)
                    //.border(Color.red, width: 1)
                }
                Spacer()
            }
            .frame(height:132)
            //.border(Color.black, width: 1)
        }
    }

    struct LogoButton: View {
        @Binding var isLogoButton: Bool
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Button(action: {
                isLogoButton.toggle()
            }) {
                Image(colorScheme == .dark ? "appLogoDarkMode" : "appLogoTransparent")
                    .resizable()
                    .frame(width: 124, height: 124)
                    .scaledToFit()
            }
        }
    }
    
    struct AppInfoView: View {
        @Binding var isLogoButton: Bool
        
        @State private var tapCount = 0
        @State private var isTapThreshold = false
        @State private var timer: Timer?
        
        var body: some View {
            VStack(alignment: .leading) {
                if isLogoButton {
                    Text("Version : \(VersionManager.releaseDesc)")
                        .font(.system(size: 10, design: .monospaced))
                    Text("AuthMode: \(UserSettings().authMode.description)")
                        .font(.system(size: 10, design: .monospaced))
                    Text("UserMode: \(UserSettings().userMode.description)")
                        .font(.system(size: 10, design: .monospaced))
                    Text("Articles: \(articlesLocation())")
                        .font(.system(size: 10, design: .monospaced))
                }
            }
            .foregroundColor(isLogoButton ? .primary : .clear)
            .onTapGesture {
                if timer == nil {
                    // Start the timer when the first tap is detected
                    startTimer()
                }

                tapCount += 1

                if tapCount == 5 {
                    isTapThreshold = true
                    resetTapTracking()
                }
            }
            .alert("Change UserMode", isPresented: $isTapThreshold) {
                Button("Production", role: .cancel) {
                    UserSettings.init().userMode = .production
                }
                Button("Development", role: .none) {
                    UserSettings.init().userMode = .development
                }
                Button("Test", role: .none) {
                    UserSettings.init().userMode = .test
                }
            } message: {
                Text("Please choose an option to proceed.")
            }
        }
        private func startTimer() {
            timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [self] _ in
                Task { @MainActor in
                    resetTapTracking()
                }
            }
        }

        private func resetTapTracking() {
            timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [self] _ in
                Task { @MainActor in
                    tapCount = 0
                    timer?.invalidate()
                    timer = nil
                }
            }
        }
    }
    
    struct BiometricButton: View {
        let imageName: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Image(systemName: imageName)
                    .resizable()
                    .font(Font.title.weight(.thin))
                    .frame(width: 60, height: 60)
                    .foregroundColor(.primary)
            }
        }
    }
    
    struct InputFields: View {
        @Binding var username: String
        @Binding var password: String
        @Binding var isHidePassword: Bool
        @Binding var isEmailVerified: Bool
        @Binding var isEmailVerifiedImage: String
        
        var body: some View {
            VStack {
                HStack {
                    TextField("Email address", text: $username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: username) {
                            isEmailVerified = isValidEmail(username)
                            isEmailVerifiedImage = isEmailVerified ? "imgVerifyOn" : "imgVerifyOff"
                        }
                    Image(isEmailVerifiedImage)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .overlay(Rectangle().frame(height: 0.75).foregroundColor(.primary), alignment: .bottom)
                .padding(.bottom, 16)
                HStack {
                    if isHidePassword {
                        SecureField("Password", text: $password)
                    } else {
                        TextField("Password", text: $password)
                    }
                    PasswordToggleButton(isHidePassword: $isHidePassword)
                }
                .overlay(Rectangle().frame(height: 0.75).foregroundColor(.primary), alignment: .bottom)
            }
        }
    }

    struct PasswordToggleButton: View {
        @Binding var isHidePassword: Bool
        var body: some View {
            Button(action: { isHidePassword.toggle() }) {
                Image(systemName: isHidePassword ? "eye.slash" : "eye")
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
            }
        }
    }

    struct ActionsView: View {
        @Binding var username: String
        @Binding var password: String
        @Binding var btnBiometricEnabled: Bool
        @Binding var btnBiometricImage: String
        @Binding var showAlert: AlertType?
        let authenticateUser: (AuthSource) -> Void
        
        var body: some View {
            HStack {
                if btnBiometricEnabled {
                    BiometricButton(imageName: btnBiometricImage) {
                        Task {
                            let (success, error) = await Authentication.biometric.authenticateUser()
                            if success {
                                authenticateUser(.biometric)
                            } else {
                                showAlert = .loginFailed(error?.localizedDescription ?? "Unknown error.")
                            }
                        }
                    }
                }
                Spacer()
                Button(action: {
                    authenticateUser(.manual)
                }) {
                    Text("Login")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color.primary)
                }
            }
        }
    }

    struct FooterView: View {
        @Binding var isShowCreateAccount: Bool
        @Binding var isShowForgotPassword: Bool
        
        @EnvironmentObject var userSettings: UserSettings
        
        var body: some View {
            VStack {
                HStack {
                    if userSettings.email == "" {
                        Button(action: {
                            isShowCreateAccount.toggle()
                            // TODO: goto create account.
                            // Not done yet
                        }) {
                            Text("create account")
                                //.foregroundColor(Color("btnColorFixed"))
                                .foregroundColor(Color.primary)
                                .font(.system(size: 14, weight: .light, design: .default))
                                .frame(height: 30)
                        }
                        .padding(.bottom, 16)
                    }
                    Spacer()
                }
                HStack {
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
                    Spacer()
                }
            }
        }
    }
    
}

// MARK: - External helpers and Enums

enum AlertType: Identifiable {
    case loginFailed(String)
    case keychainFailed(String)
    case loginLocally(String, continueAction: () -> Void, cancelAction: () -> Void)
    case confirmation(String, continueAction: () -> Void, cancelAction: () -> Void) // New case with callbacks

    var id: String {
        switch self {
        case .loginFailed(let message): return message
        case .keychainFailed(let message): return message
        case .loginLocally(let message, _, _): return message
        case .confirmation(let message, _, _): return message
        }
    }
}

func isValidEmail(_ email: String) -> Bool {
    let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
}

#Preview {
    LoginViewV2()
        .environmentObject(UserSettings())
}
