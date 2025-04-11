//
//  OtherView.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct OtherView: View {

    @Binding var isShowSideMenu: Bool
    
    @StateObject var networkManager = NetworkManager.shared
    
    @State private var isShowHelp = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Other View!")
                Spacer()
            }
        }
    }
}

#Preview {
    OtherView(isShowSideMenu: .constant(false))
}

