//
//  LaunchView.swift
//  Globulon
//
//  Created by David Holeman on 8/2/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import BackgroundTasks

struct LaunchView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var appEnvironment: AppEnvironment
    
    @State private var scale: CGFloat = 1.0
    @State private var isProcessing = true
    
    var body: some View {
        
        ZStack {
            // Background color or other content
            //Color.viewBackgroundColorLoginBegin.edgesIgnoringSafeArea(.all)
            if isProcessing {
                VStack {
                    /// Spacer above the graphic
                    Spacer()
                    
                    /// Centered graphic
                    ZStack {
                        Image(colorScheme == .dark ? "appLogoDarkMode" : "appLogoTransparent")
                            .resizable()
                            .frame(width: 100, height: 100)
                        Text(AppSettings.appName)
                            .font(.system(size: 24))
                            .padding(.top, 130)
                        ProgressView()
                            .padding(.top, 150)
                            .scaleEffect(1.75)
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.gray))
                    }
                    .padding(.top, -14)
                    
                    /// Spacer below the graphic
                    Spacer()
                    
                    Text(AppSettings.appCopyright)
                        .font(.system(size: 12))
                        .padding(.bottom, 4) // This ensures a consistent distance from the bottom
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    //.foregroundColor(.white)
                }
                
                .task {
                    LogManager.event(module: "LaunchView.task", message: "▶️ starting...")
                    
                    _ = NetworkManager.shared.isConnected
                    
                    // TODO:  Just wiping the data store clean for testing
                    /*
                    let container = SharedModelContainer.shared.container
                    Task {
                        do {
                            try ModelContainer.resetPersistentStore()
                            print("Persistent store successfully reset.")
                        } catch {
                            print("Error resetting persistent store: \(error)")
                        }
                    }
                    */
                    
        
                    /// OPTION: Schedule any apps you want scheduled when the app starts
                    ///
                    ///`BackgroundManager.shared.scheduleAppRefresh()
                    ///`BackgroundManager.shared.scheduleProcessingTask()

                    
                    sleep(1)
                    
                    /// Change the status when done to exit the LaunchView
                    ///
                    isProcessing.toggle()
                    
                    LogManager.event(module: "LaunchView.task", message: "⏹️ ...finished")
                    
                }
                
            } else {
                VStack {
                    Spacer()
                    ZStack {
                        Image(colorScheme == .dark ? "appLogoDarkMode" : "appLogoTransparent")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .scaleEffect(scale)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now()) {
                                    withAnimation(.easeInOut(duration: 3)) {
                                        // Update the binding value to trigger animation
                                        self.scale = self.scale == 1.0 ? 200 : 1.0
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            NotificationCenter.default.post(name: Notification.Name("isLaunchCompleted"), object: nil)
                                        }
                                        self.presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                            .padding(.top, -14)
                    }
                    
                    /// Spacer below the graphic
                    Spacer()
                    
                    Text(AppSettings.appCopyright)
                        .font(.system(size: 12))
                        .padding(.bottom, 4) // This ensures a consistent distance from the bottom
                        .frame(maxWidth: .infinity, alignment: .center)
                }
 
            }
        }
    }
}


#Preview {
    LaunchView()
        .environmentObject(UserSettings())
        .environmentObject(AppEnvironment())
}
