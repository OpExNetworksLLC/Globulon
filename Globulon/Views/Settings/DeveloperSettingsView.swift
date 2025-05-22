//
//  DeveloperSettingsView.swift
//  GeoGato
//
//  Created by David Holeman on 12/4/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//


import SwiftUI

/** #Version History
- Version: 1.0.1
- Date: 2025-01-23
- Note: - Added POI
 
- Version: 1.0.0
- Date: 12-04-2024
- Note: This version uses sub views for the various sections to take the pressure off the limited capacity of a Form
*/
struct DeveloperSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    HeaderView()
                    ModeSettingsView()
                    GPSDataView()
                    RegionSettingsView()
                    AppSettingsView()
                    ArticlesView()
                    SettingsView()
                    SystemView()
                }
                .padding(.top, -16)
                .clipped()
                
                /* end stuff within our area */
                Spacer()
                Spacer().frame(height: 30)
            }
            .foregroundColor(.primary)
            .background(Color(UIColor.systemGroupedBackground))
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Developer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                
                /// Cancel and exit the view
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        ImageNavCancel()
                    }
                }
                
                /// Save changed items
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Do something before dismissing the view (if needed)
                        
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                    }
                }
            })
            .onAppear {
                /// load up when the view appears so that if you make a change and come back while still in the setting menu the values are current.
//                mySettingsContent = mySettingsContent//DisplaySettings.user
            }
        }
    }
    
    struct HeaderView: View {
        var body: some View {
            VStack(alignment: .leading) {
                Text("Developer Settings!")
                    .font(.system(size: 24, weight: .bold))
                    .padding([.leading, .trailing], 16)
                    .padding(.bottom, 1)
                Text("These settings control the behavior of the app...")
                    .font(.system(size: 14))
                    .padding([.leading, .trailing], 16)
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width - 36, height: 120, alignment: .leading)
        }
    }

    struct ModeSettingsView: View {
        @EnvironmentObject var userSettings: UserSettings
        @State var userMode = UserModeEnum(rawValue: UserDefaults.standard.integer(forKey: "userMode")) ?? .development
        var body: some View {
            Section(header: Text("Mode").offset(x: -16)) {

                /// Articles location
                Picker(selection: $userMode, label: Text("User Mode").offset(x: -16 )) {
                    ForEach(UserModeEnum.allCases, id: \.self) { userMode in
                        Text(userMode.description)
                    }
                }
                .padding(.trailing, -8)
                .onChange(of: userMode) {
                    userSettings.userMode = userMode
                }
                
            }
            .offset(x: 8)
            .padding(.trailing, 8)
        }
    }
    
    struct GPSDataView: View {
        
        enum GPSSampleRateEnum: Int, CaseIterable, Equatable {
            
            case one   = 1
            case two   = 2
            case three = 3
            case four  = 4
            case five  = 5
            
            var id: Self { self }
            
            var description: String {
                //return String(self.rawValue)
                switch self {
                case .one   : return "1 sec"
                case .two   : return "2 sec"
                case .three : return "3 sec"
                case .four  : return "4 sec"
                case .five  : return "5 sec"
                }
            }
        }
        
        @EnvironmentObject var userSettings: UserSettings
        
        @State var gpsSampleRate = GPSSampleRateEnum(rawValue: UserDefaults.standard.integer(forKey: "gpsSampleRate")) ?? .five

        
        @State var showGPSDataPurgeAllConfirm: Bool = false
        @State var showGPSDataPurgeAllSuccess: Bool = false
        @State var showGPSDataPurgeAllMessage: String = ""
        
        var body: some View {
            
            Section(header: Text("GPS Data")) {
                VStack {
                    Button(action: {
                        showGPSDataPurgeAllConfirm = true
                    }
                    ) {
                        HStack {
                            Text("Purge All GPS data:").offset(x: -16)
                                .foregroundColor(.blue)
                            Text("\(countGPSDataAll())").offset(x: -16)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "minus.circle")
                                .imageScale(.large)
                        }
                        .padding(.trailing, -16)
                        
                        Picker(selection: $gpsSampleRate, label: Text("Sample every").offset(x: -16 ).foregroundColor(.primary)) {
                            ForEach(GPSSampleRateEnum.allCases, id: \.self) { rate in
                                Text(rate.description).tag(rate)
                            }
                        }
                        .onChange(of: gpsSampleRate) {
                            userSettings.gpsSampleRate = gpsSampleRate.rawValue
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.trailing, -8)
                    
                    }
                    .padding(.trailing, 8)
                    .alert("Warning!", isPresented: $showGPSDataPurgeAllConfirm) {
                        Button("Continue", role: .destructive) {
                            
                            let result = purgeGPSData()
                            showGPSDataPurgeAllMessage = "\(result) GPS Journal entries\n were purged"
                            showGPSDataPurgeAllSuccess = true
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to purge all \n\(countGPSDataAll()) GPS Journal entries?")
                    }
                    .alert("Purge Completed", isPresented: $showGPSDataPurgeAllSuccess) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(showGPSDataPurgeAllMessage)
                    }
                }
                .padding(.leading, 16)
            }
            .offset(x: -8)
            .padding(.trailing, -8)
        }
    }
    
    struct RegionSettingsView: View {
        
        enum RegionRadiusEnum: Double, CaseIterable, Equatable {
            case meters05 = 5
            case meters10 = 10
            case meters15 = 15
            case meters20 = 20
            case meters25 = 25
            case meters30 = 30
            
            var id: Self { self }
            var description: String {
                switch self {
                case .meters05: return "5 meters"
                case .meters10: return "10 meters"
                case .meters15: return "15 meters"
                case .meters20: return "20 meters"
                case .meters25: return "25 meters"
                case .meters30: return "30 meters"
                }
            }
        }
        
        @EnvironmentObject var userSettings: UserSettings
        
        @State var regionRadius = RegionRadiusEnum(rawValue: UserDefaults.standard.double(forKey: "regionRadius")) ?? .meters15
        
        @State var poiRadius = RegionRadiusEnum(rawValue: UserDefaults.standard.double(forKey: "poiRadius")) ?? .meters05
        
        var body: some View {
            Section(header: Text("Region").offset(x: -16)) {
                Picker(selection: $regionRadius, label: Text("Region radius").offset(x: -16 ).foregroundColor(.primary)) {
                    ForEach(RegionRadiusEnum.allCases, id: \.self) { distance in
                        Text(distance.description).tag(distance)
                    }
                }
                .onChange(of: regionRadius) {
                    userSettings.regionRadius = regionRadius.rawValue
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.trailing, -8)
                
                /// POI Radius
                Picker(selection: $poiRadius, label: Text("POI radius").offset(x: -16 ).foregroundColor(.primary)) {
                    ForEach(RegionRadiusEnum.allCases, id: \.self) { distance in
                        Text(distance.description).tag(distance)
                    }
                }
                .onChange(of: poiRadius) {
                    userSettings.poiRadius = poiRadius.rawValue
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.trailing, -8)
            }
            .offset(x: 8)
            .padding(.trailing, 8)
        }
    }
    
    struct AppSettingsView: View {
        
        @EnvironmentObject var userSettings: UserSettings
        
        @State var isIntroduced:    Bool = false
        @State var isPermissions:   Bool = false
        @State var isOnboarded:     Bool = false
        @State var isTerms:         Bool = false
        @State var isWelcomed:      Bool = false
        @State var isAccount:       Bool = false
        @State var isPrivacy:       Bool = false
        @State var isLicensed:      Bool = false
        @State var isGDPRConsent:   Bool = false
        
        var body: some View {
            Section(header: Text("APP Settings")) {
                
                /// Introduced
                Toggle(isOn: self.$isIntroduced) {
                    Text("Introduced")
                        .foregroundColor(.primary)
                }
                .onAppear {
                    isIntroduced = userSettings.isIntroduced
                }
                .onChange(of: isIntroduced) {
                    userSettings.isIntroduced = isIntroduced
                }
                .padding(.trailing, -8)
                
                /// Permissions
                ///
                Toggle(isOn: self.$isPermissions) {
                    Text("Permissions")
                        .foregroundColor(.primary)
                }
                .onAppear {
                    isPermissions = userSettings.isPermissions
                }
                .onChange(of: isPermissions) {
                    userSettings.isPermissions = isPermissions
                }
                .padding(.trailing, -8)
                
                /// Onboarded
                ///
                Toggle(isOn: self.$isOnboarded) {
                    Text("Onboarded")
                }
                .onAppear {
                    isOnboarded = userSettings.isOnboarded
                }
                .onChange(of: isOnboarded) {
                    userSettings.isOnboarded = isOnboarded
                }
                .padding(.trailing, -8)
                
                /// Terms
                ///
                Toggle(isOn: self.$isTerms) {
                    Text("Terms")
                }
                .onAppear {
                    isTerms = userSettings.isTerms
                }
                .onChange(of: isTerms) {
                    userSettings.isTerms = isTerms
                }
                .padding(.trailing, -8)
                
                /// Welcomed
                ///
                Toggle(isOn: self.$isWelcomed) {
                    Text("Welcomed")
                }
                .onAppear {
                    isWelcomed = userSettings.isWelcomed
                }
                .onChange(of: isWelcomed) {
                    userSettings.isWelcomed = isWelcomed
                }
                .padding(.trailing, -8)
                
                /// Account
                ///
                Toggle(isOn: self.$isAccount) {
                    Text("Account")
                }
                .onAppear {
                    isAccount = userSettings.isAccount
                }
                .onChange(of: isAccount) {
                    userSettings.isAccount = isAccount
                }
                .padding(.trailing, -8)
                
                /// Privacy
                Toggle(isOn: self.$isPrivacy) {
                    Text("Privacy")
                        .foregroundColor(.primary)
                }
                .onAppear {
                    isPrivacy = userSettings.isPrivacy
                }
                .onChange(of: isPrivacy) {
                    userSettings.isPrivacy = isPrivacy
                }
                .padding(.trailing, -8)
                
                /// License
                Toggle(isOn: self.$isLicensed) {
                    Text("License")
                }
                .onAppear {
                    isLicensed = userSettings.isLicensed
                }
                .onChange(of: isLicensed) {
                    userSettings.isLicensed = isLicensed
                }
                .padding(.trailing, -8)
                
                /// GDPR
                Toggle(isOn: self.$isGDPRConsent) {
                    Text("GDPR Consent")
                        .foregroundColor(.primary)
                }
                .onAppear {
                    isGDPRConsent = userSettings.isGDPRConsent
                }
                .onChange(of: isGDPRConsent) {
                    userSettings.isGDPRConsent = isGDPRConsent
                }
                .padding(.trailing, -8)
                
            }
            .offset(x: -8)
            .padding(.trailing, -8)
        }
    }
    
    struct ArticlesView: View {
        
        @EnvironmentObject var userSettings: UserSettings
        
        @State var articlesLocation = ArticleLocations(rawValue: UserDefaults.standard.integer(forKey: "articlesLocation")) ?? .local
        @State var showAlertDeleteAllArticles: Bool = false
        @State var showAlertLoadArticlesSuccess: Bool = false
        @State var showAlertLoadArticlesMessage: String = ""
        
        var body: some View {
            Section(header: Text("Articles").offset(x: -16)) {
                /// Delete all articles
                Button(action: {
                    showAlertDeleteAllArticles = true
                }
                ) {
                    HStack {
                        Text("Delete All Articles").offset(x: -16)
                        Spacer()
                        Image(systemName: "minus.circle")
                            .imageScale(.large)
                    }
                    .padding(.trailing, -16)
                }
                .alert(isPresented: $showAlertDeleteAllArticles, content: {
                    let firstButton = Alert.Button.default(Text("Cancel"))
                    let secondButton = Alert.Button.destructive(Text("Continue")) {
                        performDeleteAllArticles()
                        showAlertDeleteAllArticles = false
                    }
                    return Alert(title: Text("Warning!"), message: Text("Are you sure you want to delete All Articles?"), primaryButton: firstButton, secondaryButton: secondButton)
                })
                .padding(.trailing, 8)
                
                /// Articles location
                Picker(selection: $articlesLocation, label: Text("Location").offset(x: -16 )) {
                    ForEach(ArticleLocations.allCases, id: \.self) { location in
                        Text(location.description)
                    }
                }
                .padding(.trailing, -8)
                .onChange(of: articlesLocation) {
                    userSettings.articlesLocation = articlesLocation
                }
                
                /// Load articles
                Button(action: {
                    Task {
                        let (_, message) = await Articles.load()
                        DispatchQueue.main.async {
                            showAlertLoadArticlesMessage = message
                            showAlertLoadArticlesSuccess = true
                        }
                    }
                }

                ) {
                    HStack {
                        Text("Load Articles").offset(x: -16)
                        Spacer()
                        Image(systemName: "plus.circle")
                            .imageScale(.large)
                    }
                    .padding(.trailing, -16)
                }
                .alert(isPresented: $showAlertLoadArticlesSuccess) {
                    return Alert(title: Text("Load Articles"),
                        message: Text(showAlertLoadArticlesMessage),
                        dismissButton: .default(Text("OK")))
                }
                .padding(.trailing, 8)
                
            }
            .offset(x: 8)
            .padding(.trailing, 8)
            
            
        }
        func performDeleteAllArticles() {
            Articles.deleteArticles()
            userSettings.articlesDate = DateInfo.zeroDate
        }
    }
    
    struct SettingsView: View {
        @Environment(\.presentationMode) var presentationMode
        
        @State var showAlertDeleteAllSettings: Bool = false
        @State var showAlertDeleteUserSettings: Bool = false
        
        var body: some View {
            
            Section(header: Text("Settings").offset(x: -16)) {
                
                /// Delete All Settings Button
                Button(action: {
                    showAlertDeleteAllSettings = true
                }
                ) {
                    HStack {
                        Text("Delete All Settings").offset(x: -16)
                        Spacer()
                        Image(systemName: "minus.circle")
                            .imageScale(.large)
                    }
                    .padding(.trailing, -16)
                }
                .alert(isPresented: $showAlertDeleteAllSettings, content: {
                    let firstButton = Alert.Button.default(Text("Cancel"))
                    let secondButton = Alert.Button.destructive(Text("Continue")) {
                        performDeleteAllSettings()
                        showAlertDeleteAllSettings = false
                    }
                    return Alert(title: Text("Warning!"), message: Text("Are you sure you want to delete All Settings?"), primaryButton: firstButton, secondaryButton: secondButton)
                })
                .padding(.trailing, 8)
                
                
                /// Delete User Settings Button
                Button(action: {
                    showAlertDeleteUserSettings = true
                }
                ) {
                    HStack {
                        Text("Delete User Settings").offset(x: -16)
                        Spacer()
                        Image(systemName: "minus.circle")
                            .imageScale(.large)
                    }
                    .padding(.trailing, -16)
                }
                .alert(isPresented: $showAlertDeleteUserSettings, content: {
                    let firstButton = Alert.Button.default(Text("Cancel"))
                    let secondButton = Alert.Button.destructive(Text("Continue")) {
                        performDeleteUserSettings()
                        showAlertDeleteUserSettings = false
                    }
                    return Alert(title: Text("Warning!"), message: Text("Are you sure you want to delete your User Settings information?"), primaryButton: firstButton, secondaryButton: secondButton)
                })
                .padding(.trailing, 8)
                
            }
            .offset(x: 8)
            .padding(.trailing, 8)
            
        }
        func performDeleteUserSettings() {
            
            @EnvironmentObject var userSettings: UserSettings
      
            userSettings.firstname = ""
            userSettings.lastname = ""
            //userSettings.email = ""
            userSettings.avatar = AppDefaults.avatar
            userSettings.alias = ""
            userSettings.phoneCell = ""
            
            LogManager.event(module: "DeveloperSettingsView:peformDeleteUserSettings", message: "Deleting all user settings...")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: Notification.Name("isLoggedOut"), object: nil)
            }
            self.presentationMode.wrappedValue.dismiss()
        }
        
        func performDeleteAllSettings() {

            @EnvironmentObject var userSettings: UserSettings
            
            userSettings.firstname = ""
            userSettings.lastname = ""
            userSettings.email = ""
            userSettings.avatar = AppDefaults.avatar
            userSettings.alias = ""
            userSettings.phoneCell = ""
            
            userSettings.isOnboarded = false
            userSettings.isTerms = false
            userSettings.isWelcomed = false
            userSettings.isAccount = false
            userSettings.isPrivacy = false
            userSettings.isLicensed = false
            
            userSettings.articlesDate = DateInfo.zeroDate
            
            LogManager.event(module: "DeveloperSettingsView:peformDeleteAllSettings", message: "Deleting all settings...")

            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: Notification.Name("isReset"), object: nil)
            }
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    struct SystemView: View {
        
        var body: some View {
            
            Section(header: Text("System")) {
                NavigationLink(destination: SystemInfoView()) {
                    HStack {
                        Text("System Info")
                    }
                }
                NavigationLink(
                    destination: SettingsInfoView()) {
                        HStack {
                            Text("Review Settings")
                        }
                    }
            }
            .offset(x: -8)
            .padding(.trailing, -8)
        }
    }

}

#Preview {
    DeveloperSettingsView()
        .environmentObject(UserSettings())
}
