//
//  DeveloperSettingsView.swift
//  Globulon
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

/// # DeveloperSettingsView
/// Display current trips
///
/// # Version History
/// ### 0.1.0.62
/// # - update deleteGpsJournalSD to return and handle count in alert messages
/// # - update deleteTripSummariesSD to return and handle count in alert messages
/// # - *Date*: 07/13/24

struct DeveloperSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var userSettings: UserSettings
   
    @State var isIntroduced: Bool = false
    @State var isTracking: Bool = false
    @State var isOnboarded: Bool = false
    @State var isTerms: Bool = false
    @State var isWelcomed: Bool = false
    @State var isAccount: Bool = false
    @State var isPrivacy: Bool = false
    @State var isLicensed: Bool = false

    @State var isTripReprocessingAllowed: Bool = false

    @State var showAlertDeleteAllArticles: Bool = false
    @State var showAlertDeleteAllSettings: Bool = false
    @State var showAlertDeleteUserSettings: Bool = false
    @State var showAlertLoadArticlesSuccess: Bool = false
    @State var showAlertLoadArticlesMessage: String = ""
    
    @State var showAlertDeleteAllGPSDataConfirm: Bool = false
    @State var showAlertDeleteAllGPSDataSuccess: Bool = false
    @State var showAlertDeleteAllGPSDataMessage: String = ""

    @State var showAlertDeleteAllTripsConfirm: Bool = false
    @State var showAlertDeleteAllTripsSuccess: Bool = false
    @State var showAlertDeleteAllTripsMessage: String = ""
    
    @State var showAlertDeleteAllProcessedGPSDataConfirm: Bool = false
    @State var showAlertDeleteAllProcessedGPSDataSuccess: Bool = false
    @State var showAlertDeleteAllProcessedGPSDataMessage: String = ""

    @State var showAlertDedupSuccess: Bool = false
    @State var showAlertDedupMessage: String = ""
    
    @State var showAlertDeprocessSuccess: Bool = false
    @State var showAlertDeprocessMessage: String = ""

    @State var showAlertTripPurgeLimitConfirm: Bool = false
    @State var showAlertTripPurgeLimitSuccess: Bool = false
    @State var showAlertTripPurgeLimitMessage: String = ""
    
    @State var showAlertGPSDeleteTripLimitConfirm: Bool = false
    @State var showAlertGPSDeleteTripLimitSuccess: Bool = false
    @State var showAlertGPSDeleteTripLimitMessage: String = ""
    
    @State var showAlertDeleteJournalSDConfirm: Bool = false
    @State var showAlertDeleteJournalSDSuccess: Bool = false
    @State var showAlertDeleteJournalSDMessage: String = ""
    
    @State var showAlertLoadSampleGPSDataSuccess: Bool = false
    @State var showAlertLoadSampleGPSDataMessage: String = ""

    @State var trackingTripSeparator = UserSettings.init().trackingTripSeparator
    @State var trackingTripEntriesMin = UserSettings.init().trackingTripEntriesMin
    @State var trackingSampleRate = TrackingSampleRateEnum(rawValue: UserDefaults.standard.integer( forKey: "trackingSampleRate")) ?? .five
    @State var trackingSpeedThreshold = TrackingSpeedThresholdEnum(rawValue: UserDefaults.standard.double( forKey: "trackingSpeedThreshold")) ?? .mph05
    
    @State var tripGPSHistoryLimit = UserSettings.init().tripGPSHistoryLimit
    @State var tripHistoryLimit = UserSettings.init().tripHistoryLimit

    @State var articlesLocation = ArticleLocations(rawValue: UserDefaults.standard.integer(forKey: "articlesLocation")) ?? .local
    @State var userMode = UserModeEnum(rawValue: UserDefaults.standard.integer(forKey: "userMode")) ?? .development
    
    init() {
        // Do stuff if needed
    }
    
    var body: some View {
        
        NavigationView {
            VStack {
                /* start stuff within our area */
                Form {
                    VStack(alignment: .leading) {
                        Text("Developer Settings!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .padding([.leading, .trailing], 16)
                            .padding(.bottom, 1)
                        Text("These settings control the behavior of the app...")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .padding([.leading, .trailing], 16)
                        Spacer()
                    }
                    .frame(width: AppValues.screen.width - 36, height: 120, alignment: .leading)
                    
                    /// APP SETTINGS
                    ///
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
                        
                        Toggle(isOn: self.$isTracking) {
                            Text("Tracking")
                                .foregroundColor(.primary)
                        }
                        .onAppear {
                            isTracking = userSettings.isTracking
                        }
                        .onChange(of: isTracking) {
                            userSettings.isTracking = isTracking
                        }
                        .padding(.trailing, -8)
                        
                        Toggle(isOn: self.$isOnboarded) {
                            Text("Onboarded")
                                .foregroundColor(.primary)
                        }
                        .onAppear {
                            isOnboarded = userSettings.isOnboarded
                        }
                        .onChange(of: isOnboarded) {
                            userSettings.isOnboarded = isOnboarded
                        }
                        .padding(.trailing, -8)
                        
                        Toggle(isOn: self.$isTerms) {
                            Text("Terms")
                                .foregroundColor(.primary)
                        }
                        .onAppear {
                            isTerms = userSettings.isTerms
                        }
                        .onChange(of: isTerms) {
                            userSettings.isTerms = isTerms
                        }
                        .padding(.trailing, -8)
                        
                        Toggle(isOn: self.$isWelcomed) {
                            Text("Welcomed")
                                .foregroundColor(.primary)
                        }
                        .onAppear {
                            isWelcomed = userSettings.isWelcomed
                        }
                        .onChange(of: isWelcomed) {
                            userSettings.isWelcomed = isWelcomed
                        }
                        .padding(.trailing, -8)
                        
                        Toggle(isOn: self.$isAccount) {
                            Text("Account")
                                .foregroundColor(.primary)
                        }
                        .onAppear {
                            isAccount = userSettings.isAccount
                        }
                        .onChange(of: isAccount) {
                            userSettings.isAccount = isAccount
                        }
                        .padding(.trailing, -8)
                        
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
                        
                        Toggle(isOn: self.$isLicensed) {
                            Text("License")
                                .foregroundColor(.primary)
                        }
                        .onAppear {
                            isLicensed = userSettings.isLicensed
                        }
                        .onChange(of: isLicensed) {
                            userSettings.isLicensed = isLicensed
                        }
                        .padding(.trailing, -8)
                        
                    }
                    .foregroundColor(.secondary)
                    .offset(x: -8)
                    .padding(.trailing, -8)
                    // end form
                    
                    /// SCORING:
                    ///
                    Section(header: Text("Scoring").offset(x: -16)) {
                        
                        Picker(selection: $trackingSampleRate, label: Text("Sample every").offset(x: -16 ).foregroundColor(.primary)) {
                            ForEach(TrackingSampleRateEnum.allCases, id: \.self) { rate in
                                Text(rate.description).tag(rate)
                            }
                        }
                        .onChange(of: trackingSampleRate) {                            UserSettings.init().trackingSampleRate = trackingSampleRate.rawValue
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.trailing, -8)
                        
                        Stepper(
                            value: $trackingTripEntriesMin,
                            in: 1...25,
                            step: 1) {
                                Text("Min samples per trip: ").foregroundColor(.primary) + Text("\(trackingTripEntriesMin)").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            }
                            .onChange(of: trackingTripEntriesMin) {
                                userSettings.trackingTripEntriesMin = trackingTripEntriesMin
                            }
                            .foregroundColor(.primary)
                            .padding(.leading, -16)
                            .padding(.trailing, -8)
                                                
                        Stepper(
                            value: $trackingTripSeparator,
                            in: 30...360,
                            step: 30) {
                                Text("Trip separator seconds: ").foregroundColor(.primary) + Text("\(trackingTripSeparator)").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            }
                            .onChange(of: trackingTripSeparator) {
                                userSettings.trackingTripSeparator = trackingTripSeparator
                            }
                            .foregroundColor(.primary)
                            .padding(.leading, -16)
                            .padding(.trailing, -8)
                        

                        Picker(selection: $trackingSpeedThreshold, label: Text("Minium tracking speed").offset(x: -16 ).foregroundColor(.primary)) {
                            ForEach(TrackingSpeedThresholdEnum.allCases, id: \.self) { rate in
                                Text(rate.description).tag(rate)
                            }
                        }
                        .onChange(of: trackingSampleRate) {                            UserSettings.init().trackingSpeedThreshold = trackingSpeedThreshold.rawValue
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.trailing, -8)

                    }
                    .foregroundColor(.secondary)
                    .offset(x: 8)
                    .padding(.trailing, 8)
                    
                    /// TRIP DATA:
                    ///
                    Section(header: Text("Trip Data").offset(x: -16)) {
                        
                        /// Export all GPS data
                        ///
                        VStack {
                            Button(action: {
                                /// Peform the export
                                ///
                                _  = exportAllGPSData()
                            }
                            ) {
                                HStack {
                                    Text("Export all GPS data").offset(x: -16)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "minus.circle")
                                        .imageScale(.large)
                                }
                                .padding(.trailing, -16)
                            }
                        .padding(.trailing, 8)
                        }
                        
                        /// Dellete all trips
                        ///
                        VStack {
                            Button(action: {
                                showAlertDeleteAllTripsConfirm = true
                            }
                            ) {
                                HStack {
                                    Text("Delete all trips").offset(x: -16)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "minus.circle")
                                        .imageScale(.large)
                                }
                                .padding(.trailing, -16)
                            }
                            .padding(.trailing, 8)
                            .alert("Warning!", isPresented: $showAlertDeleteAllTripsConfirm) {
                                Button("Continue", role: .destructive) {
                                    let result = deleteTripSummariesSD()
                                    showAlertDeleteAllTripsMessage = "\(result) trips were deleted"
                                    showAlertDeleteAllTripsSuccess = true
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("Are you sure you want to delete all trips?")
                            }
                            .alert("Delete Completed", isPresented: $showAlertDeleteAllTripsSuccess) {
                                Button("OK", role: .cancel) {}
                            } message: {
                                Text(showAlertDeleteAllTripsMessage)
                            }
                        }
                        
                        
                        
                        /// Dedup GPS Data
                        Button(action: {
                            let result = dedupGpsJournalSD()
                            showAlertDedupSuccess = true
                            showAlertDedupMessage = "Removed \(result) duplicates from GPS data"

                        }) {
                            HStack {
                                Text("Dedup GPS Data").offset(x: -16)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "minus.circle")
                                    .imageScale(.large)
                            }
                            .padding(.trailing, -16)
                        }
                        .alert(isPresented: $showAlertDedupSuccess) {
                            return Alert(title: Text("Dedup GPS data"),
                                message: Text(showAlertDedupMessage),
                                dismissButton: .default(Text("OK")))
                        }
                        .padding(.trailing, 8)
                        
                        /// Deprocess GPS Data
                        ///
                        Button(action: {
                            let result = deprocessGpsJournalSD()
                            showAlertDeprocessSuccess = true
                            showAlertDeprocessMessage = "Deprocessed \(result) GPS data entries"

                        }) {
                            HStack {
                                Text("Deprocess GPS data").offset(x: -16)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "minus.circle")
                                    .imageScale(.large)
                            }
                            .padding(.trailing, -16)
                        }
                        .alert(isPresented: $showAlertDeprocessSuccess) {
                            return Alert(title: Text("Deprocess GPS data"),
                                message: Text(showAlertDeprocessMessage),
                                dismissButton: .default(Text("OK")))
                        }
                        .padding(.trailing, 8)
                        
                        /// Delete all GPS Data
                        ///
                        Button(action: {
                            showAlertDeleteAllGPSDataConfirm = true
                        }
                        ) {
                            HStack {
                                Text("Delete All GPS data").offset(x: -16)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "minus.circle")
                                    .imageScale(.large)
                            }
                            .padding(.trailing, -16)
                        }
                        .padding(.trailing, 8)
                        /*
                        .alert(isPresented: $showAlertDeleteAllGPSData, content: {
                            let firstButton = Alert.Button.default(Text("Cancel"))
                            let secondButton = Alert.Button.destructive(Text("Continue")) {
                                
                                //TODO: Delete the GPS data here...
                                //
                                deleteGpsJournalSD()
                                showAlertDeleteAllGPSData = false
                            }
                            return Alert(title: Text("Warning!"), message: Text("Are you sure you want to delete All GPS Data?"), primaryButton: firstButton, secondaryButton: secondButton)
                        })
                        .padding(.trailing, 8)
                        */
                        .alert("Warning!", isPresented: $showAlertDeleteAllGPSDataConfirm) {
                            Button("Continue", role: .destructive) {
                            
                                let result = deleteGpsJournalSD()
                                showAlertDeleteAllGPSDataMessage = "\(result) GPS Journal entries\n were deleted"
                                showAlertDeleteAllGPSDataSuccess = true
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Are you sure you want to delete all processed GPS Journal entries?")
                        }
                        .alert("Delete Completed", isPresented: $showAlertDeleteAllGPSDataSuccess) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text(showAlertDeleteAllGPSDataMessage)
                        }
                        
                        
                        /// Delete all processed GPS Data
                        ///
                        Button(action: {
                            showAlertDeleteAllProcessedGPSDataConfirm = true
                        }
                        ) {
                            HStack {
                                Text("Delete All processed GPS data").offset(x: -16)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "minus.circle")
                                    .imageScale(.large)
                            }
                            .padding(.trailing, -16)
                        }
                        .padding(.trailing, 8)
                        .alert("Warning!", isPresented: $showAlertDeleteAllProcessedGPSDataConfirm) {
                            Button("Continue", role: .destructive) {
                                // TODO: create delete function
                                let result = deleteAllProcessedGPSJournalSD()
                                showAlertDeleteAllProcessedGPSDataMessage = "\(result) processed GPS Journal entries\n were deleted"
                                showAlertDeleteAllProcessedGPSDataSuccess = true
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Are you sure you want to delete all processed GPS Journal entries?")
                        }
                        .alert("Delete Completed", isPresented: $showAlertDeleteAllProcessedGPSDataSuccess) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text(showAlertDeleteAllProcessedGPSDataMessage)
                        }
                        
                        /// GPS History Trip Limit
                        ///
                        Stepper(
                            value: $tripGPSHistoryLimit,
                            in: 5...100,
                            step: 5) {
                                Text("GPS Trip history limit: ").foregroundColor(.primary) + Text("\(tripGPSHistoryLimit)").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            }
                            .onChange(of: tripGPSHistoryLimit) {
                                userSettings.tripGPSHistoryLimit = tripGPSHistoryLimit
                            }
                        .foregroundColor(.primary)
                        .padding(.leading, -16)
                        .padding(.trailing, -8)
                        
                        /// Purge GPS history to limit
                        ///
                        Button(action: {
                            showAlertGPSDeleteTripLimitConfirm = true
                        }
                        ) {
                            HStack {
                                Text("Purge to GPS Trip history limit").offset(x: -16)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "minus.circle")
                                    .imageScale(.large)
                            }
                            .padding(.trailing, -16)
                        }
                        .padding(.trailing, 8)
                        .alert("Warning!", isPresented: $showAlertGPSDeleteTripLimitConfirm) {
                            Button("Continue", role: .destructive) {
                                let limit = UserSettings.init().tripGPSHistoryLimit
                                let result = purgeGPSJournalSDbyCount(tripLimit: limit)
                                showAlertGPSDeleteTripLimitMessage = "\(result) GPS trips were purged"
                                showAlertGPSDeleteTripLimitSuccess = true
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Are you sure you want to purge to the GPS trip history limit of \(UserSettings.init().tripGPSHistoryLimit) trips?")
                        }
                        .alert("Purge Completed", isPresented: $showAlertGPSDeleteTripLimitSuccess) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text(showAlertGPSDeleteTripLimitMessage)
                        }

                        /// Trip history limit
                        ///
                        Stepper(
                            value: $tripHistoryLimit,
                            in: 5...100,
                            step: 5) {
                                Text("Trip history limit: ").foregroundColor(.primary) + Text("\(tripHistoryLimit)").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            }
                            .onChange(of: tripHistoryLimit) {
                                userSettings.tripHistoryLimit = tripHistoryLimit
                            }
                        .foregroundColor(.primary)
                        .padding(.leading, -16)
                        .padding(.trailing, -8)
                        
                        
                        /// Purge to trip limit
                        ///
                        Button(action: {
                            showAlertTripPurgeLimitConfirm = true
                        }
                        ) {
                            HStack {
                                Text("Purge to Trip history limit").offset(x: -16)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "minus.circle")
                                    .imageScale(.large)
                            }
                            .padding(.trailing, -16)
                        }
                        .padding(.trailing, 8)
                        .alert("Warning!", isPresented: $showAlertTripPurgeLimitConfirm) {
                            Button("Continue", role: .destructive) {
                                let limit = UserSettings.init().tripHistoryLimit
                                let result = purgeTripSummariesSDbyCount(tripLimit: limit)
                                showAlertTripPurgeLimitMessage = "\(result) trips were purged"
                                showAlertTripPurgeLimitSuccess = true
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Are you sure you want to purge to the trip history limit of \(UserSettings.init().tripHistoryLimit) trips?")
                        }
                        .alert("Purge Completed", isPresented: $showAlertTripPurgeLimitSuccess) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text(showAlertTripPurgeLimitMessage)
                        }

                        ///  Load sample trips
                        ///
                        Button(action: {
                            showAlertLoadSampleGPSDataSuccess = true
                        }
                        ) {
                            HStack {
                                Text("Load sample GPS data").offset(x: -16)
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .imageScale(.large)
                            }
                            .padding(.trailing, -16)
                        }
                        .alert(isPresented: $showAlertLoadSampleGPSDataSuccess, content: {
                            let firstButton = Alert.Button.default(Text("Cancel"))
                            let secondButton = Alert.Button.destructive(Text("Continue")) {
                                
                                /// Start Load sample trips
                                ///
                                _ = loadSampleTripFromAssets(file: "SampleTrip01")
                                _ = loadSampleTripFromAssets(file: "SampleTrip02")
                                _ = loadSampleTripFromAssets(file: "SampleTrip03")
                                _ = loadSampleTripFromAssets(file: "SampleTrip04")
                                _ = loadSampleTripFromAssets(file: "SampleTrip05")


                                /// ... end Load sample trips

                            }
                            return Alert(title: Text("Warning!"), message: Text("Are you sure you add sample GPS data?"), primaryButton: firstButton, secondaryButton: secondButton)
                        })
                        .padding(.trailing, 8)
                        
                        /// Trip reprocessing
                        Toggle(isOn: self.$isTripReprocessingAllowed) {
                            Text("Trip reprocessing allowed")
                                .foregroundColor(.primary)
                        }
                        .onAppear {
                            isTripReprocessingAllowed = userSettings.isTripReprocessingAllowed
                        }
                        .onChange(of: isTripReprocessingAllowed) {
                            userSettings.isTripReprocessingAllowed = isTripReprocessingAllowed
                        }
                        .foregroundColor(.secondary)
                        .offset(x: -16)
                        .padding(.trailing, -24)
                    }
                    .foregroundColor(.secondary)
                    .offset(x: 8)
                    .padding(.trailing, 8)

                    
                    
                    /// ARTICLES"
                    ///
                    Section(header: Text("Articles").offset(x: -16)) {
                        /// Delete all articles
                        Button(action: {
                            showAlertDeleteAllArticles = true
                        }
                        ) {
                            HStack {
                                Text("Delete all articles").offset(x: -16)
                                    .foregroundColor(.blue)
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
                        Picker(selection: $articlesLocation, label: Text("Location").offset(x: -16 ).foregroundColor(.primary)) {
                            ForEach(ArticleLocations.allCases, id: \.self) { location in
                                Text(location.description)
                            }
                        }
                        .padding(.trailing, -8)
                        .onChange(of: articlesLocation) {
                            UserSettings.init().articlesLocation = articlesLocation
                        }
                        
                        /// Load articles
                        Button(action: {
                            //TODO: replace with production load
                            Articles.load { success, message in
                                showAlertLoadArticlesMessage = message
                                showAlertLoadArticlesSuccess = true
                            }
                        }
                        ) {
                            HStack {
                                Text("Load articles").offset(x: -16)
                                    .foregroundColor(.blue)
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
                    .foregroundColor(.secondary)
                    .offset(x: 8)
                    .padding(.trailing, 8)
                    
                    // Mode
                    Section(header: Text("Mode").offset(x: -16)) {

                        
                        /// User mode
                        Picker(selection: $userMode, label: Text("User mode").offset(x: -16 ).foregroundColor(.primary)) {
                            ForEach(UserModeEnum.allCases, id: \.self) { userMode in
                                Text(userMode.description)
                            }
                        }
                        .padding(.trailing, -8)
                        .onChange(of: userMode) {
                            UserSettings.init().userMode = userMode
                        }
                        
                    }
                    .foregroundColor(.secondary)
                    .offset(x: 8)
                    .padding(.trailing, 8)
                    
                    Section(header: Text("Settings").offset(x: -16)) {
                        
                        /// Delete All Settings Button
                        Button(action: {
                            showAlertDeleteAllSettings = true
                        }
                        ) {
                            HStack {
                                Text("Delete all settings").offset(x: -16)
                                    .foregroundColor(.blue)
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
                                Text("Delete user settings").offset(x: -16)
                                    .foregroundColor(.blue)
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
                    .foregroundColor(.secondary)
                    .offset(x: 8)
                    .padding(.trailing, 8)

                    
                    // Start System Info
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
                                    Text("Review settings")
                                        .foregroundColor(.primary)
                                }
                            }
                    }
                    .foregroundColor(.secondary)
                    .offset(x: -8)
                    .padding(.trailing, -8)
                    // end System Info
                    
                }
                .padding(.top, -16)
                .clipped()
                // end form
                
                /* end stuff within our area */
                Spacer()
                Spacer().frame(height: 30)
            }
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
                            .foregroundColor(.blue)
                    }
                }
            })
            .onAppear {
                /// load up when the view appears so that if you make a change and come back while still in the setting menu the values are current.
//                mySettingsContent = mySettingsContent//DisplaySettings.user
            }
        }
    }
    
    func performDeleteUserSettings() {
  
        userSettings.firstname = ""
        userSettings.lastname = ""
        userSettings.email = ""
        userSettings.avatar = AppDefaults.avatar
        userSettings.alias = ""
        userSettings.phoneCell = ""
        
        LogEvent.print(module: "DeveloperSettingsView:peformDeleteUserSettings", message: "Deleting all user settings...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: Notification.Name("isLoggedOut"), object: nil)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    func performDeleteAllSettings() {
        // delete core data for these entities
        
        userSettings.firstname = ""
        userSettings.lastname = ""
        userSettings.email = ""
        userSettings.avatar = AppDefaults.avatar
        userSettings.alias = ""
        userSettings.phoneCell = ""
        
        userSettings.isIntroduced = false
        userSettings.isTracking = false
        userSettings.isOnboarded = false
        userSettings.isTerms = false
        userSettings.isWelcomed = false
        userSettings.isAccount = false
        userSettings.isPrivacy = false
        userSettings.isLicensed = false
        userSettings.trackingSampleRate = AppDefaults.gps.sampleRate
        userSettings.trackingSpeedThreshold = AppDefaults.gps.speedThreshold
        userSettings.trackingTripSeparator = AppDefaults.gps.tripSeparator
        userSettings.trackingTripEntriesMin = AppDefaults.gps.tripEntriesMin
        
        userSettings.articlesDate = DateInfo.zeroDate
        
        LogEvent.print(module: "DeveloperSettingsView:peformDeleteAllSettings", message: "Deleting all settings...")

        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NotificationCenter.default.post(name: Notification.Name("isReset"), object: nil)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    func performDeleteAllArticles() {
        Articles.deleteArticles()
        userSettings.articlesDate = DateInfo.zeroDate
    }

}

#Preview {
    DeveloperSettingsView()
        .environmentObject(UserSettings())
}
