//
//  HistoryMapSnapshotView.swift
//  ViDrive
//
//  Created by David Holeman on 5/6/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import MapKit


struct HistoryMapTripSnapshotView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var tripTimestamp: Date?
    
    //@State private var mapCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    
    @Query(sort: \TripHistoryTripsSD.originationTimestamp, order: .forward) private var tripHistoryTripsSD: [TripHistoryTripsSD]
    
    @State private var coordinatesArray: [CLLocationCoordinate2D] = []
    
    var firstFilteredTrip: TripHistoryTripsSD? {
        return tripHistoryTripsSD.first { tripSummary in
            return tripSummary.originationTimestamp == tripTimestamp
        }
    }
    
    private var sortedTrip: [TripHistoryTripJournalSD] {
        firstFilteredTrip?.toTripHistoryTripJournal?.sorted {$0.timestamp < $1.timestamp } ?? []
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
                    
//                    MapPolyline(coordinates: firstFilteredTrip!.sortedCoordinates)
//                        .mapOverlayLevel(level: .aboveLabels)
//                        .stroke(.blue, lineWidth: 5)
                    
                }
                Spacer()
            }
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
    HistoryMapTripSnapshotView(tripTimestamp: convertToDateISO8601(from: "2024-03-13T14:26:45Z"))
}

