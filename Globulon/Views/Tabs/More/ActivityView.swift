//
//  ActivityView.swift
//  Globulon
//
//  Created by David Holeman on 3/4/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import MapKit
import SceneKit
import Charts

struct ActivityView: View {
    //@Binding var isShowSideMenu: Bool
    
    @StateObject var locationManager = LocationManager.shared
    @StateObject var activityManager = ActivityManager.shared
    @StateObject var networkManager = NetworkManager.shared
    
    @State var isShowHelp = false
    @State private var isRecording = false
    
    @State private var mapSpan: Double = 0.0001
    private let mapSpanMinimum: Double = 0.00005
    private let mapSpanIncrement: Double = 0.0001
    
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    ))

    var body: some View {
        // Top menu
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Lat/Lng:")
                        Spacer()
                        Text("\(locationManager.lastLocation.coordinate.latitude), \(locationManager.lastLocation.coordinate.longitude)")
                    }
                    HStack {
                        Text("Speed:")
                        Spacer()
                        Text("\(formatMPH(convertMPStoMPH(locationManager.lastSpeed), decimalPoints: 2)) mph")
                    }
                }
                .font(.system(size: 12, design: .monospaced))
                .padding()
                
                Divider()
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("State:")
                        Spacer()
                        if self.locationManager.isMoving {
                            Text("Moving")
                                .foregroundColor(.green)
                        } else {
                            Text("Static")
                                .foregroundColor(.red)
                        }
                    }
                    HStack {
                        Text("Mode:")
                        Spacer()
                        Text(self.locationManager.activityState.rawValue)
                            .foregroundColor(modeColor(for: locationManager.activityState))

                    }
                    HStack {
                        Text("Activity:")
                        Spacer()
                        Text(self.activityManager.activityState.rawValue)
                            .foregroundColor(activityColor(for: activityManager.activityState))

                    }
                }
                .font(.system(size: 12, design: .monospaced))
                .padding(.leading, 16)
                .padding(.trailing, 16)
                
                /// MAP
                ///
                VStack {
                    
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                        Marker("You", systemImage: "circle.circle", coordinate: CLLocationCoordinate2D(latitude: (locationManager.lastLocation.coordinate.latitude), longitude: (locationManager.lastLocation.coordinate.longitude)))
                    }
                    .onAppear {
                        updateCameraPosition()
                    }
                    .onChange(of: locationManager.lastLocation) {
                        updateCameraPosition()
                    }
                    .frame(height: 200)
                    .padding()
                    
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
                    .padding(.bottom, 32)
                }
 
                List {
                    ForEach(activityManager.activityDataBuffer, id: \.self) { detail in
                        Text("\(formatDateStampA(detail.timestamp)) \(detail.note)")
                    }
                }
                .onAppear {
                    /// This is how/when one could ask for permission
                    CLLocationManager().requestWhenInUseAuthorization()
                }
                .frame(height: 250)
                .listStyle(.plain)
                .font(.system(size: 12, design: .monospaced))

                Spacer()
            }
        }
        .navigationBarTitle("Activity")
    }
    
    func updateCameraPosition() {
        let location = CLLocationCoordinate2D(latitude: locationManager.lastLocation.coordinate.latitude,
                                              longitude: locationManager.lastLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: mapSpan, longitudeDelta: mapSpan))
        cameraPosition = .region(region)
    }
    
    /// Helper function to change text color based on activity state
    private func modeColor(for state: LocationManager.ActivityState) -> Color {
        switch state {
        case .stationary: return .gray
        case .walking: return .green
        case .running: return .orange
        case .driving: return .red
        case .unknown: return .black
        }
    }
    /// Helper function to change text color based on activity state
    private func activityColor(for state: ActivityManager.ActivityState) -> Color {
        switch state {
        case .stationary: return .gray
        case .walking: return .green
        case .running: return .orange
        case .driving: return .red
        case .unknown: return .black
        }
    }
    
    // MARK: dd/mm/yy hh:mm:ss am/pm
    func formatDateStampA(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-YY hh:mm:ss a"
        return formatter.string(from: date)
    }
}


#Preview {
    //ActivityView(isShowSideMenu: .constant(false))
    ActivityView()
}

