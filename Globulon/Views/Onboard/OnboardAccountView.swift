//
//  OnboardAccountView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct OnboardAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    
    //@ObservedObject var appStatus = AppStatus()
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
        
    @State var firstname: String = UserSettings.init().firstname
    @State var lastname: String = UserSettings.init().lastname
    
    /// An entry to correspond to each field tag for sequenced entry.  Set the field to true if you want it to become first responder
    @State var fieldFocus = [true, false]
    
    init() {
        UITableView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        HStack {
            
            Spacer().frame(width: 16)
            
            VStack(alignment: .leading) {
                
                Group {
                    Spacer().frame(height: 50)
                    HStack {
                        Button(action: {
                            //appStatus.currentOnboardPageView = .onboardTermsView  // go back a page
                            appStatus.currentOnboardPageView = .onboardStartView  // go back a page
                        }
                        ) {
                            HStack {
                                btnPreviousView()
                            }
                        }
                        Spacer()
                    } // end HStack
                    .padding(.bottom, 16)
                    
                    Text("Account")
                        .font(.system(size: 24))
                        .fontWeight(.regular)
                        .padding(.bottom, 16)
                    Text("These fields are optional but it's nice to know your name.")
                        .font(.system(size: 16))
                }

                Spacer().frame(height: 30)
                
                Group {
                    Text("FIRST NAME")
                        //.fontWeight(.light)
                        .font(.caption)
                    TextFieldEx (
                        label: "First name",
                        text: $firstname,
                        focusable: $fieldFocus,
                        returnKeyType: .next,
                        autocapitalizationType: .words,
                        textContentType: UITextContentType.givenName,
                        tag: 0
                    )
                    .frame(height:40)
                    .padding(.vertical, 0)
                    .overlay(Rectangle().frame(height: 0.5).padding(.top, 30))
                    
                    Spacer().frame(height: 30)
                    
                    Text("LAST NAME")
                        //.fontWeight(.light)
                        .font(.caption)
                    TextFieldEx (
                        label: "Last name",
                        text: $lastname,
                        focusable: $fieldFocus,
                        returnKeyType: .done,
                        autocapitalizationType: .words,
                        textContentType: UITextContentType.familyName,
                        tag: 1
                    )
                    .frame(height: 40)
                    .padding(.vertical, 0)
                    .overlay(Rectangle().frame(height: 0.5).padding(.top, 30))
                    
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        if firstname != userSettings.firstname { userSettings.firstname = firstname.trimmingCharacters(in: .whitespacesAndNewlines) }
                        if lastname != userSettings.lastname { userSettings.lastname = lastname.trimmingCharacters(in: .whitespacesAndNewlines) }
                        appStatus.currentOnboardPageView = .onboardEmailView
                    }
                    ) {
                        HStack {
                            Text("next")
                                .foregroundColor(Color("btnNextOnboarding"))
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Color("btnNextOnboarding"))
                                .cornerRadius(30)

                        }
                    }
                   
                } // end HStack
                Spacer().frame(height: 30)
            } // end VStack
            Spacer().frame(width: 16)
        } // end HStack
        .background(Color("viewBackgroundColorOnboarding"))
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            /// load up when the stack appears so that if you make a change and come back while still in the setting menu the values are current.
//            firstname = userSettings.firstname
//            lastname = userSettings.lastname
        }
        .onTapGesture { self.hideKeyboard() }
        
    } // end view
} // end struc_


struct OnboardAccountView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardAccountView()
            .environmentObject(AppStatus())
    }
}

