//
//  SystemInfoView.swift
//  OpExShellV1
//
//  Created by David Holeman on 8/2/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//


import SwiftUI

struct SystemInfoView: View {

    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        VStack {
            HStack() {
                Text("System Information")
                    .font(.title)
                Spacer()
            }
        }
        .padding(.leading, 16)
        
        VStack {
            HStack() {
                Text("OS Version....:")
                Text(SystemInfo.os)
                Spacer()
            }
            HStack() {
                Text("Device........:")
                Text(SystemInfo.deviceCode)
                Spacer()
            }
            .padding(.bottom, 8)
            HStack() {
                Text("App Version...:")
                Text("\(VersionManager.releaseDesc)")
                Spacer()
            }
            .padding(.bottom, 8)
            
            Spacer()
            
            Button(action: {

                self.presentationMode.wrappedValue.dismiss()
            }
            ) {
                HStack {
                    Image(systemName: "arrow.left")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .padding()
                        .background(Color("btnPrev"))
                        .cornerRadius(30)
                    Text("Exit").foregroundColor(.blue)
                    Spacer()
                }
            }
            .padding(0)
            Spacer().frame(height: 30)

            
        }
        .font(.system(size: 14, design: .monospaced))
        .foregroundColor(.primary)
        .padding(.top, 8)
        .padding(.leading, 16)
        
    }
}

#Preview {
    SystemInfoView()
}
