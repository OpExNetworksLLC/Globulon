//
//  PermissionsView.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

/**
    - Version: 1.0.1
    - Date: 11-25-2024
    - Note: Changes
    * Added Bluetooth permission request.
 
    - Version: 1.0.0
    - Date: 08-05-2024
 
    # plist.info  modifications:
    Add these items to the pinfo.list depending on which ones you use in your app:
    - Privacy - Location Always Usage Description = This app always has access to your device location
    - Privacy - Location When in Use Description= This app requires access to your device when in use
    - Privacy - Location Always and When in Use Description = This app when and always requires access to your device location
*/
struct PermissionsView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var userSettings: UserSettings
    
    /// Singlton access to LocationManager
    /// Uncomment if you want to permit use of location services
    ///
    let locationManager = LocationManager.shared
    
    /// OPTION: Setting required permissions
    ///
    /// Set to false if you want to require a permission to be allowed.
    /// Set to true if user can bypass permissions and set later but will have to do so manually
    ///
    @State var isPermissionAllowed: Bool = false
    
    /// Uncomment to support use of location services
    ///
    @State var isWhenInUseAuthorization = false
    @State var isAuthorizedAlways = false
    
    /// Motion tracking
    @State var isMotionTrackingAllowed = false
    
    /// Singleton access tothe notifications handler
    let notificationManager = NotificationManager.shared
    @State var isUserNotificationAllowed = false
    
    /// Bluetooth
    let bluetoothHandler = BluetoothHandler.shared
    @State var isBluetoothAllowed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                
                Spacer().frame(height: 16)
                
                Text("Set permissions for \(AppSettings.appName)...")
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
                                        locationManager.requestWhenInUseAuthorization()
                                        isWhenInUseAuthorization = true
                                        isPermissionAllowed = true
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
                                        locationManager.requestAuthorizedAlways()
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
                                locationManager.getAuthorizedWhenInUse { result in
                                    self.isWhenInUseAuthorization = result
                                }
                                locationManager.getAuthorizedAlways { result in
                                    self.isAuthorizedAlways = result
                                }
                                ///  Set to WhenInUseAuthorization to true when AuthorizedAlways is set.
                                if self.isAuthorizedAlways { self.isWhenInUseAuthorization = true }
                                
                                if self.isWhenInUseAuthorization || self.isAuthorizedAlways {
                                    isPermissionAllowed = true
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
                                Text("Allow motion tracking to improve tracking accuracy.")
                                Button(action: {
                                    if !self.isMotionTrackingAllowed {
                                        ActivityManager.requestMotionActivityPermission { result in
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
                                ActivityManager.shared.getMotionActivityPermission { result in
                                    
                                    /// Passing back if tracking is allowed
                                    ///
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
                                Text("Receive push notifications.")
                                
                                Button(action: {
                                    /*
                                    if !self.isUserNotificationAllowed {
                                        NotificationManager.requestUserNotificationPermission { result in
                                            self.isUserNotificationAllowed = result
                                        }
                                        isPermissionAllowed = true
                                        
                                        /// FCM:  start firebase enabled  notifications
//                                        DispatchQueue.main.async {
//                                            self.appDelegate.registerForNotifications()
//                                        }
                                        
                                    }
                                    */
                                    Task {
                                        let result = await notificationManager.requestUserNotificationPermission()
                                        if result {
                                            self.isUserNotificationAllowed = true
                                            isPermissionAllowed = true
                                        }
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
                                .onAppear {
                                    /// Check and reflect the latest status.  This is important because if this view is accessed after intial setup we want
                                    /// to reflect the latest status of permissions set for the app.
                                    Task {
                                        if notificationManager.isNotificationsEnabled {
                                            self.isUserNotificationAllowed = true
                                            isPermissionAllowed = true
                                        }
//                                        let result = await notificationManager.requestUserNotificationPermission()
//                                        if result {
//                                            self.isUserNotificationAllowed = true
//                                            isPermissionAllowed = true
//                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .fixedSize(horizontal: false, vertical: true)
//                            .onAppear {
//                                notificationManager.getUserNotificationPermission { result in
//                                    self.isUserNotificationAllowed = result
//                                }
//                            }
                            
                            Spacer()
                        }
                        
                        /// BLUETOOTH
                        ///
                        HStack() {
                            Spacer().frame(width: 16)
                            VStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .symbolVariant(.none) // Default style, no fill
                                    .font(.system(size: 32, weight: .thin))
                                Spacer()
                            }
                            .padding(.trailing, 12)
                            VStack(alignment: .leading) {
                                Text("BLUETOOTH")
                                    .padding(.bottom, 2)
                                Text("Allow bluetooth access.")
                                    .padding(.bottom, 4)

                                Button(action: {
                                    if !self.isBluetoothAllowed {
                                        Task {
                                            await bluetoothHandler.requestBluetoothPermission()
                                            self.isBluetoothAllowed = true
                                            isPermissionAllowed = true
                                        }
                                    }
                                }) {
                                    HStack {
                                        Spacer()
                                        if !self.isBluetoothAllowed {
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
                                .background(self.isBluetoothAllowed ? Color.gray : Color("btnNextTracking"))
                                .edgesIgnoringSafeArea(.horizontal)
                                .cornerRadius(5)
                                .padding(.bottom, 8)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .onAppear {
                                bluetoothHandler.getBluetoothPermission { result in
                                    self.isBluetoothAllowed = result
                                    isPermissionAllowed = true
                                }
                            }
                            
                        }
                        Spacer()
                    }
                    
                }
                
                /// Prev/Next
                ///
                HStack {
                    /// Declined button
                    ///
                    Button(action: {
                        /// Set these becaue in the onboard flow someone can go backwards and decline
                        userSettings.isPermissions = false
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isReset"), object: nil)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .foregroundColor(isPermissionAllowed ? .white : .white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(isPermissionAllowed ? Color(UIColor.systemGray5) : .btnPrevPermissions)
                                .cornerRadius(30)
                            Text("Decline")
                                .foregroundColor(isPermissionAllowed ? .gray : .btnPrevPermissions)
                            
                        }
                    }
                    .padding(0)
                    
                    Spacer()
                    
                    /// Next button
                    ///
                    Button(action: {
                        userSettings.isPermissions = true
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isPermissions"), object: nil)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Text("next")
                                .foregroundColor(isPermissionAllowed ? .btnNextPermissions : .gray)
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(isPermissionAllowed ? .white : .white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(isPermissionAllowed ? .btnNextPermissions : Color(UIColor.systemGray5))
                                .cornerRadius(30)
                        }
                    }
                    .disabled(isPermissionAllowed ? false : true)  // disable:enable the button
                    
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
