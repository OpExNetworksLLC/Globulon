//
//  PermissionsView.swift
//  ViDrive
//
//  Created by David Holeman on 3/12/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct PermissionsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    /// Singlton access to LocationManager
    let locationHandler = LocationHandler.shared
    
    @EnvironmentObject var userSettings: UserSettings
    
    @State var isTrackingAllowed: Bool = false
    @State var isWhenInUseAuthorization = false
    @State var isAuthorizedAlways = false
    @State var isUserNotificationAllowed = false
    @State var isMotionTrackingAllowed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                
                Spacer().frame(height: 16)
                
                Text("Set permissions for \(AppValues.appName)...")
                    .font(.system(size: 24))
                    .padding(.bottom, 24)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading) {
                        
                        /// LOCATION
                        ///
                        HStack() {
                            Spacer().frame(width: 16)
                            VStack {
                                Image(systemName: "location.circle")
                                    .symbolVariant(.none) // Default style, no fill
                                    .font(.system(size: 32, weight: .thin))
                                Spacer()
                            }
                            .padding(.trailing, 12)
                            VStack(alignment: .leading) {
                                Text("LOCATION")
                                    .padding(.bottom, 2)
                                Text("Grant permission for location tracking to track your trips when you are using the app.")
                                    .padding(.bottom, 4)
                                
                                /// AllowWhenInUse
                                ///
                                Button(action: {
                                    if !self.isWhenInUseAuthorization {
                                        locationHandler.requestWhenInUseAuthorization()
                                        isWhenInUseAuthorization = true
                                        isTrackingAllowed = true
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        if !self.isWhenInUseAuthorization {
                                            Text("Allow")
                                                .padding()
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "checkmark.circle")
                                                .font(.system(size: 32, weight: .light))
                                                .foregroundColor(.white)
                                            Text("Allowed")
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                    }
                                    .frame(height: 48)
                                }
                                .frame(maxWidth: .infinity)
                                .background(self.isWhenInUseAuthorization ? Color.gray : Color("btnNextTracking"))
                                .edgesIgnoringSafeArea(.horizontal)
                                .cornerRadius(5)
                                .padding(.bottom, 8)
                                
                                Text("Set to always allow so that the app continues to collect trip data.")
                                    .padding(.bottom, 4)
                                
                                ///  AuthorizedAlways
                                ///
                                Button(action: {
                                    if !self.isAuthorizedAlways {
                                        locationHandler.requestAuthorizedAlways()
                                        isAuthorizedAlways = true
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        if !self.isAuthorizedAlways {
                                            Text("Allow")
                                                .padding()
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "checkmark.circle")
                                                .font(.system(size: 32, weight: .light))
                                                .foregroundColor(.white)
                                            Text("Allowed")
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                    }
                                    .frame(height: 48)
                                }
                                .frame(maxWidth: .infinity)
                                .background(self.isAuthorizedAlways ? Color.gray : Color("btnNextTracking"))
                                .edgesIgnoringSafeArea(.horizontal)
                                .cornerRadius(5)
                                .padding(.bottom, 8)
                                
                                
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .onAppear {
                                locationHandler.getAuthorizedWhenInUse { result in
                                    self.isWhenInUseAuthorization = result
                                }
                                locationHandler.getAuthorizedAlways { result in
                                    self.isAuthorizedAlways = result
                                }
                                ///  Set to WhenInUseAuthorization to true when AuthorizedAlways is set.
                                if self.isAuthorizedAlways { self.isWhenInUseAuthorization = true }
                                
                                if self.isWhenInUseAuthorization || self.isAuthorizedAlways {
                                    isTrackingAllowed = true
                                }
                            }
                            
                        }
                        
                        /// MOTION
                        ///
                        HStack() {
                            Spacer().frame(width: 16)
                            VStack {
                                Image(systemName: "iphone.gen2.radiowaves.left.and.right.circle")
                                    .symbolVariant(.none) // Default style, no fill
                                    .font(.system(size: 32, weight: .thin))
                                Spacer()
                            }
                            .padding(.trailing, 12)
                            VStack(alignment: .leading) {
                                Text("MOTION")
                                    .padding(.bottom, 2)
                                Text("Allow motion tracking to improve tracking accuracy")
                                Button(action: {
                                    if !self.isMotionTrackingAllowed {
                                        MotionManager.requestMotionTrackingPermission { result in
                                            isMotionTrackingAllowed = result
                                        }
                                        // TODO: Forcing this for now.  should wait or loop until activated.
                                        isMotionTrackingAllowed = true
                                        
                                    }

                                }) {
                                    HStack {
                                        Spacer()
                                        if !self.isMotionTrackingAllowed {
                                            Text("Allow")
                                                .padding()
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "checkmark.circle")
                                                .font(.system(size: 32, weight: .light))
                                                .foregroundColor(.white)
                                            Text("Allowed")
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                    }
                                    .frame(height: 48)
                                }
                                .frame(maxWidth: .infinity)
                                .background(self.isMotionTrackingAllowed ? Color.gray : Color("btnNextTracking"))
                                .edgesIgnoringSafeArea(.horizontal)
                                .cornerRadius(5)
                                .padding(.bottom, 16)
                                
                                Spacer()
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .onAppear {
                                MotionManager.getMotionTrackingPermission { result in
                                    self.isMotionTrackingAllowed = result
                                }
                            }
                            
                        }
                        
                        /// NOTIFICATIONS
                        ///
                        HStack {
                            Spacer().frame(width: 16)
                            
                            VStack {
                                Image(systemName: "bell.circle")
                                    .symbolVariant(.none) // Default style, no fill
                                    .font(.system(size: 32, weight: .thin))
                                Spacer()
                            }
                            .padding(.trailing, 12)
                            
                            VStack(alignment: .leading) {
                                Text("NOTIFICATIONS")
                                    .padding(.bottom, 2)
                                Text("Receive push notifications")
                                
                                Button(action: {
                                    if !self.isUserNotificationAllowed {
                                        NotificationManager.requestUserNotificationPermission { result in
                                            isUserNotificationAllowed = result
                                        }
                                        
                                        /// FCM:  start it up
//                                        DispatchQueue.main.async {
//                                            self.appDelegate.registerForNotifications()
//                                        }
                                        
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        if !self.isUserNotificationAllowed {
                                            Text("Allow")
                                                .padding()
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "checkmark.circle")
                                                .font(.system(size: 32, weight: .light))
                                                .foregroundColor(.white)
                                            Text("Allowed")
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                    }
                                    .frame(height: 48)
                                }
                                .frame(maxWidth: .infinity)
                                .background(self.isUserNotificationAllowed ? Color.gray : Color("btnNextTracking"))
                                .edgesIgnoringSafeArea(.horizontal)
                                .cornerRadius(5)
                                .padding(.bottom, 16)
                                
                                Spacer()
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .onAppear {
                                NotificationManager.getUserNotificationPermission { result in
                                    self.isUserNotificationAllowed = result
                                }
                            }
                            
                            Spacer()
                        }
                        Spacer()
                    }
                    
                }
                
                /// Prev/Next
                ///
                HStack {
                    /// Declined button
                    Button(action: {
                        /// Set these becaue in the onboard flow someone can go backwards and decline
                        userSettings.isTracking = false
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isReset"), object: nil)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .foregroundColor(isTrackingAllowed ? .white : .white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(isTrackingAllowed ? Color(UIColor.systemGray5) : .btnPrevTracking)
                                .cornerRadius(30)
                            Text("Decline")
                                .foregroundColor(isTrackingAllowed ? .gray : .btnPrevTracking)
                            
                        }
                    }
                    .padding(0)
                    
                    Spacer()
                    Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isTracking"), object: nil)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                        
                        
                    }
                    ) {
                        HStack {
                            Text("next")
                                .foregroundColor(isTrackingAllowed ? .btnNextTracking : .gray)
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(isTrackingAllowed ? .white : .white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(isTrackingAllowed ? Color("btnNextTracking") : Color(UIColor.systemGray5))
                                .cornerRadius(30)
                        }
                    }
                    .disabled(isTrackingAllowed ? false : true)  // disable:enable the button
                    
                } // end HStack
                Spacer().frame(height: 32)
                
            }
            .padding(.leading, 16)
            // End VStack

            Spacer().frame(width: 16)
        } // End HStack
        .edgesIgnoringSafeArea(.bottom)
    }
    
}

#Preview {
    PermissionsView()
        //.environmentObject(LocationManager())
}
