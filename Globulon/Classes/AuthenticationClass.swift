//
//  AuthenticationClass.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2025.02.25)
 - Note:
*/

import SwiftUI
import LocalAuthentication
import Security

/// Firebase
///
#if FIREBASE_ENABLED
import FirebaseAuth
import FirebaseAnalytics
#endif

import LocalAuthentication

class Authentication {
    
    #if FIREBASE_ENABLED || KEYCHAIN_ENABLED
    class biometric {
        class func authenticateUser() async -> (Bool, Error?) {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let biometryType = context.biometryType
                var reason = "Authenticate with \(biometryType)"
                if biometryType == .faceID {
                    reason = "Authenticate with Face ID"
                } else if biometryType == .touchID {
                    reason = "Authenticate with Touch ID"
                }
                
                do {
                    let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                    LogManager.event(module: "Authentication.biometric.authenticateUser", message: "Biometric authentication. success: \"\(success)\".")
                    return (success, nil)
                } catch let evaluationError as LAError {
                    LogManager.event(module: "Authentication.biometric.authenticateUser", message: "Biometric authentication failed. evaluationError: \"\(evaluationError.localizedDescription)\"")
                    return (false, evaluationError)
                } catch {
                    return (false, error)
                }
            } else {
                if let error = error {
                    LogManager.event(module: "Authentication.biometric.authenticateUser", message: "Error code: (\(error.code)) desc: \"\(error.localizedDescription)\"")
                    return (false, error)
                } else {
                    return (false, nil)
                }
            }
        }
        
