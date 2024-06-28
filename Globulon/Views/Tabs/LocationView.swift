//
//  LocationView.swift
//  Globulon
//
//  Created by David Holeman on 6/26/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import MapKit

struct LocationView: View {
    @Binding var isShowSideMenu: Bool
    
    @StateObject var locationsHandler = LocationsHandler.shared
    @StateObject private var activityHandler = ActivityHandler.shared
    @StateObject var networkManager = NetworkStatus.shared
    
    @State var isShowHelp = false
    
//    @State private var userPosition: MapCameraPosition = .userLocation(fallback: .automatic)
//    @State private var cameraPosition: MapCameraPosition = .automatic
    
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
                        Text("\(locationsHandler.lastLocation.coordinate.latitude), \(locationsHandler.lastLocation.coordinate.longitude)")
                    }
                }
                .padding()
                Divider()
                Spacer()
                
                /// Add stuff here...
                ///

                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    Marker("You", systemImage: "circle.circle", coordinate: CLLocationCoordinate2D(latitude: (locationsHandler.lastLocation.coordinate.latitude), longitude: (locationsHandler.lastLocation.coordinate.longitude)))
                }
                .onAppear {
                    updateCameraPosition()
                }
                .onChange(of: locationsHandler.lastLocation) {
                    updateCameraPosition()
                }

                
//                Map(position: $userPosition) {
//                    UserAnnotation()
//                }
                
//                Map(coordinateRegion: $locationsHandler.region)
                
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
                    if networkManager.isConnected {
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
    private func updateCameraPosition() {
        let location = CLLocationCoordinate2D(latitude: locationsHandler.lastLocation.coordinate.latitude,
                                              longitude: locationsHandler.lastLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
        cameraPosition = .region(region)
    }
}

#Preview {
    LocationView(isShowSideMenu: .constant(false))
}

