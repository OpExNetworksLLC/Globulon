//
//  UserSettingsView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct UserSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appStatus: AppStatus
    @EnvironmentObject var userSettings: UserSettings
    
//    @State var mySettingsContent: String = DisplaySettings.user
    
    @State var avatar: UIImage = UserSettings.init().avatar
    
    @State var isChanged: Bool = false
    @State var isLandingPageIndex =  UserSettings.init().landingPage
    var body: some View {
        
        NavigationView {
            HStack {
                VStack() {
                    /* start stuff within our area */
                   
                    Form {
                        
                        VStack(alignment: .leading) {
                            Text("User Settings!")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                                .padding([.leading, .trailing], 16)
                                .padding(.bottom, 1)

                            Text("These settings control the behavior of your app...")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .padding([.leading, .trailing], 16)
                            Spacer()
                        }
                        .frame(width: AppValues.screen.width - 36, height: 120, alignment: .leading)
                        //.padding(.bottom, 16)

                        /// Options for the user to change the BEHAVIOR of the app
                        ///
                        Section(header: Text("Behavior").offset(x: -16)) {
                            
                            /// Pick the default landing page the user would like the app to start on.
                            Picker(selection: $isLandingPageIndex, label: Text("Landing page").offset(x: -16 ).foregroundColor(.primary)) {
                                ForEach(LandingPageEnum.allCases, id: \.self) { location in
                                    Text(location.description)
                                }
                            }
                            .padding(.trailing, -8)
                            .onChange(of: isLandingPageIndex) {
                                UserSettings.init().landingPage = isLandingPageIndex
                            }
                            
                            // TODO: put code here to change any other behaviors of the app
                            
                        }
                        .foregroundColor(.secondary)
                        .offset(x: 8)
                        .padding(.trailing, 8)
                        // end Behavior
                        
                        /// Link for the user to change the SECURITY options of the app
                        ///
                        Section(header: Text("Security")) {
                            NavigationLink(destination: UserSecurityView()) {
                                HStack {
                                    Text("Security")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        // end Security Info
                        
                        /// Links to view the state of various SYSTEM settings
                        ///
                        Section(header: Text("System")) {
                            NavigationLink(destination: SystemInfoView()) {
                                HStack {
                                    Text("System info")
                                        .foregroundColor(.primary)
                                }
                            }
                            NavigationLink(
                                destination: SettingsInfoView()) {
                                    HStack {
                                        Text("Review Settings")
                                            .foregroundColor(.primary)
                                    }
                                }

                        }
                        .foregroundColor(.secondary)
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        // end System Info

                    }
                    
                    
                    /* end stuff within our area */
                    Spacer()
                    Spacer().frame(height: 30)
                }
                .padding(.top, -16)
                .clipped()
                // end form

                .background(Color(UIColor.systemGroupedBackground))
                .listStyle(GroupedListStyle())
                .navigationBarTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    /// Exit view
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            // TODO:  Reset anything that was changed before exit if that is the desired behavior
                            //
                            
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            ImageNavCancel()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        /// Save any changed settings (if isChanged is true) and then exit the view
                        Button(action: {
                            
                            // TODO:  Add code here to effect changes if save is not real time with the option.
                            //

                            self.presentationMode.wrappedValue.dismiss()

                        }) {
                            Text(isChanged ? "Save" : "Done")
                                .foregroundColor(.blue)
                        }
                    }
                })
            }
        }
        .onAppear {

            // TODO:  Show anyting here that we want to load up
            //
            
            /// Set to false to start assuming all that's shown is current.
            isChanged = false
        }
    }
}

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsView()
            .environmentObject(AppStatus())
            .environmentObject(UserSettings())
    }
}


