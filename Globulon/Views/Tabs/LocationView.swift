//
//  LocationView.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftUI
import MapKit

struct LocationView: View {
    @Binding var isShowSideMenu: Bool
    
    @StateObject var locationHandler = LocationHandler.shared
    @StateObject var networkHandler = NetworkHandler.shared
    
    @State var isShowHelp = false
    
    @State private var mapSpan: Double = 0.003
    private let mapSpanMinimum: Double = 0.002
    private let mapSpanIncrement: Double = 0.002
    
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    ))

    var body: some View {
        // Top menu
        NavigationStack {
            VStack() {
                
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
                
                Spacer()
                
                VStack {
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                        Marker("You", systemImage: "circle.circle", coordinate: CLLocationCoordinate2D(latitude: (locationHandler.lastLocation.coordinate.latitude), longitude: (locationHandler.lastLocation.coordinate.longitude)))
                    }
                    .onAppear {
                        updateCameraPosition()
                    }
                    .onChange(of: locationHandler.lastLocation) {
                        updateCameraPosition()
                    }
                }
 

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
                
                ///  This is how/when one could ask for permission
                .onAppear {
                    CLLocationManager().requestWhenInUseAuthorization()
                }
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        
    }
    
    func updateCameraPosition() {
        let location = CLLocationCoordinate2D(latitude: locationHandler.lastLocation.coordinate.latitude,
                                              longitude: locationHandler.lastLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: mapSpan, longitudeDelta: mapSpan))
        cameraPosition = .region(region)
    }
}

#Preview {
    LocationView(isShowSideMenu: .constant(false))
}

