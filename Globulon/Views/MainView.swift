//
//  MainView.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct MainView: View {
    
    @StateObject var locationHandler = LocationHandler.shared
    @StateObject var activityHandler = ActivityHandler.shared
    
    @StateObject var appStatus = AppStatus()
    @StateObject var networkHandler = NetworkHandler.shared
    
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
                /*
                LocationView(isShowSideMenu: $appStatus.isShowSideMenu)
                    .tabItem {
                        Image(systemName: "location")
                        Text("Location")
                    }
                    .tag(LandingPageEnum.location)
                */
                ActivityView(isShowSideMenu: $appStatus.isShowSideMenu)
                    .tabItem {
                        Image(systemName: "arrow.triangle.pull")
                        Text("Activity")
                    }
                    //.tag(LandingPageEnum.feed)
                MotionView(isShowSideMenu: $appStatus.isShowSideMenu)
                    .tabItem {
                        Image(systemName: "circle.dotted.and.circle")
                        Text("Motion")
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
            .alert("No Internet Connection!", isPresented: .constant(!networkHandler.isConnected)) {
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
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now()) {
//                processOnAppear()
//            }
//        }
        .task {
            LogEvent.print(module: "MainView.task", message: "starting...")
            
            /// Do stuff...
            
            /// Force start location updates if they were manually stopped by the user
            ///
            if locationHandler.updatesStarted == false {
                locationHandler.startLocationUpdates()
            }

//TODO: commented out so activity is not automatically started
//            if activityHandler.updatesStarted == false {
//                activityHandler.startActivityUpdates()
//            }
            
            LogEvent.print(module: "MainView.task", message: "...finished")
        }
    }
}

#Preview {
    MainView()
        .environmentObject(UserSettings())
}
