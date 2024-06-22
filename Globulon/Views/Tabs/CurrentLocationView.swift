//
//  CurrentLocationView.swift
//  ViDrive
//
//  Created by David Holeman on 2/15/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import MapKit

struct CurrentLocationView: View {
    @Binding var isShowSideMenu: Bool
    
    @State private var userPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        
        // Top menu
        VStack(spacing: 0) {

            VStack(alignment: .leading) {
                HStack {
                    Text("Lat/Lng:")
                    Spacer()
                    Text("\(CLLocationManager().location?.coordinate.latitude ?? 0.0), \(CLLocationManager().location?.coordinate.longitude ?? 0.0)")
                }
            }
            .padding()

            Map(position: $userPosition) {
                UserAnnotation()
            }
            
            ///  This is how/when one could ask for permission
            .onAppear {
                CLLocationManager().requestWhenInUseAuthorization()
            }
            

            Spacer()
            

        }
    }
}

#Preview {
    CurrentLocationView(isShowSideMenu: .constant(false))
}
