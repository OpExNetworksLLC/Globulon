//
//  StartupSequenceView.swift
//  Globulon
//
//  Created by David Holeman on 4/30/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.0 (2025.04.30)
 - Attention:
    - You will want the graphics to be the same here for the screen layout as for the LaunchView so that
      the transition from this to the LaunchView appears seamless
 - Note:
    - Version: 1.0.0 (2025.04.30)
        - Added firebase analytics
*/

import SwiftUI

struct StartupSequenceView: View {
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
                
            }
        }
    }
}

#Preview {
    StartupSequenceView()
}
