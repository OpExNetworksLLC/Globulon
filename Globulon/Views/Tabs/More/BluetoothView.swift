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
                            ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                                Text(device.name ?? "Unknown Device")
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
