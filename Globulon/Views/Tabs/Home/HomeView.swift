//
//  HomeView.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    
    @Binding var isShowSideMenu: Bool

    @EnvironmentObject var appEnvironment: AppEnvironment
    
    @StateObject var networkHandler = NetworkHandler.shared
    
    @State private var isShowHelp = false
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Home View!")
                Spacer()
            }
        }
    }
}

#Preview {
    HomeView(isShowSideMenu: .constant(false))
}
