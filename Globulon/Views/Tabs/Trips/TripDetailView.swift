//
//  TripDetailView.swift
//  ViDrive
//
//  Created by David Holeman on 2/15/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import CoreLocation

struct TripDetailView: View {
    
    
    var trip: TripSummariesSD
    
    private var sortedTrip: [TripJournalSD] {
        trip.toTripJournal?.sorted { $0.timestamp < $1.timestamp } ?? []
    }
    
    @Environment(\.modelContext) private var modelContext
    
    /// Singlton access to LocationManager
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var address: String = ""
    @State private var addressOrigination: String = "pending ..."
    @State private var addressDestination: String = "pending ..."
    
    @State private var showDeleteConfirmation = false
    @State private var gpsEntryToDelete: GpsJournalSD? = nil
    @State private var tripJournalEntryToDelete: TripJournalSD? = nil
    
    @State var isShowMapLocationView = false
    @State var isShowMapView = false
    
    @State var latitude: Double
    @State var longitude: Double
    
    var body: some View {
        let timeDifference = Calendar.current.dateComponents([.minute], from: trip.originationTimestamp, to: trip.destinationTimestamp).minute ?? 0
        
        VStack {
            
            VStack {
                HStack {
                    Text("Start Time:")
                    Spacer()
                    Text("\(formatDateShortUS(trip.originationTimestamp))")
                }
                
                HStack {
                    Text("End Time:")
                    
                    Spacer()
                    Text("\(formatDateShortUS(trip.destinationTimestamp))")
                }
                HStack {
                    Text("Duration:")
                    
                    Spacer()
                    Text("\(timeDifference) Minutes")
                }
            }
            .padding()
            .padding(.bottom,-16)
            .font(.system(size: 14, design: .monospaced))
            /*
            VStack {
                HStack {
                    Text("Start Location:")
                    Spacer()
                    Text("\(trip.originationLatitude), \(trip.originationLongitude)")
                }
                HStack {
                    Text("End Location:")
                    Spacer()
                    Text("\(trip.destinationLatitude), \(trip.destinationLongitude)")
                }
            }
            .padding()
            .padding(.bottom, -16)
            .font(.system(size: 14, design: .monospaced))
            */
            
            VStack {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Address:")
                            Text("\(trip.originationAddress)")
                                .padding(.leading)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .padding()
                        Spacer()
                    }
                    .padding(.bottom, -32)
                    .font(.system(size: 14, design: .monospaced))
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("End Address:")
                        Text("\(trip.destinationAddress)")
                            .padding(.leading)
                            .font(.system(size: 11, design: .monospaced))
                        
                    }
                    .padding()
                    Spacer()
                }
                .padding(.bottom, -16)
                .font(.system(size: 14, design: .monospaced))
            }
            /*
            .task {
                /*  TODO: keep for reference if we want to get from location manager vs. other source.
                addressOrigination = await locationManager.getAddressFromLatLon(latitude: trip.originationLatitude, longitude: trip.originationLongitude)
                addressDestination = await locationManager.getAddressFromLatLon(latitude: trip.destinationLatitude, longitude: trip.destinationLongitude)
                 */
                addressOrigination = await locationManager.getFullAddressFromLatLon(latitude: trip.originationLatitude, longitude: trip.originationLongitude)
                addressDestination = await locationManager.getFullAddressFromLatLon(latitude: trip.destinationLatitude, longitude: trip.destinationLongitude)
                
                /*
                let AddressOrigination = await Address.getFullAddressFromLatLon(latitude: trip.originationLatitude, longitude: trip.originationLongitude)
                let AddressDestination = await Address.getFullAddressFromLatLon(latitude: trip.destinationLatitude, longitude: trip.destinationLongitude)
                 */
            }
             */
            
            /*
            VStack {
                HStack {
                    Text("Max speed:")
                    Spacer()
                    Text("\(formatMPH(convertMPStoMPH(trip.maxSpeed))) MPH")
                }
                HStack {
                    Text("Smoothness:")
                    Spacer()
                    Text("\(Int(trip.scoreSmoothness))")
                }
                HStack {
                    Text("Braking:")
                    Spacer()
                    Text("\(Int(trip.scoreDeceleration))")
                }
                HStack {
                    Text("Acceleration:")
                    Spacer()
                    Text("\(Int(trip.scoreAcceleration))")
                }
                
            }
            .padding()
            .padding(.bottom, -16)
            .font(.system(size: 14, design: .monospaced))
            */
            
            MapTripSnapshotView(tripTimestamp: trip.originationTimestamp)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.bottom, -8)
                .onTapGesture {
                    isShowMapView = true
                }
                .fullScreenCover(isPresented: $isShowMapView, content: {
                    MapTripView(tripTimestamp: trip.originationTimestamp)
                })
            
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("GPS count:")
                        Spacer()
                        Text("\(trip.toTripJournal?.count ?? 0)")
                        
                    }
                    .font(.system(size: 14, design: .monospaced))
                    .padding(.trailing, 8)
                    HStack {
                        Text("GPS Data:")
                            .font(.system(size: 14, design: .monospaced))
                        Spacer()
                    }

                    List {
                        ForEach(sortedTrip, id: \.self) { detail in
                            Text("\(formatDateStampA(detail.timestamp))  \(formatMPH(convertMPStoMPH(detail.speed)))/mph \(detail.note)")
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        print("** deleting: \(detail.timestamp)")
                                        //deleteTripJournalEntry()
                                        //originationTimestamp = trip.originationTimestamp
                                        //showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        latitude = detail.latitude
                                        longitude = detail.longitude
                                        isShowMapLocationView.toggle()
                                    } label: {
                                        Label("Map", systemImage: "map")
                                    }
                                    .tint(.green)
                                }
                                .fullScreenCover(isPresented: $isShowMapLocationView) {
                                    NavigationView {
                                        MapTripLocationView(latitude: detail.latitude, longitude: detail.longitude)
                                    }
                                }
                        }

                        //.onDelete(perform: deleteTripJournalEntry)
                        .listStyle(PlainListStyle())
                        .font(.system(size: 10, design: .monospaced))
                    }
                    .listStyle(.plain)
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete GPS Entry"),
                            message: Text("Are you sure you want to delete this entry?"),
                            primaryButton: .destructive(Text("Delete")) {
                                performDeleteTripJournalEntry(trip: tripJournalEntryToDelete!)
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                }
                
                
            }
            .padding()
            .padding(.trailing, -8)
            Spacer()
        }
        .padding(.bottom, -16)
        
        Spacer()
    }
    //.padding()
    //.navigationBarTitle("Trip Detail", displayMode: .inline)
    
    
    private func deleteTripJournalEntry(at offsets: IndexSet) {
        offsets.forEach { index in
            
            /// Use 'sortedTrip' instead of directly accessing 'trip.toTripJournal'
            let entry = sortedTrip[index]
            
            print("index: \(index)")
            print("item :  \(entry.timestamp)")
            
            tripJournalEntryToDelete = entry
            showDeleteConfirmation = true   
        }
    }
    
    private func performDeleteTripJournalEntry(trip: TripJournalSD) {
        print("entry to delete: \(trip.timestamp)")
        
        modelContext.delete(trip)
        do {
            try modelContext.save()
        } catch {
            /// Handle the error, e.g., show an alert to the user
            LogEvent.print(module: "TripDetailView:performDeteTripJournalEntry()", message: "Error savign context after deleting a trip: \(error)")
        }
    }
    
}


#Preview {
    TripDetailView(trip: TripSummariesSD(originationTimestamp: Date(), originationLatitude: 37.334948, originationLongitude: -122.032921, originationAddress: "", destinationTimestamp: Date() + 300, destinationLatitude: 37.334526, destinationLongitude: -122.037833, destinationAddress: "", maxSpeed: 35.0, duration: 2.0, distance: 1.5, scoreAcceleration: 100.0, scoreDeceleration: 100.0, scoreSmoothness: 90.0, archived: false),latitude: 37.334526, longitude: -122.037833)
    
}

