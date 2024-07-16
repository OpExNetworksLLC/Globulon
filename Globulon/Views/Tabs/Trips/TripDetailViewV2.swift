//
//  TripDetailViewV2.swift
//  Globulon
//
//  Created by David Holeman on 4/24/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # TripDetailViewV3
/// Display trip details
///
/// # Version History
/// ### 0.1.0.64
/// # - cleaned up toolbar and toolbar items
/// # - *Date*: 07/15/24

import SwiftUI
import SwiftData
import MapKit

struct TripDetailViewV2: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var tripTimestamp: Date?
    
    @State private var mapCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    
    @Query(sort: \TripSummariesSD.originationTimestamp, order: .forward) private var tripSummariesSD: [TripSummariesSD]
    
    @StateObject private var tripManager = TripManager()
    
    @State private var coordinatesArray: [CLLocationCoordinate2D] = []
    
    @State var isShowMapView = false
    @State var isShowMapTripView = false
    @State var isShowMapLocationView = false
    @State var isShowDeleteConfirmation = false
    
    @State private var showDeleteConfirmation = false
    @State private var showExportCompletion: Bool = false
    
    var firstFilteredTrip: TripSummariesSD? {
        return tripSummariesSD.first { tripSummary in
            return tripSummary.originationTimestamp == tripTimestamp
        }
    }
    
    private var sortedTrip: [TripJournalSD] {
        firstFilteredTrip?.toTripJournal?.sorted { $0.timestamp < $1.timestamp } ?? []
    }
    
    
    var body: some View {
        
        NavigationView {
            VStack {
                
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
                .padding()
                .padding(.bottom, -16)
                .font(.system(size: 14))
                
                
                VStack {
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Start Address:")
                                Text("\(firstFilteredTrip?.originationAddress ?? "n/a")")
                                    .padding(.leading)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                            }
                            .padding()
                            Spacer()
                        }
                        .padding(.bottom, -32)
                        .font(.system(size: 14))
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("End Address:")
                            Text("\(firstFilteredTrip?.destinationAddress ?? "n/a")")
                                .padding(.leading)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            
                        }
                        .padding()
                        Spacer()
                    }
                    .padding(.bottom, -16)
                    .font(.system(size: 14))
                }
                .padding(.bottom, 16)
                
                MapTripSnapshotView(tripTimestamp: firstFilteredTrip?.originationTimestamp)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, -16)
                    .onTapGesture {
                        /// Do stuff
                        tripManager.originationTimestamp = firstFilteredTrip?.originationTimestamp
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isShowMapTripView.toggle()
                        }
                    }
                    .padding(.bottom, 8)
    
                
                HStack {
                    VStack {
                        CircularScoreView(score: Int(firstFilteredTrip?.scoreAcceleration ?? 00))
                            .frame(width: 42, height: 42)
                        Text("Accel")
                    }
                    VStack {
                        CircularScoreView(score: Int(firstFilteredTrip?.scoreDeceleration ?? 0))
                            .frame(width: 42, height: 42)
                        Text("Decel")
                    }
                    VStack {
                        CircularScoreView(score: Int(firstFilteredTrip?.scoreSmoothness ?? 0))
                            .frame(width: 42, height: 42)
                        Text("Smooth")
                    }
                    VStack {
                        Text("\(formatMPH(convertMPStoMPH((firstFilteredTrip?.maxSpeed) ?? 0))) mph")
                            .frame(width: 96, height: 42)
                        Text("Max")
                    }
                    Spacer()
                }
                .font(.system(size: 14))
                .padding(.leading, 16)
                
                /// Action buttons
                /// 
                HStack{
                    Text(firstFilteredTrip?.archived ?? false ? "Saved" : "Unsaved")
                        .padding(.leading, 16)
                    Spacer()
                    
                    /// EXPORT Trip
                    ///
                    Button {
                        tripManager.originationTimestamp = firstFilteredTrip?.originationTimestamp
                        _ = exportTripData(tripTimestamp: firstFilteredTrip!.originationTimestamp)
                        showExportCompletion = true

                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            .frame(width: 100, height: 32)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 5,
                                    style: .continuous
                                )
                                .stroke(.blue, lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 8)
                    
                    /// MAP
                    ///
                    Button(action: {
                        /// Do stuff
                        tripManager.originationTimestamp = firstFilteredTrip?.originationTimestamp
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isShowMapTripView.toggle()
                        }
                    }) {
                        Label("Map", systemImage: "map")
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            .frame(width: 100, height: 32)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 5,
                                    style: .continuous
                                )
                                .stroke(.blue, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 8)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("GPS count:")
                            Spacer()
                            Text("\(firstFilteredTrip?.toTripJournal?.count ?? 0)")
                            
                        }
                        .font(.system(size: 14))
                        .padding(.trailing, 8)
                        
                        HStack {
                            Text("GPS Data:")
                                .font(.system(size: 14))
                            Spacer()
                        }

                        List {
                            ForEach(sortedTrip, id: \.self) { detail in
                                Text("\(formatDateStampA(detail.timestamp))  \(formatMPH(convertMPStoMPH(detail.speed)))/mph \(detail.note)")                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            tripManager.originationTimestamp = tripTimestamp
                                            tripManager.journalEntryTimestamp = detail.timestamp
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                isShowDeleteConfirmation.toggle()
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            tripManager.latitude = detail.latitude
                                            tripManager.longitude = detail.longitude
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                isShowMapLocationView.toggle()
                                            }
                                        } label: {
                                            Label("Map", systemImage: "map")
                                        }
                                        .tint(.green)
                                    }
                            }

                            //.onDelete(perform: deleteTripJournalEntry)
                            .listStyle(PlainListStyle())
                            .font(.system(size: 10, design: .monospaced))
                        }
                        .listStyle(.plain)
                        
                        .fullScreenCover(isPresented: $isShowMapLocationView) {
                            MapTripLocationView(latitude: tripManager.latitude ?? 0.0, longitude: tripManager.longitude ?? 0.0)
                        }
                        
                        .alert(isPresented: $isShowDeleteConfirmation) {
                            Alert(
                                title: Text("Delete GPS Entry"),
                                message: Text("Are you sure you want to delete this entry?\n \(formatDateStampA(tripManager.originationTimestamp!))"),
                                primaryButton: .destructive(Text("Delete")) {
                                    
                                    /// Try to delete the entry
                                    _ = deleteTripGPSJournalEntry(tripTimestamp: tripManager.originationTimestamp!, journalEntryTimestamp: tripManager.journalEntryTimestamp!)
                                    
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
            
            .fullScreenCover(isPresented: $isShowMapTripView) {
                //MapTripView(tripTimestamp: originationTimestamp)
                if let timestamp = tripManager.originationTimestamp {
                    MapTripView(tripTimestamp: timestamp)
                } else {
                    Text("No trip data available.")
                }
            }
            
            .foregroundColor(.primary)
            .navigationBarTitle("Trip Details V2")
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
        }
        .navigationBarBackButtonHidden(true)  // Hide the back button since we account for that

        
        Spacer()
    }
        
}

#Preview {
    TripDetailViewV2(tripTimestamp: Date())
}
