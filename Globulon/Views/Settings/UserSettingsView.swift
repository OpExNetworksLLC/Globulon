//
//  UserSettingsView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.2
 - Date: 2025.01.07
 - Note:
    - Version:  1.0.2 (2025.01.07)
        -  Embeded GDPRPolicyView inside PrivacyPolicyView which solved the flickering problem when in a form
    - Version:  1.0.1 (2025.01.06)
        - Subviews and presentation cleanup
    - Version:  1.0.0 (2025.01.06)
        - Added Analytics and Privacy options.
        - Reorganized into sub views
 */

import SwiftUI
#if FIREBASE_ENABLED
    import FirebaseAnalytics
#endif

struct UserSettingsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appStatus: AppStatus
    
    @State var isChanged: Bool = false
 
    var body: some View {
        
        NavigationView {
            HStack {
                VStack() {
                    Form {
                        
                        HeaderView()
                        BehaviorView()
                        SecurityView()
                        
                        #if FIREBASE_ENABLED
                            PrivacyView()
                        #endif
                        
                        /// Links to view the state of various SYSTEM settings
                        ///
                        SystemView()
                    }
                    
                    Spacer()
                    
                    Spacer().frame(height: 30)
                }
                .foregroundColor(.primary)
                .padding(.top, -16)
                .clipped()
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
                            
                            /// OPTION:  Add code here to effect changes if save is not real time with the option.
                            /// Do stuff...

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
            /// Set to false to start assuming all that's shown is current.
            isChanged = false
        }
    }
    
    //MARK: Sub Views
    struct HeaderView: View {
        var body: some View {
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
            .frame(width: UIScreen.main.bounds.width - 36, height: 120, alignment: .leading)
        }
    }
    struct BehaviorView: View {
        @State var isLandingPageIndex =  UserSettings.init().landingPage

        var body: some View {
            Section(header: Text("Behavior")
                .foregroundColor(.secondary)
            ) {
                
                /// Pick the default landing page the user would like the app to start on.
                Picker(selection: $isLandingPageIndex, label: Text("Landing page")
                    .foregroundColor(.primary)) {
                    ForEach(LandingPageEnum.allCases, id: \.self) { location in
                        Text(location.description)
                    }
                }
                .onChange(of: isLandingPageIndex) {
                    UserSettings.init().landingPage = isLandingPageIndex
                }
                
                // TODO: put code here to change any other behaviors of the app
                
            }
            .offset(x: -8)
            .padding(.trailing, -8)
        }
    }
    struct SecurityView: View {
        var body: some View {
            Section(header: Text("Security")
                .foregroundColor(.secondary)
            ) {
                NavigationLink(destination: UserSecurityView()) {
                    HStack {
                        Text("Security")
                            .foregroundColor(.primary)
                    }
                }
            }
            .offset(x: -8)
            .padding(.trailing, -8)
        }
    }
    struct PrivacyView: View {
        @State var isGDPRConsentGranted: Bool = false
        @State private var isShowGDPRPolicy: Bool = false
        
        var body: some View {
            Section(header: Text("Privacy")
                .foregroundColor(.secondary)
            ) {
                Toggle(isOn: self.$isGDPRConsentGranted) {
                    Text("Allow Analtyics Data Collection")
                        .foregroundColor(.primary)
                }
                .onAppear {
                    isGDPRConsentGranted = UserSettings.init().isGDPRConsentGranted
                }
                .onChange(of: isGDPRConsentGranted) {
                    UserSettings.init().isGDPRConsentGranted = isGDPRConsentGranted
                    Analytics.setAnalyticsCollectionEnabled(isGDPRConsentGranted)
                    LogEvent.print(module: "\(AppSettings.appName).init()", message: "firebase analytics enabled: \(UserSettings.init().isGDPRConsentGranted)")

                }
                /// NOTE:  Had to do some overlays to hide the chevron
                NavigationLink(destination: GDPRPolicyView()) {
                    /// NOTE:  Don't show anything here as we rely on the overlays
                }
                .overlay(
                    Rectangle()
                        .foregroundColor(Color(UIColor.secondarySystemGroupedBackground)) // Mask chevron
                        .allowsHitTesting(false) // Allows interaction with NavigationLink
                )
                .overlay(
                    HStack {
                        Spacer()
                        Text("More Details")
                            .foregroundColor(.blue)
                    }
                )
                
                /// NOTE:  Normal way to do this with chevron
                /*
                NavigationLink(destination: GDPRPolicyView()) {
                    HStack {
                        Spacer()
                        Text("More Details")
                            .foregroundColor(.blue)
                    }
                }
                .overlay(
                    Rectangle()
                        .foregroundColor(.clear) // Transparent overlay
                        .allowsHitTesting(false) // Allows interaction with NavigationLink
                )
                */
            }
            .offset(x: -8)
            .padding(.trailing, -8)
        }
        struct GDPRPolicyView: View {
            @Environment(\.colorScheme) var colorScheme
            var body: some View {
                VStack {
                    SwiftUIWebView(localHTMLFileName: AppSettings.analyticsConsentURL, url: nil)
                        .padding(8)
                        .border(colorScheme == .dark ? .white : .black)
                        .border(.gray)
                        .padding(8)
                    Spacer()
                }
            }
        }
    }
    struct SystemView: View {
        var body: some View {
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
        }
    }
}

#Preview {
    UserSettingsView()
}