        static private func handleEvaluationError(_ error: LAError) -> (errorCode: Int, errorCase: LAError.Code, description: String) {
            let description: String
            switch error.code {
            case .authenticationFailed:
                description = "Authentication failed: User did not provide valid credentials."
            case .userCancel:
                description = "Authentication was canceled by the user."
            case .userFallback:
                description = "User chose to use the fallback authentication method."
            case .systemCancel:
                description = "Authentication was canceled by the system."
            case .passcodeNotSet:
                description = "Passcode is not set on the device."
            case .biometryNotAvailable:
                description = "Biometric authentication is not available on this device."
            case .biometryNotEnrolled:
                description = "Biometry is not enrolled on this device."
            case .biometryLockout:
                description = "Biometry is locked out due to too many failed attempts."
            default:
                description = "Authentication failed due to an unknown error: \(error.localizedDescription)"
            }
            return (error.code.rawValue, error.code,  description)
        }
    }
    #endif
    
    /// Keychain authentication functions
    ///
    //#if KEYCHAIN_ENABLED
    class keychain {
        
        class func authUser(username: String, password: String) -> Bool {
            
            let serviceName = AppSettings.appName
            let accountData = username.data(using: .utf8)!
            
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: accountData,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne
            ]
            
            var result: AnyObject?
            let error = SecItemCopyMatching(query as CFDictionary, &result)
            
            let status = convertOSStatusToNSError(error)
            
            if error == errSecSuccess,
               let passwordData = result as? Data,
               let retrievedPassword = String(data: passwordData, encoding: .utf8) {
                if retrievedPassword == password {
                    LogManager.event(module: "Authentication.keychain.authUser", message: "Authorization succeded.  user: \"\(maskUsername(username))\" \"\(maskPassword(password))\"")
                    return true
                } else {
                    LogManager.event(module: "Authentication.keychain.authUser", message: "Authorization failed.  user: \"\(maskUsername(username))\" \"\(maskPassword(password))\", error: \(status.localizedDescription)")
                    return false
                }
            } else {
                LogManager.event(module: "Authentication.keychain.authUser", message: "\(status.localizedDescription)")
                return false
            }
        }

        class func addUser(username: String, password: String, completion: @escaping (Bool, String, Error?) -> Void) {
            
            let serviceName = AppSettings.appName
            let accountData = username.data(using: .utf8)!
            let passwordData = password.data(using: .utf8)!
            
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: accountData,
                kSecValueData: passwordData,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            // Delete any existing items with the same account before adding the new one
            SecItemDelete(query as CFDictionary)
            
            let error = SecItemAdd(query as CFDictionary, nil)

            let result = convertOSStatusToNSError(error)

            guard error == errSecSuccess else {
                evaluateKeychainError(errorCode: error)
                LogManager.event(module: "Authentication.keychain.addUser", message: "\(result)")
                return completion(false, "", result)
            }
                    
            LogManager.event(module: "Authentication.keychain.addUser", message: "\(maskUsername(username))/\(maskPassword(password)) added successfully.")
            LogManager.event(output: .debugOnly, module: "Authentication.keychain.addUser", message: "\(username)/\(password) added successfully.")

            completion(true, "", result)
        }
        
        class func deleteUser(username: String, completion: (Bool, Error?) -> Void) {
            
            let accountData = username.data(using: .utf8)!
            
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: accountData,
            ]
            
            let error = SecItemDelete(query as CFDictionary)
            
            let result = convertOSStatusToNSError(error)

            if error != errSecSuccess {
                LogManager.event(module: "Authentication.keychain.deleteUser", message: "\(result)")
                completion(false, result)
            } else {
                
                LogManager.event(module: "Authentication.keychain.deleteUser", message: "\(AppSettings.appName) removed successfully.")
                completion(true, result)
            }
        }
        
        class func changeUser(oldUsername: String, newUsername: String, completion: @escaping (Bool, Error?) -> Void) {
            
            Authentication.keychain.retrievePassword(username: oldUsername) { success, password, error in
                if success {
                    /// Delete old account to clear it out
                    Authentication.keychain.deleteUser(username: oldUsername) { success, error in
                        if success {
                            LogManager.event(module: "Authentication.keychain.deleteUser", message: "\(maskUsername(oldUsername)) deleted successfully.")
                            /// Add the new user
                            Authentication.keychain.addUser(username: newUsername, password: password) { success, userID, error in
                                if success {
                                    /// do stuff
                                    LogManager.event(module: "Authentication.keychain.changeUser", message: "\(maskUsername(oldUsername)) added successfully.")
                                    completion(true, error)
                                } else {
                                    LogManager.event(module: "Authentication.keychain.changeUser", message: "Error adding account \(error!)")
                                    completion(false, error)
                                }
                            }
                            
                        } else {
                            LogManager.event(module: "Authentication.keychain.changeUser", message: "Error deleting old account \(error!)")
                            completion(false, error)
                        }
                    }
                } else {
                    LogManager.event(module: "Authentication.keychain.changeUser", message: "Error retrieving password \(error!)")
                    completion(false, error)
                }
            }
        }
        
        class func retrievePassword(username: String, completion: @escaping (Bool, String, Error?) -> Void) {
            
            let serviceName = AppSettings.appName
            let accountData = username.data(using: .utf8)!
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: accountData,
                kSecReturnData as String: true
            ]

            var result: AnyObject?
            let error = SecItemCopyMatching(query as CFDictionary, &result)
            
            let status = convertOSStatusToNSError(error)
            
            if error == errSecSuccess, let passwordData = result as? Data, let password = String(data: passwordData, encoding: .utf8) {
                LogManager.event(module: "Authentication.keychain.retrievePassword", message: "Password \"\(maskPassword(password))\" retrieved successfully.")
                completion(true, password, status)
            } else if error == errSecItemNotFound {
                evaluateKeychainError(errorCode: error)
                LogManager.event(module: "Authentication.keychain.retrievePassword", message: "Error \(status) Password not found in Keychain")
            } else {
                evaluateKeychainError(errorCode: error)
                LogManager.event(module: "Authentication.keychain.retrievePassword", message: "Error \(status) Password retreival failed.")
            }
        }
                
        class func updatePassword(username: String, passwordOld: String, passwordNew: String, completion: @escaping (Bool, Error?) -> Void) {
            
            let serviceName = AppSettings.appName
            let accountData = username.data(using: .utf8)!
            let passwordData = passwordNew.data(using: .utf8)!
            
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: serviceName,
                kSecAttrAccount: accountData,
                kSecValueData: passwordData,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            // Create a dictionary with the attributes to be updated.
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: passwordData
            ]
            
            // Perform the update operation.
            let error = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            let result = convertOSStatusToNSError(error)
            
            if error == errSecSuccess {
                LogManager.event(module: "Authentication.keychain.updatePassword", message: "Password \"\(maskPassword(passwordOld))\"  changed to \"\(maskPassword(passwordNew))\" successfully")
                completion(true, result)
            } else {
                evaluateKeychainError(errorCode: error)
                LogManager.event(module: "Authentication.keychain.updatePassword", message: "Error \(result)")
                completion(false, result)
            }
        }
        
        class func convertOSStatusToNSError(_ status: OSStatus) -> NSError {
            return NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }

        private class func evaluateKeychainError(errorCode: OSStatus) {
            LogManager.event(module: "Authentication.evaluateKeychainError", message: "Error code: \(errorCode)")
            if let errorMessage = SecCopyErrorMessageString(errorCode, nil) {
                LogManager.event(module: "Authentication.evaluateKeychainError", message: "Error message: \(errorMessage)")
            } else {
                LogManager.event(module: "Authentication.evaluateKeychainError", message: "Unexpcted Error (\(errorCode))")
            }
        }
    }
    //#endif
    
    /// Firebase authentication
    ///
    #if FIREBASE_ENABLED
    class firebase {
        
        class func authUser(email: String, password: String, completion: @escaping (Bool, String, Error?) -> Void) {
            
            @AppStorage("firebaseUID") var firebaseUID: String = ""
            @AppStorage("password") var userPassword: String = ""
            
            Auth.auth().signIn(withEmail: email, password: password) {authResult, error in
                
                if let error = error {
                    
                    LogManager.event(module: "Authentication.firebase.authUser", message: "Authorization failed.  user: \"\(maskEmail(email))\" \"\(maskPassword(password))\", error: \(error.localizedDescription)")

                    completion(false, "", error)
                    
                } else {
                    /// User was authorized
                    LogManager.event(module: "Authentication.firebase.authUser", message: "Authorization was successful.  user: \"\(maskEmail(email))\", password: \"\(maskPassword(password))\", authResut = \(maskString(authResult?.user.uid ?? ""))")
                    LogManager.event(output: .debugOnly, module: "Authentication.firebase.authUser", message: "Authorization was successful.  user: \"\(email)\", password: \"\(password)\", authResut = \(authResult?.user.uid ?? "")")
                    
                    /// Save results
                    firebaseUID = authResult?.user.uid ?? ""
                    
                    /// OPTION: Firebase event:  login
                    ///
                    Analytics.logEvent(AnalyticsEventLogin, parameters: [AnalyticsParameterMethod: "email"])
                    
                    completion(true, authResult?.user.uid ?? "", error)
                }
            }
        }

         
        class func addUser(email: String, password: String, completion: @escaping (Bool, String, Error?) -> Void) {
            Auth.auth().createUser(withEmail: email, password: password) {authResult, error in
                
                @AppStorage("firebaseUID") var firebaseUID: String = ""
                @AppStorage("password") var userPassword: String = ""
                
                if let error = error {
                    
                    LogManager.event(module: "Authentication.firebase.addUser", message: "Adding user failed.  user: \"\(maskEmail(email))\", error: \(error.localizedDescription)")
                    completion(false, "", error)
                } else {
                    /// User was created
                    ///
                    LogManager.event(module: "Authentication.firebase.addUser", message: "Adding user was successful.  user: \"\(maskEmail(email))\", password: \"\(maskPassword(password))\", authResut: = \(authResult?.user.uid ?? "")")
                    
                    /// Save results
                    firebaseUID = authResult?.user.uid ?? ""
                    userPassword = password

                    completion(true, authResult?.user.uid ?? "", error)
                }
            }
        }
        
        class func deleteUser(email: String, completion: @escaping (Bool, Error?) -> Void) {
            
            @AppStorage("firebaseUID") var firebaseUID: String = ""
            @AppStorage("email") var userEmail: String = ""
            @AppStorage("password") var userPassword: String = ""
            
            ///  Get the current user
            guard let user = Auth.auth().currentUser else {
                // No user is signed in
                return
            }
            
            /// OPTION:  Delete the user's data from the database (optional)
            /// deletion code here...
            
            /// Delete the current user
            user.delete { error in
                if let error = error {
                    LogManager.event(module: "Authentication.firebase.deleteUser", message: "Deleting user failed.  user: \"\(maskEmail(email))\", error: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    LogManager.event(module: "Authentication.firebase.deleteUser", message: "Deleting user was successful.  user: \"\(maskEmail(email))\"")

                    completion(true, error)
                }
            }
        }
        
        class func passwordReset(email: String, completion: @escaping (Bool, Error?) -> Void) {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    /// Reset failed to send
                    LogManager.event(module: "Authentication.firebase.passwordReset", message: "Password reset failed.  user: \"\(maskEmail(email))\", error: \(error.localizedDescription)")
                    completion(false, error)

                } else {
                    /// Reset was sent
                    LogManager.event(module: "Authentication.firebase.passwordReset", message: "Password reset sent.  email: \"\(maskEmail(email))\"")
                    completion(true, error)
                }
            }
        }
        
        class func changeUser(emailOld: String, emailNew: String, completion: @escaping (Bool, Error?) -> Void) {
            
            @AppStorage("email") var userEmail: String = ""
            
            /// Get the current user
            guard let user = Auth.auth().currentUser else { return }
            
            /// Send verification to the new email before updating
            user.sendEmailVerification(beforeUpdatingEmail: emailNew) { error in
                if let error = error {
                    /// Failed to send email verification
                    LogManager.event(module: "Authentication.firebase.changeEmail", message: "Failed to send email verification. emailOld: \"\(emailOld)\" emailNew: \"\(emailNew)\"")
                    LogManager.event(module: "Authentication.firebase.changeEmail", message: "This operation is sensitive and requires recent authentication. Log out then log in again before retrying this request.")
                    completion(false, error)
                } else {
                    /// Email verification sent, remind user to check their email
                    LogManager.event(module: "Authentication.firebase.changeEmail", message: "Verification email sent. Please verify your new email: \"\(emailNew)\" before it is updated.")
                    /// You can't update userEmail here directly because the email is not yet confirmed.
                    /// Consider updating userEmail after the user confirms their new email.
                    completion(true, nil)
                }
            }
        }

        class func confirmEmailChange() {
            guard let user = Auth.auth().currentUser else {
                // Handle case where there is no current user
                return
            }
            
            user.reload { error in
                if let error = error {
                    // Handle error (e.g., could not reload user)
                    print("Error reloading user: \(error.localizedDescription)")
                } else if user.isEmailVerified {
                    // Assuming the user's email is now verified, update app records
                    @AppStorage("email") var userEmail: String = ""
                    userEmail = user.email ?? ""
                    
                    // Log success and notify the user
                    LogManager.event(module: "Authentication", message: "Email verification confirmed and updated successfully.")
                    // Optionally, notify the user within the app that their email has been updated successfully.
                } else {
                    // If the email isn't verified yet, prompt the user or handle accordingly
                    LogManager.event(module: "Authentication", message: "Email verification not confirmed yet. Please check your email and verify.")
                }
            }
        }
        
        static func handleEvaluationError(_ error: NSError) -> (errorCode: Int, errorCase: AuthErrorCode.Code?, message: String, description: String) {
            if let errorCase = AuthErrorCode.Code(rawValue: error.code) {
                let userFriendlyMessage: String
                switch errorCase {
                case .networkError:
                    userFriendlyMessage = "Network error. Please try again."
                case .wrongPassword:
                    userFriendlyMessage = "The password is invalid."
                case .userNotFound:
                    userFriendlyMessage = "No user found with this email."
                case .emailAlreadyInUse:
                    userFriendlyMessage = "The email is already in use by another account."
                case .invalidEmail:
                    userFriendlyMessage = "The email address is badly formatted."
                case .tooManyRequests:
                    userFriendlyMessage = "Too many attempts. Please try again later."
                case .userDisabled:
                    userFriendlyMessage = "This user account has been disabled."
                default:
                    userFriendlyMessage = "An unknown error occurred."
                }
                return (error.code, errorCase, userFriendlyMessage, error.localizedDescription)
            } else {
                let fallbackMessage = "An error occurred."
                return (error.code, nil, fallbackMessage, error.localizedDescription)
            }
        }
        
        /*
        class func changeUser(emailOld: String, emailNew: String, completion: @escaping (Bool, Error?) -> Void) {
            
            @AppStorage("email") var userEmail: String = ""
            
            /// Get the current user
            guard let user = Auth.auth().currentUser else { return }
            
            /// Update the current user
            user.updateEmail(to: emailNew) { error in
                if let error = error {
                    /// Reset failed to send
                    LogManager.event(module: "Authentication.firebase.changeReset", message: "Email change failed.  emailOld: \"\(emailOld)\" emailNew: \"\(emailOld)\"")
                    LogManager.event(module: "Authentication.firebase.changeReset", message: "This operation is sensitive and requires recent authentication. Log out then log in again before retrying this request.")
                    completion(false, error)
                } else {
                    /// save the email address
                    userEmail = emailNew
                    LogManager.event(module: "Authentication.firebase.changeEmail", message: "Email changed.  emailOld: \"\(emailOld)\" emailNew: \"\(emailOld)\"")
                    completion(true, error)
                }
            }

        }
         */
    }
    #endif
}

