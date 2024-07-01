//
//  LaunchView.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct LaunchView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
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
                        Text(AppValues.appName)
                            .font(.headline)
                            //.foregroundColor(.white)
                            .padding(.top, 150)
                        ProgressView()
                            .padding(.top, 150)
                            .scaleEffect(1.75)
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.gray))
                    }
                    .padding(.bottom, 8)

                    /// Spacer below the graphic
                    Spacer()
                    
                    Text("Copyright © 2024 OpEx Networks, LLC. All rights reserved.")
                        .font(.system(size: 12))
                        //.foregroundColor(.white)
                }

                .task {
                    
                    await processTask()
                }

            } else {
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
            }
        }
    }
    
    /// Process Task
    ///
    /// Using .task vs .onAppear will will wait for async tasks to complete before continuing.
    ///
    func processTask() async {
        
        LogEvent.print(module: "LaunchView.processTask", message: "starting...")
        
        /// Load the help articles if needed
        ///
        Articles.load { success, message in
            LogEvent.print(module: "LaunchView.processTask", message: message)
        }
        
        /// We do this here early so that we can reflect the lastest in the scores based on processed trips
        /// 
        await processTrips()
        
        /// Flush out processed GPS data
        ///
        _ = deleteAllProcessedGPSJournalSD()
        
        /// Change the status when done to exit the LaunchView
        ///
        isProcessing.toggle()
        
        LogEvent.print(module: "LaunchView.processTask", message: "...finished")

    }
}

#Preview {
    LaunchView()
}

