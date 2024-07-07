//
//  LocationView.swift
//  Globulon
//
//  Created by David Holeman on 7/7/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import MapKit

struct LocationView: View {
    @Binding var isShowSideMenu: Bool
    
    @StateObject var locationHandler = LocationHandler.shared
    @StateObject private var activityHandler = ActivityHandler.shared
    @StateObject var networkHandler = NetworkHandler.shared
    
    @State var isShowHelp = false
    
    @State private var mapSpan: Double = 0.004
    private let mapSpanMinimum: Double = 0.002
    private let mapSpanIncrement: Double = 0.004
    
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
                        Text("Lat, Lng:")
                        Spacer()
                        Text("\(locationHandler.lastLocation.coordinate.latitude), \(locationHandler.lastLocation.coordinate.longitude)")
                    }
                }
                .padding()
                Divider()
                Spacer()
                
                /// Add stuff here...
                ///

                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    Marker("You", systemImage: "circle.circle", coordinate: CLLocationCoordinate2D(latitude: (locationHandler.lastLocation.coordinate.latitude), longitude: (locationHandler.lastLocation.coordinate.longitude)))
                }
                .onAppear {
                    updateCameraPosition()
                }
                .onChange(of: locationHandler.lastLocation) {
                    updateCameraPosition()
                }
                .padding()

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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if networkHandler.isConnected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowHelp.toggle()
                    }) {
                        Image(systemName: "questionmark")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(AppValues.pallet.primaryLight)
                            .frame(width: 35, height: 35)
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
            .fullScreenCover(isPresented: $isShowHelp) {
                NavigationView {
                    ArticlesSearchView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    isShowHelp.toggle()
                                }) {
                                    ImageNavCancel()
                                }
                            }
                            ToolbarItem(placement: .principal) {
                                Text("search")
                            }
                        }
                }
            }
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
    LocationView(isShowSideMenu: .constant(false))
}

