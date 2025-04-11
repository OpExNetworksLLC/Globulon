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
    @StateObject private var bluetoothHandler = BluetoothHandler.shared
    
    @State private var isShowHelp = false
    
    var body: some View {
        NavigationStack {
            
            VStack {
                if bluetoothHandler.bluetoothState != .poweredOn {
                    Text("Bluetooth is not available.\nPlease enable Bluetooth.")
                } else {
                    List {
                        Section(header: Text("Connected Devices")) {
                            ForEach(bluetoothHandler.connectedDevices, id: \.identifier) { device in
                                Text(device.name ?? "Unknown Device")
                            }
                        }
                        
                        Section(header: Text("Discovered Devices")) {
                            ForEach(bluetoothHandler.discoveredDevices, id: \.identifier) { device in
                                Text(device.name ?? "Unknown Device")
                            }
                        }
                    }
                }
            }
            .onAppear {
                bluetoothHandler.startScanning()
                //bluetoothHandler.startBluetoothUpdates()
            }
            .onDisappear {
                bluetoothHandler.stopScanning()
                //bluetoothHandler.stopBluetoothUpdates()
            }
        }
        .navigationTitle("Bluetooth")
    }
}

#Preview {
    BluetoothView()
}
