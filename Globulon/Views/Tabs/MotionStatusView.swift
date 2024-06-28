//
//  MotionStatusView.swift
//  Globulon
//
//  Created by David Holeman on 6/26/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import CoreMotion

struct MotionStatusView: View {
    
    @Binding var isShowSideMenu: Bool
    
    @ObservedObject var locationsHandler = LocationsHandler.shared
    @StateObject private var activityHandler = ActivityHandler.shared
    
    @State var isShowHelp = false
    @State var isRecording = false

    var body: some View {

///
        // Top menu
        NavigationStack {
            VStack(spacing: 0) {
                
                // TODO:  list was here from dataset
                
                /// display stuff here
                ///
                VStack {
                    Spacer().frame(height: 16)
                    VStack() {
                        HStack() {
                            VStack() {
                                HStack() {
                                    Text("\(self.locationsHandler.priorCount)")
                                        .frame(width: 30, alignment: .trailing)
                                    Text("Date:")
                                        .frame(width: 75, alignment: .leading)
                                    Text("\(formatDateStampM(self.locationsHandler.priorLocation.timestamp))")
                                    Spacer()
                                }
                                
                                HStack() {
                                    Spacer().frame(width: 40)
                                    Text("Lat/Lng:")
                                        .frame(width: 75, alignment: .leading)
                                    Text("\(self.locationsHandler.priorLocation.coordinate.latitude) / \(self.locationsHandler.priorLocation.coordinate.longitude)")
                                    Spacer()
                                }
                                HStack() {
                                    Spacer().frame(width: 40)
                                    Text("Speed:")
                                        .frame(width: 75, alignment: .leading)
                                    Text("\(self.locationsHandler.lastLocation.speed)")
                                    Spacer()
                                }
                            }
                        }
                        
                        Spacer().frame(height: 16)
                        
                        HStack() {
                            VStack() {
                                HStack() {
                                    Text("\(self.locationsHandler.count)")
                                        .frame(width: 30, alignment: .trailing)
                                    Text("Date:")
                                        .frame(width: 75, alignment: .leading)
                                    Text("\(formatDateStampM(self.locationsHandler.lastLocation.timestamp))")
                                    Spacer()
                                }
                                
                                HStack() {
                                    Spacer().frame(width: 40)
                                    Text("Lat/Lng:")
                                        .frame(width: 75, alignment: .leading)
                                    Text("\(self.locationsHandler.lastLocation.coordinate.latitude) / \(self.locationsHandler.lastLocation.coordinate.longitude)")
                                    Spacer()
                                }
                                HStack() {
                                    Spacer().frame(width: 40)
                                    Text("Speed:")
                                        .frame(width: 75, alignment: .leading)
                                    Text("\(self.locationsHandler.lastLocation.speed)")
                                    Spacer()
                                }
                            }
                            Spacer()
                        }

                    }
                    .padding(.leading, 16)
                    
                    Spacer().frame(height: 16)
                    VStack() {
                        HStack(){
                            VStack() {
                                Text("moving")
                                Rectangle()
                                    .fill(self.locationsHandler.isMoving ? .green : .red)
                                    .frame(width: 75, height: 75, alignment: .center)
                            }
                            VStack() {
                                Text("walking")
                                Rectangle()
                                    .fill(self.locationsHandler.isWalking ? .green : .red)
                                    .frame(width: 75, height: 75, alignment: .center)
                            }
                            VStack() {
                                Text("driving")
                                Rectangle()
                                    .fill(self.locationsHandler.isDriving ? .green : .red)
                                    .frame(width: 75, height: 75, alignment: .center)
                            }

                        }
                    }
                    .padding(.leading, 16)
                    
                    Text("activity: \(activityHandler.isActivity)\nstate: \(activityHandler.activityState)")
                    
                    Spacer()
                    /* On:Off in Navigation Bar
                    Button(self.locationsHandler.updatesStarted ? "Stop Location Updates" : "Start Location Updates") {
                        self.locationsHandler.updatesStarted ? self.locationsHandler.stopLocationUpdates() : self.locationsHandler.startLocationUpdates()
                        self.activityHandler.startActivityUpdates()
                    }
                    .buttonStyle(.bordered)
                    */
                    Button(self.locationsHandler.backgroundActivity ? "Stop BG Activity Session" : "Start BG Activity Session") {
                        self.locationsHandler.backgroundActivity.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                
                /// end display stuff
                
                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            
            
            /// Navigation Bar
            ///
            .navigationBarItems(leading: Button(action: {
                isShowSideMenu.toggle()
            }) {
                Image(systemName: "square.leftthird.inset.filled")
                    .font(.system(size: 26, weight: .ultraLight))
                    .frame(width: 35, height:35)
                    .foregroundColor(AppValues.pallet.primaryLight)
                
            }, trailing: Button(action: {
                // Do stuff
                isRecording.toggle()
                if isRecording {
                    self.locationsHandler.startLocationUpdates()
                } else {
                    self.locationsHandler.stopLocationUpdates()
                }
            }) {
                if isRecording {
                    Image(systemName: "record.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color.red)
                        .frame(width: 35, height: 35)
                    Text("recording")
                        .foregroundColor(AppValues.pallet.primaryLight)

                } else {
                    Image(systemName: "record.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(AppValues.pallet.primaryLight)
                        .foregroundColor(Color.red)
                        .frame(width: 35, height: 35)
                    Text("record")
                        .foregroundColor(AppValues.pallet.primaryLight)
                }
            })
            //.fullScreenCover(isPresented: $isShowHelp, content: {
            .sheet(isPresented: $isShowHelp, content: {
                // Content of the sheet
                HelpSheetView(isShowHelp: $isShowHelp)
            })
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("appLogoTransparent")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                        .foregroundColor(AppValues.pallet.primaryLight)
                }
            }
        }
        .onAppear() {
            isRecording = locationsHandler.updatesStarted
        }
        .onChange(of: locationsHandler.updatesStarted) {
            isRecording = locationsHandler.updatesStarted
        }
        
    }

}

#Preview {
    MotionStatusView(isShowSideMenu: .constant(false))
}


