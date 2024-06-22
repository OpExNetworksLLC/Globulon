//
//  MapTripSnapshotView.swift
//  ViDrive
//
//  Created by David Holeman on 4/12/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import MapKit


struct MapTripSnapshotView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var tripTimestamp: Date?
    
    //@State private var mapCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    @Query(sort: \TripSummariesSD.originationTimestamp, order: .forward) private var tripSummariesSD: [TripSummariesSD]
    
    @State private var coordinatesArray: [CLLocationCoordinate2D] = []

    var firstFilteredTrip: TripSummariesSD? {
        return tripSummariesSD.first { tripSummary in
            return tripSummary.originationTimestamp == tripTimestamp
        }
    }
    
    var body: some View {
        
        NavigationView {
            VStack(alignment: .leading) {

                Map(interactionModes: []) {
                    
                    Marker("start", systemImage: "circle", coordinate: CLLocationCoordinate2D(latitude: (firstFilteredTrip?.originationLatitude ?? 0.0), longitude: (firstFilteredTrip?.originationLongitude ?? 0.0)))
                        .tint(.green)
                    Marker("end", systemImage: "star", coordinate: CLLocationCoordinate2D(latitude: (firstFilteredTrip?.destinationLatitude ?? 0.0), longitude: (firstFilteredTrip?.destinationLongitude ?? 0.0)))
                        .tint(.red)
                    
                    MapPolyline(coordinates: coordinatesArray)
                        .mapOverlayLevel(level: .aboveLabels)
                        .stroke(.blue, lineWidth: 5)
                    
                }
                Spacer()
            }
            .onAppear {
                coordinatesArray.removeAll()
                if let journals = firstFilteredTrip?.toTripJournal {
                    // Sort the journals by timestamp in ascending order
                    let sortedJournals = journals.sorted { $0.timestamp < $1.timestamp }

                    for location in sortedJournals {
                        print("** \(location.timestamp) \(location.latitude) \(location.longitude)")
                        coordinatesArray.append(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                    }
                }
            }
        }
    }

}

#Preview {
    MapTripSnapshotView(tripTimestamp: convertToDateISO8601(from: "2024-03-13T14:26:45Z"))
}
