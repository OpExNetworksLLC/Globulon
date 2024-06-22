//
//  AuthenticationClass.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

/// Biometric and Keychain
///
import LocalAuthentication
import Security

/// Firebase
///
import FirebaseAuth

class Authentication {
    
    class biometric {
        /// Authenticate and then return true/false and the error code
        ///
        class func authenticateUser(completion: @escaping (Bool, Error?) -> Void) {
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
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluationError in
                    DispatchQueue.main.async {
                        LogEvent.print(module: "Authentication.biometric.authenticateUser", message: "Biometric authentication.  success: \"\(success)\".  evaluationError: \"\(String(describing: evaluationError))\"")
                        
                        completion(success, evaluationError)
                    }
                }
            } else {
                /// Biometric authentication is not available on this device or it's disabled.
                ///
                LogEvent.print(module: "Authentication.biometric.authenticateUser", message: "Error code: (\(error!.code))  desc: \"\(error!.localizedDescription)\"")
                completion(false, error)
            }
        }
    }
    
    /// Keychain authentication functions
    class keychain {
        
        class func authUser(username: String, password: String) -> Bool {
            
            let serviceName = AppValues.appName
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
                    LogEvent.print(module: "Authentication.keychain.authUser", message: "Authorization succeded.  user: \"\(username)\" \"\(password)\"")
                    return true
                } else {
                    LogEvent.print(module: "Authentication.keychain.authUser", message: "Authorization failed.  user: \"\(username)\" \"\(password)\", error: \(status.localizedDescription)")
                    return false
                }
            } else {
                LogEvent.print(module: "Authentication.keychain.authUser", message: "\(status.localizedDescription)")
                return false
            }
        }

        class func addUser(username: String, password: String, completion: @escaping (Bool, String, Error?) -> Void) {
            
            let serviceName = AppValues.appName
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
                LogEvent.print(module: "Authentication.keychain.addUser", message: "\(result)")
                return completion(false, "", result)
            }
                    
            LogEvent.print(module: "Authentication.keychain.addUser", message: "\(username)/\(password) added successfully.")
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
                LogEvent.print(module: "Authentication.keychain.deleteUser", message: "\(result)")
                completion(false, result)
            } else {
                
                LogEvent.print(module: "Authentication.keychain.deleteUser", message: "\(AppValues.appName) removed successfully.")
                completion(true, result)
            }
        }
        
        class func changeUser(oldUsername: String, newUsername: String, completion: @escaping (Bool, Error?) -> Void) {
            
            Authentication.keychain.retrievePassword(username: oldUsername) { success, password, error in
                if success {
                    /// Delete old account to clear it out
                    Authentication.keychain.deleteUser(username: oldUsername) { success, error in
                        if success {
                            LogEvent.print(module: "Authentication.keychain.deleteUser", message: "\(oldUsername) deleted successfully.")
                            /// Add the new user
                            Authentication.keychain.addUser(username: newUsername, password: password) { success, userID, error in
                                if success {
                                    /// do stuff
                                    LogEvent.print(module: "Authentication.keychain.changeUser", message: "\(oldUsername) added successfully.")
                                    completion(true, error)
                                } else {
                                    LogEvent.print(module: "Authentication.keychain.changeUser", message: "Error adding account \(error!)")
                                    completion(false, error)
                                }
                            }
                            
                        } else {
                            LogEvent.print(module: "Authentication.keychain.changeUser", message: "Error deleting old account \(error!)")
                            completion(false, error)
                        }
                    }
                } else {
                    LogEvent.print(module: "Authentication.keychain.changeUser", message: "Error retrieving password \(error!)")
                    completion(false, error)
                }
            }
        }
        
        class func retrievePassword(username: String, completion: @escaping (Bool, String, Error?) -> Void) {
            
            let serviceName = AppValues.appName
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
                LogEvent.print(module: "Authentication.keychain.retrievePassword", message: "Password \"\(password)\" retrieved successfully.")
                completion(true, password, status)
            } else if error == errSecItemNotFound {
                evaluateKeychainError(errorCode: error)
                LogEvent.print(module: "Authentication.keychain.retrievePassword", message: "Error \(status) Password not found in Keychain")
            } else {
                evaluateKeychainError(errorCode: error)
                LogEvent.print(module: "Authentication.keychain.retrievePassword", message: "Error \(status) Password retreival failed.")
            }
        }
                
        class func updatePassword(username: String, passwordOld: String, passwordNew: String, completion: @escaping (Bool, Error?) -> Void) {
            
            let serviceName = AppValues.appName
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
                LogEvent.print(module: "Authentication.keychain.updatePassword", message: "Password \"\(passwordOld)\"  changed to \"\(passwordNew)\" successfully")
                completion(true, result)
            } else {
                evaluateKeychainError(errorCode: error)
                LogEvent.print(module: "Authentication.keychain.updatePassword", message: "Error \(result)")
                completion(false, result)
            }
        }
        
        class func convertOSStatusToNSError(_ status: OSStatus) -> NSError {
            return NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }

        private class func evaluateKeychainError(errorCode: OSStatus) {
            LogEvent.print(module: "Authentication.evaluateKeychainError", message: "Error code: \(errorCode)")
            if let errorMessage = SecCopyErrorMessageString(errorCode, nil) {
                LogEvent.print(module: "Authentication.evaluateKeychainError", message: "Error message: \(errorMessage)")
            } else {
                LogEvent.print(module: "Authentication.evaluateKeychainError", message: "Unexpcted Error (\(errorCode))")
            }
        }
    }
    
    /// Firebase authentication
    ///
    class firebase {
        
        class func authUser(email: String, password: String, completion: @escaping (Bool, String, Error?) -> Void) {
            
            @AppStorage("firebaseUID") var firebaseUID: String = ""
            @AppStorage("password") var userPassword: String = ""
            
            Auth.auth().signIn(withEmail: email, password: password) {authResult, error in
                
                if let error = error {
                    
                    LogEvent.print(module: "Authentication.firebase.authUser", message: "Authorization failed.  user: \"\(email)\" \"\(password)\", error: \(error.localizedDescription)")

                    completion(false, "", error)
                    
                } else {
                    /// User was authorized
                    LogEvent.print(module: "Authentication.firebase.authUser", message: "Authorization was successful.  user: \"\(email)\", authResut = \(authResult?.user.uid ?? "")")
                    
                    /// Save results
                    firebaseUID = authResult?.user.uid ?? ""
                    userPassword = password
                    
                    completion(true, authResult?.user.uid ?? "", error)
                }
            }
        }

         
        class func addUser(email: String, password: String, completion: @escaping (Bool, String, Error?) -> Void) {
            Auth.auth().createUser(withEmail: email, password: password) {authResult, error in
                
                @AppStorage("firebaseUID") var firebaseUID: String = ""
                @AppStorage("password") var userPassword: String = ""
                
                if let error = error {
                    
                    LogEvent.print(module: "Authentication.firebase.addUser", message: "Adding user failed.  user: \"\(email)\", error: \(error.localizedDescription)")
                    completion(false, "", error)
                } else {
                    /// User was created
                    ///
                    LogEvent.print(module: "Authentication.firebase.addUser", message: "Adding user was successful.  user: \"\(email)\", authResut: = \(authResult?.user.uid ?? "")")

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
            
            // TODO:  Delete the user's data from the database (optional)
            // deletion code here...
            
            /// Delete the current user
            user.delete { error in
                if let error = error {
                    LogEvent.print(module: "Authentication.firebase.deleteUser", message: "Deleting user failed.  user: \"\(email)\", error: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    LogEvent.print(module: "Authentication.firebase.deleteUser", message: "Deleting user was successful.  user: \"\(email)\"")

                    completion(true, error)
                }
            }
        }
        
        class func passwordReset(email: String, completion: @escaping (Bool, Error?) -> Void) {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    /// Reset failed to send
                    LogEvent.print(module: "Authentication.firebase.passwordReset", message: "Password reset failed.  user: \"\(email)\", error: \(error.localizedDescription)")
                    completion(false, error)

                } else {
                    /// Reset was sent
                    LogEvent.print(module: "Authentication.firebase.passwordReset", message: "Password reset sent.  email: \"\(email)\"")
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
                    LogEvent.print(module: "Authentication.firebase.changeEmail", message: "Failed to send email verification. emailOld: \"\(emailOld)\" emailNew: \"\(emailNew)\"")
                    LogEvent.print(module: "Authentication.firebase.changeEmail", message: "This operation is sensitive and requires recent authentication. Log out then log in again before retrying this request.")
                    completion(false, error)
                } else {
                    /// Email verification sent, remind user to check their email
                    LogEvent.print(module: "Authentication.firebase.changeEmail", message: "Verification email sent. Please verify your new email: \"\(emailNew)\" before it is updated.")
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
                    LogEvent.print(module: "Authentication", message: "Email verification confirmed and updated successfully.")
                    // Optionally, notify the user within the app that their email has been updated successfully.
                } else {
                    // If the email isn't verified yet, prompt the user or handle accordingly
                    LogEvent.print(module: "Authentication", message: "Email verification not confirmed yet. Please check your email and verify.")
                }
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
                    LogEvent.print(module: "Authentication.firebase.changeReset", message: "Email change failed.  emailOld: \"\(emailOld)\" emailNew: \"\(emailOld)\"")
                    LogEvent.print(module: "Authentication.firebase.changeReset", message: "This operation is sensitive and requires recent authentication. Log out then log in again before retrying this request.")
                    completion(false, error)
                } else {
                    /// save the email address
                    userEmail = emailNew
                    LogEvent.print(module: "Authentication.firebase.changeEmail", message: "Email changed.  emailOld: \"\(emailOld)\" emailNew: \"\(emailOld)\"")
                    completion(true, error)
                }
            }

        }
         */
    }
}

