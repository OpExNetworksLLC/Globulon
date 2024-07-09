//
//  UserAccountView.swift
//  Globulon
//
//  Created by David Holeman on 7/7/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct UserAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var userSettings: UserSettings
    
    @State var firstname: String = UserSettings.init().firstname
    @State var lastname: String = UserSettings.init().lastname
    @State var email: String = UserSettings.init().email
    @State var phoneCell: String = UserSettings.init().phoneCell
    
    /// An entry to correspond to each field tag for sequenced entry
    @State var fieldFocus = [false, false]
    
    /// Phone number verification
    @State var isPhoneVerified: Bool = false
    @State var isPhoneVerifiedImage: String = "imgVerifyOff"
    @State var phoneNumber: String = ""
    @State var inputFormatMask = "+n (nnn) nnn-nnnn"

    /// email verification
    @State var isEmailVerified: Bool = false
    @State var isEmailVerifiedImage: String = "imgVerifyOff"
    @State var originalEmail: String = ""
    @State var isEmailChanged: Bool = false
    
    /// Retrieve password
    @State var passwordPrevious: String = ""

    @State var isChanged: Bool = false
    
    @State var isTermsAccepted: Bool = false
    @State var isLicenseReviewed: Bool = false
    @State var isPrivacyReviewed: Bool = false
    
    @State var showKeychainChangeEmailFailedAlert: Bool = false
    @State var showKeychainChangeEmailFailedMessage: String = ""
    
    @State var showFirebaseChangeEmailFailedAlert: Bool = false
    @State var showFirebaseChangeEmailFailedMessage: String = ""
    
    @State var showFirebaseChangeEmailSubmitAlert: Bool = false
    @State var showFirebaseChangeEmailSubmitMessage: String = ""
    @State var submitEmailChangeButtonCaption: String = "Submit"
    
    @State var showFirebaseChangeEmailSubmittedAlert: Bool = false
    @State var showFirebaseChangeEmailSubmittedMessage: String = ""

    enum InputField: Hashable {
        case firstName
        case lastName
    }
    @FocusState private var focusedField: InputField?


    var body: some View {
                
        NavigationView {
            HStack {

                VStack() {
                    /* start stuff within our area */
                    Form {
                        VStack(alignment: .leading) {
                            Text("Account Settings!")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                                .padding([.leading, .trailing], 16)
                                .padding(.bottom, 1)
                            Text("These are settings that define your account")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .padding([.leading, .trailing], 16)
                            Spacer()
                        }
                        .frame(width: AppValues.screen.width - 36, height: 120, alignment: .leading)
                        
                        Section(header: Text("name")) {

                            TextField("First name", text: $firstname)
                                .disableAutocorrection(true)
                                .foregroundColor(Color.primary)
                                .autocapitalization(.words)
                                .textContentType(.givenName)
                                .focused($focusedField, equals: .firstName)
                                .submitLabel(.next)
//                                .onSubmit {
//                                    focusedField = .lastName
//                                }
                                .onTapGesture {
                                    focusedField = .firstName
                                }
                            .onChange(of: firstname){
                                userSettings.firstname = firstname.trimmingCharacters(in: .whitespacesAndNewlines)
                            }

                            TextField("Last name", text: $lastname)
                                .disableAutocorrection(true)
                                .foregroundColor(Color.primary)
                                .autocapitalization(.words)
                                .textContentType(.familyName)
                                .focused($focusedField, equals: .lastName)
                                .submitLabel(.done)
//                                .onSubmit {
//                                    focusedField = nil
//                                }
                                .onTapGesture {
                                    focusedField = .lastName
                                }
                            .onChange(of: lastname) {
                                userSettings.lastname = lastname.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }
                        .foregroundColor(.secondary)
                        .offset(x: -8)
                        .padding(.trailing, -8)

                        
                        Section(header: Text("email")) {
                            //TextField("Email Address", text: $email).offset(x: -20)
                            
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
                                            //if email == "+1 (" {email = ""} // or "+011" or whatever precursor
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
                                        // check validity
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
                                            // save as it's valid
                                            userSettings.email = email
                                            if email != originalEmail {
                                                isEmailChanged = true
                                                submitEmailChangeButtonCaption = "Submit email change"
                                            } else {
                                                isEmailChanged = false
                                                submitEmailChangeButtonCaption = "Submit"
                                            }
                                        } else {
                                            isEmailVerified = false
                                            isChanged = false
                                            isEmailChanged = false
                                            submitEmailChangeButtonCaption = "Submit"
                                            }
                                        
                                        //if email != userSettings.email { isChanged = true }
                                        
                                        }
                                Image(isEmailVerifiedImage)
                                    .imageScale(.large)
                                    .frame(width: 32, height: 32, alignment: .center)
                                    .onChange(of: email) {
                                        isEmailVerified = isValidEmail(string: email)
                                        if isEmailVerified {isEmailVerifiedImage = "imgVerifyOn" } else { isEmailVerifiedImage = "imgVerifyOff" }
                                    }
                            }

                            if AppSettings.login.isKeychainLoginEnabled {
                                HStack {
                                    Button(action: {
                                        if AppSettings.login.isKeychainLoginEnabled {
                                            
                                            Authentication.keychain.changeUser(oldUsername: originalEmail, newUsername: email) { success, error in
                                                if success {
                                                    /// Save the new email address
                                                    userSettings.email = email
                                                } else {
                                                    showKeychainChangeEmailFailedMessage = error?.localizedDescription ?? ""
                                                    showKeychainChangeEmailFailedAlert = true
                                                }
                                            }
                                        }
                                    }) {
                                        if isEmailChanged {
                                            HStack {
                                                Spacer()
                                                Text("submit")
                                                    .frame(height: 30)
                                                    .padding(.leading, 8)
                                                    .padding(.trailing, 8)
                                                    .background(RoundedRectangle(cornerRadius: 5)
                                                        .stroke(Color.blue, lineWidth: 0.5))
                                            }
                                        } else {
                                            Text("n/a")
                                        }
                                    }
                                    Spacer()
                                }
                                .alert("Email change failed", isPresented: $showKeychainChangeEmailFailedAlert) {
                                    Button("Ok", role: .cancel) {
                                        showFirebaseChangeEmailSubmittedAlert = false
                                        email = originalEmail
                                        isEmailChanged = false
                                        
                                    }
                                } message: {
                                    Text(showKeychainChangeEmailFailedMessage)
                                }
                            }
                            
                            if AppSettings.login.isFirebaseLoginEnabled {
                                HStack {
                                    Button(action: {
                                        showFirebaseChangeEmailSubmitAlert = true
                                        showFirebaseChangeEmailSubmitMessage = ""
                                    }
                                    ) {
                                        Text(submitEmailChangeButtonCaption)
                                            .foregroundColor(isEmailChanged ? .blue : .gray)
                                    }
                                    .disabled(isEmailChanged ? false : true)

                                    Spacer()

                                }
                                .alert(isPresented: $showFirebaseChangeEmailSubmitAlert, content: {
                                    let firstButton = Alert.Button.default(Text("Cancel")) {
                                        /// Reset stuff
                                        email = originalEmail
                                        isEmailChanged = false
                                    }
                                    let secondButton = Alert.Button.destructive(Text("Continue")) {
                                        
                                        /// Submit the email change request
                                        ///
                                        print("** submitting firebase email change")
                                        
                                        /// TODO: remove this as firebase change will control this messaging
                                        ///
//                                        showFirebaseChangeEmailSubmittedAlert = true  // do this from the firebase change
//                                        showFirebaseChangeEmailSubmittedMessage = "submitted. check email"
//                                        print("** change submitted new: \(email) old:\(originalEmail)")
                                        
                                        if AppSettings.login.isFirebaseLoginEnabled {
                                            Authentication.firebase.changeUser(emailOld: originalEmail, emailNew: email) {
                                                success, error in
                                                if success {
                                                    showFirebaseChangeEmailSubmittedAlert = true
                                                    showFirebaseChangeEmailSubmittedMessage = "You must go to your email and confirm the change to the new email address by clicking the link in the email address.  The email will be from support@opexnetworks.com.  If you do not see the email please check your spam or junk folder."
                                                    submitEmailChangeButtonCaption = "Check email"
                                                    isEmailChanged = false
                                                    
                                                    //TODO: What if user does not confirm change.  Email is updated in the app so we'll have to test them changing that on login or (after biometric) and handle.  The disconnect here makes it sloppy for the user.  Grrr.
                                                    
                                                    //TODO: also if they have logged in via biometric then they are not actively logged into firebase so will need to test for that in change process.  More ugly. GRrr.
                                                    
                                                } else {
                                                    /// Handle failure to add user
                                                    ///
                                                    showFirebaseChangeEmailFailedMessage = error?.localizedDescription ?? ""
                                                    showFirebaseChangeEmailFailedAlert = true
                                                    email = originalEmail
                                                    isEmailChanged = false
                                                }
                                            }
                                        }
                                    }
                                    return Alert(title: Text("Warning!"), message: Text("Are you sure you want to change your email address?"), primaryButton: firstButton, secondaryButton: secondButton)
                                })
                                .alert("Email change submitted", isPresented: $showFirebaseChangeEmailSubmittedAlert) {
                                    Button("Ok", role: .cancel) {
                                        showFirebaseChangeEmailSubmittedAlert = false
                                        
                                        //TODO: other cleanup settings and alerts
                                        // isEmailChange= false
                                    }
                                } message: {
                                    Text(showFirebaseChangeEmailSubmittedMessage)
                                }
 
                            }
 
                            /// next item...
                            ///
                        }
                        .foregroundColor(.secondary)
                        .offset(x: -8)
                        .padding(.trailing, -24)
                        
                        Section(header: Text("phone")) {
                            HStack {
                                TextField(
                                    inputFormatMask,
                                    text: $phoneCell,
                                    onEditingChanged: {(editingChanged) in
                                        if phoneCell == "" { phoneCell = "+1 (" }
                                        if editingChanged {
                                            //get focus
                                        } else {
                                            //lose focus
                                        }
                                    })
                                    //.offset(x: -16)
                                    .keyboardType(.phonePad)
                                    .textContentType(.telephoneNumber)
                                    .onAppear {
                                        phoneCell = userSettings.phoneCell
                                        phoneCell = formattedNumber(number: phoneCell, mask: inputFormatMask, char: "n")
                                        // check validity
                                        if isValidPhoneNumber(testStr: phoneCell) {
                                            isPhoneVerified = true
                                        } else {
                                            isPhoneVerified = false
                                            }
                                    }
                                    .onChange(of: phoneCell) {
                                        // show formatted number on screen
                                        phoneCell = formattedNumber(number: phoneCell, mask: inputFormatMask, char: "n")
                                        // convert back to just number
                                        phoneNumber = unformattedNumber(number: phoneCell)
                                        // check validity
                                        if isValidPhoneNumber(testStr: phoneCell) {
                                            isPhoneVerified = true
                                            userSettings.phoneCell = phoneNumber
                                        } else {
                                            isPhoneVerified = false
                                            /// If the user clears the phone number clear in in settings.
                                            if phoneNumber == "" { userSettings.phoneCell = "" }
                                            }
                                        //if phoneCell != userSettings.phoneCell { isChanged = true }
                                        }
                                Image(isPhoneVerifiedImage)
                                    .imageScale(.large)
                                    .frame(width: 32, height: 32, alignment: .center)
                                    .onChange(of: phoneCell) {
                                        isPhoneVerified = isValidPhoneNumber(testStr: phoneCell)
                                        if isPhoneVerified {isPhoneVerifiedImage = "imgVerifyOn" } else { isPhoneVerifiedImage = "imgVerifyOff" }
                                    }
                                    .onChange(of: isPhoneVerified) {
                                        if isPhoneVerified {isPhoneVerifiedImage = "imgVerifyOn" } else { isPhoneVerifiedImage = "imgVerifyOff" }
                                    }
                            }
                        }
                        .foregroundColor(.secondary)
                        .offset(x: -8)
                        .padding(.trailing, -24)
                        
                        // Legal stuff
                        Section(header: Text("Legal")) {
                            NavigationLink(
                                destination: WebPageView(title: "Privacy Agreement",
                                subtitle: "Review the Privacy Agreement.",
                                webURL: AppValues.privacyURL,
                                isReviewed: $isPrivacyReviewed)
                                    .onAppear {
                                        isPrivacyReviewed = userSettings.isPrivacy
                                    }
                                    .onChange(of: isPrivacyReviewed) {
                                        userSettings.isPrivacy = isPrivacyReviewed
                                    }
                            ) {
                                HStack {
                                    Text("Privacy Agreement")
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            NavigationLink(
                                destination: WebPageView(title: "License Agreement",
                                subtitle: "Review the License Agreement.",
                                webURL: AppValues.licenseURL,
                                isReviewed: $isLicenseReviewed)
                                    .onAppear {
                                        isLicenseReviewed = userSettings.isLicensed
                                    }
                                    .onChange(of: isLicenseReviewed) {
                                        userSettings.isLicensed = isLicenseReviewed
                                    }
                            ) {
                                HStack {
                                    Text("License Agreement")
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            if AppSettings.isTermsEnabled {
                                NavigationLink(
                                    destination: IntroAcceptTermsView(title: "Terms & Conditions",
                                    subtitle: "User assumes all risk and responsibility.",
                                    webURL: AppValues.licenseURL,
                                    isAccepted: $isTermsAccepted
                                    )
                                    .onAppear {
                                        /// pass to
                                        isTermsAccepted = userSettings.isTerms
                                    }
                                        .onChange(of: isTermsAccepted) {
                                            /// receive from
                                            userSettings.isTerms = isTermsAccepted
                                            if isTermsAccepted == false {
                                                LogEvent.print(module: "UserAccountView", message: "User declined Terms")

                                                userSettings.isTerms = false
                                                /// TODO:  bail here if the user declines.   confirm they want to bail?  An alert pop up maybe
                                                DispatchQueue.main.asyncAfter(deadline: .now()) {
                                                    NotificationCenter.default.post(name: Notification.Name("isReset"), object: nil)
                                                }
                                                self.presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                ) {
                                    HStack {
                                        Text("Terms & Conditions")
                                            .foregroundColor(.primary)
                                    }
                            }
                            }
                        }
                        .foregroundColor(.secondary)
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        // end Legal Section

                    }
                    /// Shorten up the spacing between sections
                    .padding(.top, -16)
                    /// Addingthe clipped statement here keeps the scrolling below the nav bar and in the safe spaces
                    .clipped()
                    // end form

                    /* end stuff within our area */
                    Spacer()
                    /// This gap puts some separate between the keyboard and the scrolled field
                    Spacer().frame(height: 30)
                }
                .background(Color(UIColor.systemGroupedBackground))
                .listStyle(GroupedListStyle())
                .navigationBarTitle("Account")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    
                    /// Cancel
                    ///
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            saveSettings()
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            ImageNavCancel()
                        }
                    }
                    
                    /// Save/Done
                    ///
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            saveSettings()
//                            if showFirebaseChangeEmailFailedAlert == false {
//                                print("^\(showFirebaseChangeEmailFailedAlert)")
//                                self.presentationMode.wrappedValue.dismiss()
//                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(isChanged ? "Save" : "Done")
                                .foregroundColor(.blue)
                        }
                        .alert("Account Firebase Problem", isPresented: $showFirebaseChangeEmailFailedAlert) {
                            Button("Ok", role: .cancel) { }
                        } message: {
                            Text(showFirebaseChangeEmailFailedMessage)
                        }
                    }
                })
            }
        }
        .onAppear {
            /// Load up when the view appears so that if you make a change and come back while still in the setting menu the values are current.
            ///
            firstname = userSettings.firstname
            lastname = userSettings.lastname
            email = userSettings.email
            originalEmail = userSettings.email
            phoneCell = userSettings.phoneCell
            isChanged = false
        }
        .onSubmit {
            switch focusedField {
            case .firstName:
                focusedField = .lastName
            default:
                print("Creating account…")
            }
        }
        
    }
    
    func saveSettings() {
        
        /// Save if  number is changed, is valid and is not blank
        if phoneNumber != userSettings.phoneCell && isPhoneVerified { userSettings.phoneCell = phoneNumber }
        
        /// Save phone number if blank
        if phoneNumber == "" { userSettings.phoneCell = ""}
        
//                            if phoneNumber != userSettings.phoneCell {
//                                if isValidPhoneNumber(testStr: phoneNumber) {
//                                    userSettings.phoneCell = phoneNumber
//
//                                } else {
//                                    userSettings.phoneCell = "" }
//                            }
                
    } // end func

    
}

struct UserAccountView_Previews: PreviewProvider {
    static var previews: some View {
        UserAccountView()
            .environmentObject(UserSettings())
    }
}

