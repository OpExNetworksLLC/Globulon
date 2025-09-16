//
//  BluetoothView.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0
 - Date: 09-27-2024
 - Note: Start
*/

import SwiftUI

struct BluetoothView: View {
        
    @StateObject var networkManager = NetworkManager.shared
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    @State private var isShowHelp = false
    
    var body: some View {
        NavigationStack {
            
            VStack {
                if bluetoothManager.bluetoothState != .poweredOn {
                    Text("Bluetooth is not available.\nPlease enable Bluetooth.")
                } else {
                    List {
                        Section(header: Text("Connected Devices")) {
                            ForEach(bluetoothManager.connectedDevices, id: \.identifier) { device in
                                Text(device.name ?? "Unknown Device")
                            }
                        }
                        
                        Section(header: Text("Discovered Devices")) {
                            ForEach(bluetoothManager.discoveredDevices
                                .filter { !($0.name?.isEmpty ?? true) } // Filter out devices with no name
                                .sorted(by: {
                                    ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
                                }), id: \.identifier) { device in
                                    Text(device.name!)
                            }
                        }
                    }
                }
            }
            .onAppear {
                bluetoothManager.startScanning()
                //bluetoothManager.startBluetoothUpdates()
            }
            .onDisappear {
                bluetoothManager.stopScanning()
                //bluetoothManager.stopBluetoothUpdates()
            }
        }
        .navigationTitle("Bluetooth")
    }
}

#Preview {
    BluetoothView()
}
