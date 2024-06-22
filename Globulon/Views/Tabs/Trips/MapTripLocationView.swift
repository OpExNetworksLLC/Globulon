//
//  MapTripLocationView.swift
//  ViDrive
//
//  Created by David Holeman on 4/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//


import SwiftUI
import SwiftData
import MapKit


struct MapTripLocationView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var latitude: Double
    var longitude: Double
    
    @State private var cameraPosition: MapCameraPosition = .automatic

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude

        /// Initialize the camera position with the provided coordinates
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        _cameraPosition = State(initialValue: .camera(
            MapCamera(centerCoordinate: coordinate, distance: 600)
        ))
    }

    var body: some View {
        
        NavigationView {
            VStack(alignment: .leading) {

                VStack(alignment: .leading) {
                    HStack {
                        Text("Lat/Lng:")
                        Spacer()
                        Text("\(latitude), \(longitude)")
                    }
                }
                .padding()
                
                Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                    Marker("Location", coordinate: CLLocationCoordinate2D(latitude: (latitude), longitude: (longitude)))
                }
                Spacer()
            }
            .foregroundColor(.primary)
            .navigationBarTitle("Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        ImageNavCancel()
                    }
                }
            })
            .onAppear {
            }
        }
    }

}

#Preview {
    MapTripLocationView(latitude: 37.81943, longitude: -121.98545)
}
