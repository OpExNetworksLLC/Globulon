//
//  HistoryMapTripView.swift
//  ViDrive
//
//  Created by David Holeman on 5/6/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import MapKit


struct HistoryMapTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var tripTimestamp: Date?
    
    @State private var mapCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    @Query(sort: \TripHistoryTripsSD.originationTimestamp, order: .forward) private var tripHistoryTripsSD: [TripHistoryTripsSD]
    
    @State private var coordinatesArray: [CLLocationCoordinate2D] = []
    
    var firstFilteredTrip: TripHistoryTripsSD? {
        return tripHistoryTripsSD.first { tripSummary in
            return tripSummary.originationTimestamp == tripTimestamp
        }
    }
    
    var body: some View {
        
        NavigationView {
            VStack(alignment: .leading) {
                
                VStack {

                    HStack {
                        Text("Start Time:")
                        Spacer()
                        Text("\(formatDateShortUS(firstFilteredTrip?.originationTimestamp ?? Date()))")
                    }
                    
                    HStack {
                        Text("End Time:")
                        
                        Spacer()
                        Text("\(formatDateShortUS(firstFilteredTrip?.destinationTimestamp ?? Date()))")
                    }
                    HStack {
                        Text("Distance & Duration:")
                        
                        Spacer()
                        Text("\(String(format: "%.1f", firstFilteredTrip?.distance ?? 0)) mi")
                            .padding(.trailing, 4)
                        Text("\(formatMMtoHHMM(minutes: firstFilteredTrip?.duration ?? 0))")
                    }
                }
                .font(.system(size: 14))

                Map(interactionModes: [.pan,.zoom]) {
                    
                    Marker("start", systemImage: "circle", coordinate: CLLocationCoordinate2D(latitude: (firstFilteredTrip?.originationLatitude ?? 0.0), longitude: (firstFilteredTrip?.originationLongitude ?? 0.0)))
                        .tint(.green)
                    Marker("end", systemImage: "star",coordinate: CLLocationCoordinate2D(latitude: (firstFilteredTrip?.destinationLatitude ?? 0.0), longitude: (firstFilteredTrip?.destinationLongitude ?? 0.0)))
                        .tint(.red)
                    
                    MapPolyline(coordinates: coordinatesArray)
                        .mapOverlayLevel(level: .aboveLabels)
                        .stroke(.blue, lineWidth: 5)
                    
                }
                Spacer()
            }
            .foregroundColor(.primary)
            .navigationBarTitle("HistoryMapTripView")
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
                coordinatesArray.removeAll()
                if let journals = firstFilteredTrip?.toTripHistoryTripJournal {
                    // Sort the journals by timestamp in ascending order
                    let sortedJournals = journals.sorted { $0.timestamp < $1.timestamp }

                    for location in sortedJournals {
                        coordinatesArray.append(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                    }
                }
            }
        }
    }

}

#Preview {
    HistoryMapTripView(tripTimestamp: convertToDateISO8601(from: "2024-03-13T14:26:45Z"))
}
