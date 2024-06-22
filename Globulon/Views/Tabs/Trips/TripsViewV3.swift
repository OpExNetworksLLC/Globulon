//
//  TripsViewV3.swift
//  ZenTrac
//
//  Created by David Holeman on 4/23/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import MapKit

struct TripsViewV3: View {
    
    @Binding var isShowSideMenu: Bool
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(
    ) private var gpsJournalSD: [GpsJournalSD]
    
    @Query(sort: \TripSummariesSD.originationTimestamp, order: .forward) private var tripSummariesSD: [TripSummariesSD]
    
    @StateObject private var tripManager = TripManager()
    
    @State private var tripList: [TripSummariesSD] = []
    
    @State var isShowHelp = false
    @State var isProcessing = false
    @State var isShowMapTripView = false
    @State var isShowTripDetailsView = false
    
    @State var showAlertDedupSuccess: Bool = false
    @State var showAlertDedupMessage: String = ""
    
    @State var showExportCompletion: Bool = false
    @State private var showDeleteConfirmation = false
    @State private var showSaveTripConfirmation = false
    
    @State var originationTimestamp: Date = Date()
    
    @State private var tripToDelete: TripSummariesSD? = nil
    
    @State private var coordinatesArray: [CLLocationCoordinate2D] = []
        
    var body: some View {
        NavigationStack {
            VStack {
                
                Spacer().frame(height: 24)
                
                /// Show progress spinner when processing trips
                ///
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.75)
                        .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                        .padding()
                }
                
                /// List the trips.
                ///
                List {
                    ForEach(tripSummariesSD.sorted(by: { $0.originationTimestamp > $1.originationTimestamp }) , id: \.self) { trip in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("\(formatDateStampDayMonth(trip.originationTimestamp))")
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(String(format: "%.1f", trip.distance)) mi")
                                    .fontWeight(.bold)
                                    .padding(.trailing, 4)
                                Text("\(formatMMtoHHMM(minutes: trip.duration))")
                                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            }
                            .padding(.bottom, 1)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("fr: \(trip.originationAddress)")
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(formatDateStampTime(trip.originationTimestamp))")
                                        .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                                }
                                HStack {
                                    Text("to: \(trip.destinationAddress)")
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(formatDateStampTime(trip.destinationTimestamp))")
                                        .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                                }
                            }
                            .font(.system(size: 14))
                            .padding(.trailing, -16)
                            
                            Map(interactionModes: []) {
                                
                                Marker("start", systemImage: "circle", coordinate: CLLocationCoordinate2D(latitude: (trip.originationLatitude), longitude: (trip.originationLongitude)))
                                    .tint(.green)
                                Marker("end", systemImage: "star", coordinate: CLLocationCoordinate2D(latitude: (trip.destinationLatitude), longitude: (trip.destinationLongitude)))
                                    .tint(.red)
                                
                                MapPolyline(coordinates: trip.sortedCoordinates)
                                    .mapOverlayLevel(level: .aboveLabels)
                                    .stroke(.blue, lineWidth: 5)
                            }
                            .frame(height: 200)
                            .onTapGesture {
                                tripManager.originationTimestamp = trip.originationTimestamp
                                isShowMapTripView.toggle()
                            }
                            
