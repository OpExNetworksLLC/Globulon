//
//  OnboardEmailView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//
import SwiftUI

struct OnboardEmailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
    
    @State var email1: String = UserSettings.init().email
    @State var email2: String = UserSettings.init().email
    
    /// An entry to correspond to each field tag for sequenced entry.  Set the field to true if you want it to become first responder
    @State var fieldFocus = [true, false]
    
    /// email verification
    @State var isEmailVerified: Bool = false
    @State var isEmail1VerifiedImage: String = "imgVerifyOff"
    @State var isEmail2VerifiedImage: String = "imgVerifyOff"
    
    var body: some View {
        HStack {
            
            Spacer().frame(width: 16)
            
            VStack(alignment: .leading) {
                
                Group {
                    Spacer().frame(height: 50)
                    
                    HStack {
                        Button(action: {
                            // TODO:  Uncomment following statement to add back into full onboarding
                            appStatus.currentOnboardPageView = .onboardAccountView  // go back a page
                        }
                        ) {
                            HStack {
                                btnPreviousView()
                            }
                        }
                        Spacer()
                    } // end HStack
                    .padding(.bottom, 16)
                    // TODO:  Remove following .disabled and .hidden to add back into full onboarding
                    //.disabled(true)
                    //.hidden()
                    
                    
                    Text("Email")
                        .font(.system(size: 24))
                        .fontWeight(.regular)
                        .padding(.bottom, 16)
                    Text("Your email address is used to as your account ID.")
                        .font(.system(size: 16))
                }
                
                Spacer().frame(height: 30)
                
                Group {
                    Text("EMAIL ADDRESS")
                        .font(.caption)
                    
                    /*
                    HStack {
                        /// Email address
                        
                        TextFieldEx (
                            label: "email address",
                            text: $email1,
                            focusable: $fieldFocus,
                            returnKeyType: .done,
                            autocapitalizationType: Optional.none,
                            keyboardType: .emailAddress,
                            textContentType: UITextContentType.emailAddress,
                            tag: 0
                        )
                        .frame(height: 40)
                        .padding(.vertical, 0)
                        .overlay(Rectangle().frame(height: 0.5).padding(.top, 30))
                        .onChange(of: email1) {
                            // check for valid email format
                            
                            // force lowercase
                            email1 = email1.lowercased()
                            
                            //isEmailVerified = isValidEmail(string: email1)
                            if isValidEmail(string: email1) {isEmail1VerifiedImage = "imgVerifyOn" } else { isEmail1VerifiedImage = "imgVerifyOff" }
                        }
                        
                        Image(isEmail1VerifiedImage)
                            .imageScale(.large)
                            .frame(width: 32, height: 32, alignment: .center)
                        
                        
                    } // end HStack
                    */
                    
                    HStack {
                        TextField(
                            "Email address",
                            text: $email1,
                            onEditingChanged: {(editingChanged) in
                                if editingChanged {
                                    // check validity
                                    if isValidEmail(string: email1) {
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
                            
                            // force lowercase
                            email1 = email1.lowercased()
                            // check validity
                            if isValidEmail(string: email1) {
                                isEmailVerified = true
                            } else {
                                isEmailVerified = false
                            }
                        }
                        .onChange(of: email1) {
                            // check validity
                            if isValidEmail(string: email1) {
                                isEmailVerified = true
                            } else {
                                isEmailVerified = false
                            }
                            
                            //if email != userSettings.email { isChanged = true }
                            
                        }
                        Image(isEmail1VerifiedImage)
                            .imageScale(.large)
                            .frame(width: 32, height: 32, alignment: .center)
                            .onChange(of: email1) {
                                isEmailVerified = isValidEmail(string: email1)
                                if isEmailVerified {isEmail1VerifiedImage = "imgVerifyOn" } else { isEmail1VerifiedImage = "imgVerifyOff" }
                            }
                    }
                    .overlay(
                        Rectangle() // This creates the underline effect
                            .frame(height: 0.75)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.top, 35),
                        alignment: .bottomLeading
                    )
                    
                    Spacer().frame(height: 32)
                    
                    Text("REENTER EMAIL ADDRESS")
                        .font(.caption)
                    /*
                    HStack {
                        /// Email address
                        TextFieldEx (
                            label: "email address",
                            text: $email2,
                            focusable: $fieldFocus,
                            returnKeyType: .done,
                            autocapitalizationType: Optional.none,
                            keyboardType: .emailAddress,
                            textContentType: UITextContentType.emailAddress,
                            tag: 1
                        )
                        .frame(height: 40)
                        .padding(.vertical, 0)
                        .overlay(Rectangle().frame(height: 0.5).padding(.top, 30))
                        .onChange(of: email2) {
                            // force lowercase
                            email2 = email2.lowercased()
                            
                            if isValidEmail(string: email1) {isEmail2VerifiedImage = "imgVerifyOn" } else { isEmail2VerifiedImage = "imgVerifyOff" }
                        }
//                        .onSubmit {
//                            // Dismiss the keyboard when the "Done" button is pressed
//                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                        }
                        
                        Image(isEmail2VerifiedImage)
                            .imageScale(.large)
                            .frame(width: 32, height: 32, alignment: .center)
                            .onChange(of: email2) {
                                if email1 == email2 {
                                    isEmailVerified = true
                                } else {
                                    isEmailVerified = false
                                }
                            }
                    } // end HStack
                     */
                    
                    HStack {
                        TextField(
                            "Email address",
                            text: $email2,
                            onEditingChanged: {(editingChanged) in
                                if editingChanged {
                                    // check validity
                                    if isValidEmail(string: email2) {
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
                            
                            // force lowercase
                            email2 = email2.lowercased()
                            // check validity
                            if isValidEmail(string: email2) {
                                isEmailVerified = true
                            } else {
                                isEmailVerified = false
                            }
                        }
                        .onChange(of: email2) {
                            // check validity
                            if isValidEmail(string: email2) {
                                isEmailVerified = true
                            } else {
                                isEmailVerified = false
                            }
                            
                            //if email != userSettings.email { isChanged = true }
                            
                        }
                        Image(isEmail1VerifiedImage)
                            .imageScale(.large)
                            .frame(width: 32, height: 32, alignment: .center)
                            .onChange(of: email2) {
                                isEmailVerified = isValidEmail(string: email2)
                                if isEmailVerified {isEmail2VerifiedImage = "imgVerifyOn" } else { isEmail2VerifiedImage = "imgVerifyOff" }
                            }
                    }
                    .overlay(
                        Rectangle() // This creates the underline effect
                            .frame(height: 0.75)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.top, 35),
                        alignment: .bottomLeading
                    )
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        if email2 != userSettings.email && isEmailVerified && email1 == email2 {
                            userSettings.email = email2.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        appStatus.currentOnboardPageView = .onboardPasswordView
                    }
                    ) {
                        HStack {
                            Text("next")
                                .foregroundColor(isEmailVerified ? Color("btnNextOnboarding") : .gray)
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(isEmailVerified ? .white : .white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(isEmailVerified ? Color("btnNextOnboarding") : Color(UIColor.systemGray5))
                                .cornerRadius(30)
                        }
                    }
                    .disabled(isEmailVerified ? false : true)
                } // end HStack
                Spacer().frame(height: 30)
            } // end VStack
            Spacer().frame(width: 16)
        } // end HStack
        .background(Color("viewBackgroundColorOnboarding"))
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            // If we have valid emails and they are not blank then enable the next button so the user can move forward without having to retrigger validation if no change is made.
            if email1 != "" || email2 != "" {
                if isValidEmail(string: email1) == isValidEmail(string: email2) {
                    isEmailVerified = true
                }
            }
        }
        .onTapGesture { self.hideKeyboard() }
        
    } // end view
} // end struc_


struct OnboardEmailView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardEmailView()
            .environmentObject(AppStatus())
            .environmentObject(UserSettings())
    }
}

