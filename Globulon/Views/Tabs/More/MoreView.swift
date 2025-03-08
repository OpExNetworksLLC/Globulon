//
//  MoreView.swift
//  Globulon
//
//  Created by David Holeman on 3/7/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct MoreView: View {
    
    var body: some View {
        NavigationStack {
            HStack {
                Text("More...")
                    .padding(.leading, 21)
                    .font(.title2)
                    .padding(.top, 8)
                Spacer()
            }
            List {
                NavigationLink("Bluetooth connections", destination: BluetoothView())
            }
            .listStyle(.plain)
        }
        .navigationTitle("More")
    }
}

#Preview {
    MoreView()
}