                            /// SCORES & Actions
                            ///
                            HStack {
                                
                                /// Acceleration
                                ///
                                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                    Circle().fill(scoreTripColor(trip.scoreAcceleration)).frame(width: 32, height: 32)
                                        .overlay(
                                            Text("Ac") // Display the progress value as a percentage
                                                .font(.caption)
                                                .foregroundColor(.black)
                                        )
                                })
                                
                                /// Deceleration
                                ///
                                Button(action: {}, label: {
                                    Circle().fill(scoreTripColor(trip.scoreDeceleration)).frame(width: 32, height: 32)
                                        .overlay(
                                            Text("De") // Display the progress value as a percentage
                                                .font(.caption)
                                                .foregroundColor(.black)
                                        )
                                    
                                })
                                
                                /// Smoothness
                                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                    Circle().fill(scoreTripColor(trip.scoreSmoothness)).frame(width: 32, height: 32)
                                        .overlay(
                                            Text("Sm") // Display the progress value as a percentage
                                                .font(.caption)
                                                .foregroundColor(.black)
                                        )
                                    
                                })
                                
                                Spacer()
                                
                                /// DELETE Trip
                                ///
                                Button(role: .destructive) {
                                    tripManager.originationTimestamp = trip.originationTimestamp
                                    showDeleteConfirmation = true
                                } label: {
                                    HStack{
                                        Image(systemName: "trash")
                                            .resizable()
                                            .frame(width: 16,height: 16)
                                        Text("Delete")
                                    }
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
                                
                                /// DETAILS
                                ///
                                Button(action: {
                                    /// Do stuff
                                    tripManager.originationTimestamp = trip.originationTimestamp
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isShowTripDetailsView.toggle()
                                    }
                                }) {
                                    Text("Details")
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
                            }
                            .frame(height: 42)
                            
                            /// SAVE trip to summary history
                            HStack {
                                Text(trip.archived ? "Saved" : "Unsaved")
                                Spacer()
                                
                                /// SAVE Trip
                                ///
                                Button(role: .destructive) {
                                    tripManager.originationTimestamp = trip.originationTimestamp
                                    showSaveTripConfirmation = true
                                } label: {
                                    HStack{
                                        Image(systemName: "square.and.arrow.down")
                                            .resizable()
                                            .frame(width: 18,height: 18)
                                        Text(trip.archived ? "Saved" : "Save")
                                    }
                                    .foregroundColor(trip.archived ? .gray : .blue)
                                    .frame(width: 100, height: 32)
                                    .background(
                                        RoundedRectangle(
                                            cornerRadius: 5,
                                            style: .continuous
                                        )
                                        .stroke(trip.archived ? .gray : .blue, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())

                            }
                            .frame(height: 42)
                        }
                    }
                }
                .listStyle(.plain)
                
                .alert("Save Trip!", isPresented: $showSaveTripConfirmation) {
                    Button("Continue") {
                        
                        /// Ensure that the copy is completed before continuting on
                        ///
                        isProcessing = true
                        DispatchQueue.global().async {
                            _ = copyTripToHistorySummarySD(tripTimestamp: tripManager.originationTimestamp!)
                            DispatchQueue.main.async {
                                isProcessing = false
                            }
                        }
                        
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to save the trip")
                }
                
                .alert(isPresented: $showDeleteConfirmation) {
                    Alert(
                        title: Text("Delete Trip"),
                        message: Text("Are you sure you want to delete this trip dated:\n \(formatDateStampDayMonthTime(tripManager.originationTimestamp!))"),
                        primaryButton: .destructive(Text("Delete")) {
                            _ = deleteTripData(tripTimestamp: tripManager.originationTimestamp!)
                        },
                        secondaryButton: .cancel()
                    )
                }
                .alert("Export Trip", isPresented: $showExportCompletion) {
                    Button("Ok", role: .cancel) { }
                } message: {
                    Text("Trip exported for \(formatDateStampDayMonthTime(tripManager.originationTimestamp ?? Date()))")
                }
                
                .fullScreenCover(isPresented: $isShowMapTripView) {
                    //MapTripView(tripTimestamp: originationTimestamp)
                    if let timestamp = tripManager.originationTimestamp {
                        MapTripView(tripTimestamp: timestamp)
                    } else {
                        Text("No trip data available.")
                    }
                }
                
                .fullScreenCover(isPresented: $isShowTripDetailsView) {
                    //TripDetailViewV2(tripTimestamp: originationTimestamp)
                    if let timestamp = tripManager.originationTimestamp {
                        TripDetailViewV2(tripTimestamp: timestamp)
                    } else {
                        Text("No trip data available.")
                    }
                }
                /// ... end List
                
                Spacer()
            }
            .navigationBarTitle("Trips V3", displayMode: .inline)
            .task() {
                await processTask()
            }
            
            .navigationBarItems(
                leading: Button(action: {
                    isShowSideMenu.toggle()
                }) {
                    Image(systemName: "square.leftthird.inset.filled")
                        .font(.system(size: 26, weight: .ultraLight))
                        .frame(width: 35, height: 35)
                        .foregroundColor(AppValues.pallet.primaryLight)
                },
                trailing: HStack {
                    Button(action: {
                        
                        isProcessing = true
                        
                        /// purge trips over the limit
                        //_ = purgeTripSummariesSDbyCount(tripLimit: UserSettings.init().tripHistoryLimit)
                        
                        /// Clear out the old trips
                        if UserSettings.init().isTripReprocessingAllowed { deleteTripSummariesSD() }
                        
                        /// Process new trips
                        Task {
                            await processTrips()
                            
                            /// Switch back to the main thread to update UI components
                            ///
                            DispatchQueue.main.async {
                                isProcessing = false // Done loading
                            }
                        }
                        
                    }) {
                        Image(systemName: isProcessing ? "circle" : "arrow.clockwise")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(AppValues.pallet.primaryLight)
                            .frame(width: 32, height: 32)
                        Text("update")
                            .foregroundColor(AppValues.pallet.primaryLight)
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("appLogoTransparent")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                    .foregroundColor(AppValues.pallet.primaryLight)                }
            }
            Spacer() //?
            
        }
        
    }
    
    func processTask() async {
        LogEvent.print(module: "TripViewV3.processTask", message: "starting...")
        
            await processTrips()
            
            /// Switch back to the main thread to update UI components
            ///
            DispatchQueue.main.async {
                isProcessing = false
            }
    
        LogEvent.print(module: "TripViewV3.processTask", message: "...finished")
    }
}

#Preview {
    TripsViewV3(isShowSideMenu: .constant(false))
}
