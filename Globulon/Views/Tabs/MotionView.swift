//
//  MotionView.swift
//  Globulon
//
//  Created by David Holeman on 6/28/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import MapKit

struct MotionView: View {
    
    @Binding var isShowSideMenu: Bool
    
    @ObservedObject var locationHandler = LocationHandler.shared
    @StateObject private var activityHandler = ActivityHandler.shared

    @State private var isShowHelp = false
    @State private var isRecording = false
    
    @State private var mapSpan: Double = 0.00005
    private let mapSpanIncrement: Double = 0.00005
    
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    ))

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Lat/Lng:")
                        Spacer()
                        Text("\(locationHandler.lastLocation.coordinate.latitude), \(locationHandler.lastLocation.coordinate.longitude)")
                    }
                }
                .padding()
                Divider()
                Spacer()

                VStack {
                    // (Other UI components)
                    
                    Spacer().frame(height: 16)
                    VStack() {
                        HStack(){
                            VStack() {
                                Text("moving")
                                Rectangle()
                                    .fill(self.locationHandler.isMoving ? .green : .red)
                                    .frame(width: 75, height: 75, alignment: .center)
                            }
                            VStack() {
                                Text("walking")
                                Rectangle()
                                    .fill(self.locationHandler.isWalking ? .green : .red)
                                    .frame(width: 75, height: 75, alignment: .center)
                            }
                            VStack() {
                                Text("driving")
                                Rectangle()
                                    .fill(self.locationHandler.isDriving ? .green : .red)
                                    .frame(width: 75, height: 75, alignment: .center)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    
                    Text("activity: \(activityHandler.isActivity)  state: \(activityHandler.activityState)")
                    
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                        Marker("You", systemImage: "circle.circle", coordinate: CLLocationCoordinate2D(latitude: (locationHandler.siftLocation.coordinate.latitude), longitude: (locationHandler.siftLocation.coordinate.longitude)))
                    }
                    .onAppear {
                        updateCameraPosition()
                    }
                    .onChange(of: locationHandler.lastLocation) {
                        updateCameraPosition()
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    
                    Spacer()
                    HStack() {
                        Button("Zoom Out") {
                            self.mapSpan += mapSpanIncrement
                            updateCameraPosition()
                            print("[glo \(self.mapSpan)]")
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button("Zoom in") {
                            /// Ensure mapSpan does not go lower than mapSpanIncrement
                            if mapSpan > mapSpanIncrement {
                                mapSpan -= mapSpanIncrement
                            } else {
                                mapSpan = mapSpanIncrement
                            }
                            updateCameraPosition()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    
                    Button(self.locationHandler.backgroundActivity ? "Stop BG Activity Session" : "Start BG Activity Session") {
                        self.locationHandler.backgroundActivity.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            
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
                    locationHandler.startLocationUpdates()
                } else {
                    locationHandler.stopLocationUpdates()
                }
            }) {
                if isRecording {
                    Image(systemName: "record.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color.red)
                        .frame(width: 35, height: 35)
                    Text("recording")
                        .foregroundColor(Color.red)

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
            isRecording = locationHandler.updatesStarted
        }
        .onChange(of: locationHandler.updatesStarted) {
            isRecording = locationHandler.updatesStarted
        }
    }
    
    func updateCameraPosition() {
        let location = CLLocationCoordinate2D(latitude: locationHandler.siftLocation.coordinate.latitude,
                                              longitude: locationHandler.siftLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: mapSpan, longitudeDelta: mapSpan))
        cameraPosition = .region(region)
    }
}



#Preview {
    MotionView(isShowSideMenu: .constant(false))
}
