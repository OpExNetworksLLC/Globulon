//
//  TripsView.swift
//  ViDrive
//
//  Created by David Holeman on 2/14/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

struct TripsView: View {
    @Binding var isShowSideMenu: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme

    @Query(
    ) private var gpsJournalSD: [GpsJournalSD]
    
    @Query(sort: \TripSummariesSD.originationTimestamp, order: .forward) private var tripSummariesSD: [TripSummariesSD]
    
    @State private var tripList: [TripSummariesSD] = []
    
    @State var isShowHelp = false
    @State var isProcessing = false
    @State var isShowMapTripView = false
    
    @State var showAlertDedupSuccess: Bool = false
    @State var showAlertDedupMessage: String = ""
    
    @State var showExportCompletion: Bool = false
    
    @State var originationTimestamp: Date = Date()
    @State private var showDeleteConfirmation = false
    
    @State private var tripToDelete: TripSummariesSD? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer().frame(height: 24)
                
                /// Show spinner when processing trips
                ///
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.75)
                        .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                        .padding()
                }

                /*start*/
                NavigationView {
                    List {
                        ForEach(tripSummariesSD.sorted(by: { $0.originationTimestamp < $1.originationTimestamp }) , id: \.self) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip, latitude: trip.originationLatitude, longitude: trip.originationLongitude)) {
                                VStack(alignment: .leading) {
                                    Text("Trip: \(formatDateStampDayMonthTime(trip.originationTimestamp))")
                                        .fontWeight(.bold)
                                        .padding(.bottom, 0)

                                    HStack {
                                        VStack {
                                            //Text("\(Int(trip.scoreAcceleration))")
                                            CircularScoreView(score: Int(trip.scoreAcceleration))
                                                .frame(width: 42, height: 42)
                                            Text("Accel")
                                        }
                                        VStack {
                                            //Text("\(Int(trip.scoreDeceleration))")
                                            CircularScoreView(score: Int(trip.scoreDeceleration))
                                                .frame(width: 42, height: 42)
                                            Text("Decel")
                                        }
                                        VStack {
                                            //Text("\(Int(trip.scoreSmoothness))")
                                            CircularScoreView(score: Int(trip.scoreSmoothness))
                                                .frame(width: 42, height: 42)
                                            Text("Smooth")
                                        }
                                        VStack {
                                            Text("\(formatMPH(convertMPStoMPH((trip.maxSpeed)))) mph")
                                                .frame(width: 96, height: 42)
                                            Text("Max")
                                        }
                                        Spacer()
                                    }
                                    .padding(.bottom, 1)
                                    
                                    VStack(alignment: .leading) {
                                        Text("fr: \(trip.originationAddress)")
                                        Text("to: \(trip.destinationAddress)")
                                    }
                                    .font(.system(size: 14, design: .monospaced))
                                    
                                    //MapTripView(tripTimestamp: trip.originationTimestamp)

                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                
                                /// DELETE Trip
                                ///
                                Button(role: .destructive) {
                                    //self.performDelete(trip: trip)
                                    originationTimestamp = trip.originationTimestamp
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                /// EXPORT Trip
                                ///
                                Button {
                                    print("** exporting: \(formatDateStampDayMonthTime(trip.originationTimestamp))")
                                    originationTimestamp = trip.originationTimestamp
                                    _ = exportTripData(tripTimestamp: originationTimestamp)
                                    showExportCompletion = true

                                } label: {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                }
                                .tint(.blue)
                        
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                
                                /// MAP Trip
                                ///
                                Button {
                                    originationTimestamp = trip.originationTimestamp
                                    isShowMapTripView.toggle()
                                } label: {
                                    Label("Map", systemImage: "map")
                                }
                                .tint(.green)
                                
                            }
                            
                            .alert(isPresented: $showDeleteConfirmation) {
                                Alert(
                                    title: Text("Delete Trip"),
                                    message: Text("Are you sure you want to delete this trip dated: \(formatDateStampDayMonthTime(originationTimestamp)) ?"),
                                    primaryButton: .destructive(Text("Delete")) {
                                        _ = deleteTripData(tripTimestamp: originationTimestamp)
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                            .alert("Export Trip", isPresented: $showExportCompletion) {
                                Button("Ok", role: .cancel) { }
                            } message: {
                                Text("Trip exported for  \(formatDateStampDayMonthTime(originationTimestamp))")
                            }
                        }
                        
                        //.onDelete(perform: deleteTrip)
                        
                        .onAppear {
                            /// This ensures tripList is populated with the latest data from tripSummariesSD when the view appears.
                            ///
                            tripList = tripSummariesSD
                        }
                    }
                    .listStyle(.plain)
                    
                    .fullScreenCover(isPresented: $isShowMapTripView) {
                        MapTripView(tripTimestamp: originationTimestamp)
                    }
                    
                }
                /*stop*/

            }
            .navigationBarTitle("Trips", displayMode: .inline)
            
            .navigationBarItems(
                leading: Button(action: {
                    isShowSideMenu.toggle()
                }) {
                    Image(systemName: "square.leftthird.inset.filled")
                        .font(.system(size: 32, weight: .ultraLight))
                        .frame(width: 35, height: 35)
                        .foregroundColor(AppValues.pallet.primaryLight)
                },
                trailing: HStack {
                    Button(action: {
                        
                        // TODO:  We just want to update the list not necessarily delete the old trips.  Stuff to sort out here to just get an update after scoring.  View is not recongizing the change to the data and refreshing.
                        
                        isProcessing = true
                        
                        /// Clear out the old trips
                        deleteTripSummariesSD()

                        /// Your long-running task here...
                        ///
                        /// Process the trips
                        Task {
                            await processTrips()
                            
                            /// Switch back to the main thread to update UI components
                            ///
                            DispatchQueue.main.async {
                                isProcessing = false // Stop loading
                            }

                        }

                    }) {
                        Image(systemName: isProcessing ? "circle" : "arrow.clockwise")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(AppValues.pallet.primaryLight)
                            .frame(width: 35, height: 35)
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
                        .frame(width: 35, height: 35)
                    .foregroundColor(AppValues.pallet.primaryLight)                }
            }
            
            Spacer()
        }
    }

}

#Preview {
    TripsView(isShowSideMenu: .constant(false))
}
