//
//  GDPRConsentView.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
#if FIREBASE_ENABLED
import FirebaseAnalytics
#endif

struct GDPRConsentView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var userSettings: UserSettings

    @State private var isGDPRConsentGiven: Bool = UserSettings.init().isGDPRConsentGranted
    @State private var initialGDPRConsent: Bool = UserSettings.init().isGDPRConsentGranted
    @State private var isShowPrivacyPolicy: Bool = false
    @State private var isShowGDPRPolicy: Bool = false
    @State private var isSavePreferencesEnabled: Bool = true // Initially enabled
    
    private var isNextButtonEnabled: Bool {
        !isSavePreferencesEnabled // Opposite of Save Preferences state
    }

    var body: some View {
        VStack() {
            Text("Data Privacy Consent")
                .font(.largeTitle)
                .bold()
                .padding(.top)
                .padding(.bottom, 16)
            
            Text("""
                 We value your privacy. We only collect anonymous data to help improve the app experience. 
                 """)
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)
            
            HStack {
                Text("""
                     Select your preferences: 
                     """)
                .multilineTextAlignment(.center)
                Spacer()
               
            }
            .padding(.bottom, 0)
            
            Toggle("Allow Analytics Data Collection", isOn: $isGDPRConsentGiven)
                .onChange(of: isGDPRConsentGiven) {
                    isSavePreferencesEnabled = (isGDPRConsentGiven != initialGDPRConsent) // Enable Save Preferences when toggle changes
                }
                .padding(.bottom, 24)
            
            HStack {
                Spacer()
                Button("More Details") {
                    isShowGDPRPolicy.toggle()
                }
                .sheet(isPresented: $isShowGDPRPolicy) {
                    NavigationView {
                        GDPRPolicyView()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: {
                                        isShowGDPRPolicy.toggle()
                                    }) {
                                        ImageNavCancel()
                                    }
                                }
                                ToolbarItem(placement: .principal) {
                                    Text("More Details")
                                }
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: {
                                        isShowGDPRPolicy.toggle()
                                    }, label: {
                                        TextNavCancel()
                                    })
                                }
                            }
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
            }
            .padding(.bottom, 48)
            
            Button(action: {
                saveConsentPreferences()
                isSavePreferencesEnabled = false // Disable Save Preferences after saving
            }) {
                Text("Save Preferences")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSavePreferencesEnabled ? Color.blue : Color.gray) // Blue if enabled, gray if disabled
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!isSavePreferencesEnabled) // Disable Save Preferences if no new changes
            .padding(.bottom, 32)
            
            Button("View Privacy Policy") {
                isShowPrivacyPolicy.toggle()
            }
            //.padding()
            .sheet(isPresented: $isShowPrivacyPolicy) {
                NavigationView {
                    PrivacyPolicyView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    isShowPrivacyPolicy.toggle()
                                }) {
                                    ImageNavCancel()
                                }
                            }
                            ToolbarItem(placement: .principal) {
                                Text("Privacy Policy")
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    isShowPrivacyPolicy.toggle()
                                }, label: {
                                    TextNavCancel()
                                })
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .onDisappear {
                            /// Set a flag to track the Privacy Policy has been viewed
                            userSettings.isPrivacy = true
                        }
                }
            }

            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("isGDPRConsent"), object: nil)
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text("Next")
                            .foregroundColor(isNextButtonEnabled ? .white : .gray)
                        Image(systemName: "arrow.right")
                            .resizable()
                            .foregroundColor(isNextButtonEnabled ? .white : .gray)
                            .frame(width: 30, height: 30)
                            .padding()
                            .background(isNextButtonEnabled ? Color("btnNextTracking") : Color(UIColor.systemGray5))
                            .cornerRadius(30)
                    }
                }
                .disabled(!isNextButtonEnabled) // Enable if Save Preferences is disabled
            }
        }
        .padding()
    }
    
    private func saveConsentPreferences() {
        if isGDPRConsentGiven {
            #if FIREBASE_ENABLED
            Analytics.setAnalyticsCollectionEnabled(true)
            #endif
            UserSettings.init().isGDPRConsentGranted = true
        } else {
            #if FIREBASE_ENABLED
            Analytics.setAnalyticsCollectionEnabled(false)
            #endif
            UserSettings.init().isGDPRConsentGranted = false
        }
        LogEvent.print(module: "GDPR ConsentView.saveConsentPreferences()", message: "firebase analytics enabled: \(UserSettings.init().isGDPRConsentGranted)")
    }
    
    struct GDPRPolicyView: View {
        var body: some View {
            @Environment(\.colorScheme) var colorScheme
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

    struct PrivacyPolicyView: View {
        @Environment(\.colorScheme) var colorScheme
        var body: some View {
            SwiftUIWebView(localHTMLFileName: nil, url: URL(string: AppSettings.privacyURL))
                .padding(8)
                .border(colorScheme == .dark ? .white : .black)
                .border(.gray)
                .padding(8)
        }
    }
}



#Preview {
    GDPRConsentView()
        .environmentObject(UserSettings())
}
