//
//  MainView.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct MainView: View {
    
    //@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var appStatus = AppStatus()
    @StateObject var networkStatus = NetworkStatus.shared
    
    @State var currentTab =  UserSettings.init().landingPage
    
    var body: some View {
        ZStack {
            TabView(selection: $currentTab) {
                HomeView(isShowSideMenu: $appStatus.isShowSideMenu)
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .tag(LandingPageEnum.home)
                LocationView(isShowSideMenu: $appStatus.isShowSideMenu)
                    .tabItem {
                        Image(systemName: "location")
                        Text("Location")
                    }
                    .tag(LandingPageEnum.location)
                MotionView(isShowSideMenu: $appStatus.isShowSideMenu)
                    .tabItem {
                        Image(systemName: "arrow.triangle.pull")
                        Text("Feed")
                    }
                    .tag(LandingPageEnum.feed)
                TripsViewV3(isShowSideMenu: $appStatus.isShowSideMenu)
                    .tabItem {
                        Image(systemName: "map")
                        Text("Trips")
                    }
                    .tag(LandingPageEnum.trips)
                HistoryView(isShowSideMenu: $appStatus.isShowSideMenu)
                    .tabItem {
                        Image(systemName: "archivebox.fill")
                        Text("History")
                    }
                    .tag(LandingPageEnum.history)
            }

            .overlay(
                Group {
                    if appStatus.isShowSideMenu {
                        Color.clear
                            .contentShape(Rectangle()) // This line makes the clear color tappable, blocking interaction with the view below.
                            .onTapGesture {
                                // Add action if needed when tapping on the overlay, for example, closing the side menu.
                                appStatus.isShowSideMenu = false
                            }
                    }
                }
            )
            /// Show an alert if network status changes
            /// 
            .alert("No Internet Connection!", isPresented: .constant(!networkStatus.isConnected)) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Please check your internet connection.")
                }
            
            if appStatus.isShowSideMenu {
                SideMenuView()

                    .transition(.move(edge: .leading))
                    .zIndex(1) // Ensures SideMenuView is on top
                    .environmentObject(appStatus)
            }
            
        }
        .animation(.easeInOut, value: appStatus.isShowSideMenu)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                processOnAppear()
            }
        }
    }
    
    /// Perform and/or launch any processes or tasks before the user interacts with the app
    ///
    func processOnAppear() {
        
        LogEvent.print(module: "MainView.processOnAppear", message: "starting...")
        
        /// Do stuff...
        
        LogEvent.print(module: "MainView.processOnAppear", message: "...finished")
    }

}

#Preview {
    MainView()
        .environmentObject(UserSettings())
}
