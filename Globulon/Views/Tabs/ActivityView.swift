//
//  ActivityView.swift
//  Globulon
//
//  Created by David Holeman on 7/16/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # ActivityView
/// Show live activity information
///
/// # Version History
/// ### 0.1.0.66
/// # - Created
/// # - *Date*: 07/16/24

import SwiftUI
import MapKit

struct ActivityView: View {
    
    @Binding var isShowSideMenu: Bool
    
    @ObservedObject var locationHandler = LocationHandler.shared
    @ObservedObject var activityHandler = ActivityHandler.shared
    
    @State private var isShowHelp = false
    @State private var isRecording = false
    
    @State private var mapSpan: Double = 0.0001
    private let mapSpanMinimum: Double = 0.00005
    private let mapSpanIncrement: Double = 0.0005
    
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
                    HStack {
                        Text("Speed:")
                        Spacer()
                        Text("\(formatMPH(convertMPStoMPH(locationHandler.lastSpeed), decimalPoints: 2)) mph")
                    }
                }
                .padding()
                Divider()
                VStack(alignment: .leading) {
                    HStack {
                        Text("Activity/State:")
                        Spacer()
                        Text("\(activityHandler.isActivity ? "active" : "inactive") / \(activityHandler.activityState)")
                    }
                    HStack {
                        Text("State:")
                        Spacer()
                        Text("Moving")
                            .foregroundColor(self.locationHandler.isMoving ? .green : .red)
                    }
                    HStack {
                        Text("Mode:")
                        Spacer()
                        Text(self.locationHandler.isWalking ? "Walking" : "")
                            .foregroundColor(self.locationHandler.isWalking ? .green : .red)
                        Text(self.locationHandler.isDriving ? "Driving" : "")
                            .foregroundColor(self.locationHandler.isDriving ? .green : .red)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 16)
                
                Spacer()

                VStack {
                    // (Other UI components)
                    
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
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button("Zoom in") {
                            /// Ensure mapSpan does not go lower than mapSpanIncrement
                            if mapSpan > mapSpanIncrement {
                                mapSpan -= mapSpanIncrement
                            } else {
                                mapSpan = mapSpanMinimum
                            }
                            updateCameraPosition()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    
                    List {
                        ForEach(activityHandler.activityDataBuffer, id: \.self) { detail in
                            Text("\(formatDateStampMSSS(detail.timestamp))  \(formatMPH(convertMPStoMPH(detail.speed), decimalPoints: 2)) mph\n\(detail.note)")
                        }
                    }
                    .listStyle(.plain)
                    
                    Button(self.locationHandler.backgroundActivity ? "Stop BG Activity Session" : "Start BG Activity Session") {
                        self.locationHandler.backgroundActivity.toggle()
                    }
                    .buttonStyle(.bordered)
                    
                }

                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isShowSideMenu.toggle()
                    }) {
                        Image(systemName: "square.leftthird.inset.filled")
                            .font(.system(size: 26, weight: .ultraLight))
                            .frame(width: 35, height: 35)
                            .foregroundColor(AppValues.pallet.primaryLight)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if activityHandler.isActivityMonitoringOn {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                    } else {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
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
                    }
                }
                
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
    ActivityView(isShowSideMenu: .constant(false))
}
