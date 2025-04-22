//
//  SystemStatusView.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct SystemStatusView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appStatus: AppStatus
    
    @State var isChanged: Bool = false
    
    @ObservedObject var backgroundManager = BackgroundManager.shared
    
    @StateObject var networkManager         = NetworkManager.shared
    @StateObject var notificationManager   = NotificationManager.shared
    @StateObject var activityManager        = ActivityManager.shared
    @StateObject var locationManager        = LocationManager.shared
    @StateObject var bluetoothHandler       = BluetoothHandler.shared
    @StateObject var carPlayManager         = CarPlayManager.shared
    
    @State private var isShowHelp = false
    
    @State private var lastCompletionDate: Date? = nil
    @State private var lastAppRefreshDate: Date? = nil
    @State private var isBluetoothAvailable: Bool = false
    @State private var isBluetoothPermission: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HeaderView()
                Form {
                    NetworkSectionView(
                        isConnected: networkManager.isConnected,
                        isReachable: networkManager.isReachable
                    )
                    CarPlaySectionView(
                        carPlayManager: carPlayManager
                    )
                    BluetoothSectionView(
                        bluetoothHandler: bluetoothHandler,
                        isAuthorized: isBluetoothPermission,
                        isAvailable: isBluetoothAvailable,
                        //isAuthorized: bluetoothHandler.isAuthorized,
                        //isAvailable: bluetoothHandler.isAvailable,
                        isConnected: bluetoothHandler.isConnected
                    )
                    PermissionsSectionView(
                        authorizedDescription: locationManager.authorizedDescription,
                        isLocationAuthorized: locationManager.isAuthorized,
                        isMotionAuthorized: activityManager.isAuthorized,
                        isNotificationEnabled: notificationManager.isNotificationsEnabled,
                        isBluetoothPermission: bluetoothHandler.isPermission
                    )
                    DeviceSectionView(
                        isMotionActivityAvailable: activityManager.isAvailable
                    )
                    MonitoringSectionView(
                        locationManager: locationManager,
                        activityManager: activityManager
                    )
                    BackgroundSectionView(
                        backgroundManager: backgroundManager
                    )

                }
                .background(Color.clear) // Sets background of the entire form
                .scrollContentBackground(.hidden) // Hides the default gray background
                .background(Color.clear) // Ensures a white background underneath
                .onAppear {
                    _ = loadLastCompletionDate
                    _ = loadLastAppRefreshDate
                    
                    /// get the bluetooth permission status
                    bluetoothHandler.getBluetoothPermission { result in
                        self.isBluetoothPermission = result
                    }
                    bluetoothHandler.getBluetoothAvailablity { result in
                        self.isBluetoothAvailable = result
                    }
                }
                /// Update anytime a new value is received
                .onReceive(bluetoothHandler.$isAvailable) { newValue in
                    self.isBluetoothAvailable = newValue
                }
            }
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
        .padding(.bottom, 16)
    }
    
    
    /// Load the last completion date from UserDefaults
    private func loadLastCompletionDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "LastBackgroundTaskCompletionDate") as? Date {
            lastCompletionDate = savedDate
        }
    }
    
    /// Load the last completion date from UserDefaults
    private func loadLastAppRefreshDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "LastAppRefreshTaskCompletionDate") as? Date {
            lastAppRefreshDate = savedDate
        }
    }
    
    /// Format the date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd h:mm:ss a"  // Date in yyyy-MM-dd and Time in h:mm:ss AM/PM
        return formatter.string(from: date)
    }
    
    struct HeaderView: View {
        var body: some View {
            VStack(alignment: .leading) {
                Text("Application Status")
                    .font(.system(size: 24, weight: .bold))
                    .padding([.leading, .trailing], 16)
                    .padding(.bottom, 1)
                Text("These settings reflect the behavior of the app...")
                    .font(.system(size: 14))
                    .padding([.leading, .trailing], 16)
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width - 24, height: 60, alignment: .leading)
            .padding(.top, 16)
        }
    }
    
    struct NetworkSectionView: View {
        let isConnected: Bool
        let isReachable: Bool

        var body: some View {
            Section(header: Text("NETWORK")) {
                HStack {
                    Text("Connectivity:")
                    Spacer()
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                HStack {
                    Text("Reachability:")
                    Spacer()
                    Circle()
                        .fill(isReachable ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: -8)
            .padding(.trailing, -16)
        }
    }
    
    struct CarPlaySectionView: View {
        
        @ObservedObject var carPlayManager: CarPlayManager
        
        var body: some View {
            Section(header: Text("CAR PLAY")) {
                HStack {
                    Text("Connected:")
                    Spacer()
                    Circle()
                        .fill(carPlayManager.isCarPlayConnected ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: -8)
            .padding(.trailing, -16)
        }
    }
    
    struct BluetoothSectionView: View {

        @ObservedObject var bluetoothHandler: BluetoothHandler
        
        let isAuthorized: Bool
        let isAvailable: Bool
        let isConnected: Bool
        

        var body: some View {
            Section(header: Text("BLUETOOTH")) {
                HStack {
                    Text("Authorized:")
                    Spacer()
                    Circle()
                        .fill(isAuthorized ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                HStack {
                    Text("Availablity:")
                    Spacer()
                    Circle()
                        .fill(isAvailable ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                HStack {
                    Text("Connected:")
                    Spacer()
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                HStack {
                        Button(role: .destructive) {
                            Task {
                                await bluetoothHandler.startBluetoothUpdates()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .padding(.leading, 8)
                                Text("Start")
                                Spacer()
                            }
                            .foregroundColor(.blue)
                            .frame(width: 100, height: 32)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 5,
                                    style: .continuous
                                )
                                .stroke(.blue, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 8)
                        .disabled(bluetoothHandler.updatesLive)
                        
                        Button(role: .destructive) {
                            bluetoothHandler.stopBluetoothUpdates()
                        } label: {
                            HStack {
                                Image(systemName: "pause")
                                    .resizable()
                                    .frame(width: 8, height: 16)
                                    .padding(.leading, 8)
                                Text("Pause")
                                Spacer()
                            }
                            .foregroundColor(.blue)
                            .frame(width: 100, height: 32)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 5,
                                    style: .continuous
                                )
                                .stroke(.blue, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 8)
                        .disabled(!bluetoothHandler.updatesLive)
                    }
                
            }
            .onAppear {
            }
            .offset(x: -8)
            .padding(.trailing, -16)
        }
    }
    
    struct PermissionsSectionView: View {
        let authorizedDescription: String
        let isLocationAuthorized: Bool
        let isMotionAuthorized: Bool
        let isNotificationEnabled: Bool
        let isBluetoothPermission: Bool

        var body: some View {
            Section(header: Text("PERMISSIONS")) {
                HStack {
                    Text("Location: \(authorizedDescription)")
                    Spacer()
                    Circle()
                        .fill(isLocationAuthorized ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                HStack {
                    Text("Motion:")
                    Spacer()
                    Circle()
                        .fill(isMotionAuthorized ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                HStack {
                    Text("Notifications:")
                    Spacer()
                    Circle()
                        .fill(isNotificationEnabled ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                HStack {
                    Text("Bluetooth:")
                    Spacer()
                    Circle()
                        .fill(isBluetoothPermission ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: -8)
            .padding(.trailing, -16)
        }
    }
    
    struct DeviceSectionView: View {
        let isMotionActivityAvailable: Bool

        var body: some View {
            Section(header: Text("DEVICE")) {
                HStack {
                    Text("Motion activity sensor:")
                    Spacer()
                    Circle()
                        .fill(isMotionActivityAvailable ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
            }
            .offset(x: -8)
            .padding(.trailing, -16)
        }
    }
    
    struct MonitoringSectionView: View {
        @ObservedObject var locationManager: LocationManager
        @ObservedObject var activityManager: ActivityManager

        var body: some View {
            Section(header: Text("MONITORING")) {
                // Location monitoring
                HStack {
                    Text("Location:")
                    Spacer()
                    Circle()
                        .fill(locationManager.updatesLive ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                }
                HStack {
                    Button(role: .destructive) {
                        locationManager.startLocationUpdates()
                    } label: {
                        HStack {
                            Image(systemName: "play")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .padding(.leading, 8)
                            Text("Start")
                            Spacer()
                        }
                        .foregroundColor(.blue)
                        .frame(width: 100, height: 32)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 5,
                                style: .continuous
                            )
                            .stroke(.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 8)
                    .disabled(locationManager.updatesLive)

                    Button(role: .destructive) {
                        print("pause")
                        locationManager.stopLocationUpdates()
                    } label: {
                        HStack {
                            Image(systemName: "pause")
                                .resizable()
                                .frame(width: 8, height: 16)
                                .padding(.leading, 8)
                            Text("Pause")
                            Spacer()
                        }
                        .foregroundColor(.blue)
                        .frame(width: 100, height: 32)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 5,
                                style: .continuous
                            )
                            .stroke(.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 8)
                    .disabled(!locationManager.updatesLive)
                }

                // Motion monitoring (only if available)
                if activityManager.isAvailable {
                    HStack {
                        Text("Motion:")
                        Spacer()
                        Circle()
                            .fill(activityManager.isActivityMonitoringOn ? Color.green : Color.red)
                            .frame(width: 16, height: 16)
                    }
                    HStack {
                        Button(role: .destructive) {
                            activityManager.startActivityUpdates()
                        } label: {
                            HStack {
                                Image(systemName: "play")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .padding(.leading, 8)
                                Text("Start")
                                Spacer()
                            }
                            .foregroundColor(.blue)
                            .frame(width: 100, height: 32)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 5,
                                    style: .continuous
                                )
                                .stroke(.blue, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 8)
                        .disabled(activityManager.isActivityMonitoringOn)

                        Button(role: .destructive) {
                            print("pause")
                            activityManager.stopActivityUpdates()
                        } label: {
                            HStack {
                                Image(systemName: "stop")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .padding(.leading, 8)
                                Text("Pause")
                                Spacer()
                            }
                            .foregroundColor(.blue)
                            .frame(width: 100, height: 32)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 5,
                                    style: .continuous
                                )
                                .stroke(.blue, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 8)
                        .disabled(!activityManager.isActivityMonitoringOn)
                    }
                }
            }
            .offset(x: -8)
            .padding(.trailing, -16)
        }
    }

    struct BackgroundSectionView: View {
        @ObservedObject var backgroundManager: BackgroundManager
        
        var body: some View {
            Section(header: Text("BACKGROUND")) {
                /// Show current status based on the taskState enum
                HStack {
                    Text("Current State:")
                    Spacer()
                    Text("\(backgroundManager.taskState.statusDescription)")
                }
                HStack {
                    Button(role: .destructive) {
                        print("stop all")
                        BackgroundManager.shared.cancelAllBackgroundTasks()
                    } label: {
                        HStack{
                            Image(systemName: "stop")
                                .resizable()
                                .frame(width: 16,height: 16)
                                .padding(.leading, 8)
                            Text("Stop All")
                            Spacer()
                        }
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .frame(width: 100, height: 32)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 5,
                                style: .continuous
                            )
                            .stroke(.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 1)
                    Spacer()
                }
                HStack {
                    Text("Last Background:")
                    Spacer()
                    Text("\((UserDefaults.standard.object(forKey: "LastBackgroundTaskCompletionDate") as? Date)?.formatted() ?? "Never")")
                }
                
                HStack {
                    Button(role: .destructive) {
                        print("play background")
                        BackgroundManager.shared.scheduleProcessingTask()
                    } label: {
                        HStack{
                            Image(systemName: "play")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .padding(.leading, 8)
                            Text("Start")
                            Spacer()
                        }
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .frame(width: 100, height: 32)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 5,
                                style: .continuous
                            )
                            .stroke(.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 4)
                    
                    Button(role: .destructive) {
                        print("stop background")
                        BackgroundManager.shared.cancelBackgroundTask()
                    } label: {
                        HStack{
                            Image(systemName: "stop")
                                .resizable()
                                .frame(width: 16,height: 16)
                                .padding(.leading, 8)
                            Text("Stop")
                            Spacer()
                        }
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .frame(width: 100, height: 32)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 5,
                                style: .continuous
                            )
                            .stroke(.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                
                HStack {
                    Text("Last App Refresh:")
                    Spacer()
                    Text("\((UserDefaults.standard.object(forKey: "LastAppRefreshTaskCompletionDate") as? Date)?.formatted() ?? "Never")")
                }
                
                HStack {
                    Button(role: .destructive) {
                        print("play refresh")
                        BackgroundManager.shared.scheduleAppRefresh()
                    } label: {
                        HStack{
                            Image(systemName: "play")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .padding(.leading, 8)
                            Text("Start")
                            Spacer()
                        }
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .frame(width: 100, height: 32)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 5,
                                style: .continuous
                            )
                            .stroke(.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 4)
                    
                    Button(role: .destructive) {
                        print("stop refresh")
                        BackgroundManager.shared.cancelAppRefreshTask()
                    } label: {
                        HStack{
                            Image(systemName: "stop")
                                .resizable()
                                .frame(width: 16,height: 16)
                                .padding(.leading, 8)
                            Text("Stop")
                            Spacer()
                        }
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .frame(width: 100, height: 32)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 5,
                                style: .continuous
                            )
                            .stroke(.blue, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 4)
    
                }
            }
            .offset(x: -8)
            .padding(.trailing, -16)
        }
    }

}

#Preview {
    SystemStatusView()
}
