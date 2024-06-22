//
//  HistoryMonthView.swift
//  ViDrive
//
//  Created by David Holeman on 5/5/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import CoreLocation

struct HistoryMonthView: View {
    
    var monthDatestamp: String?
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var tripManager = TripManager()
    
    @State private var coordinatesArray: [CLLocationCoordinate2D] = []
    
    @State private var isProcessing = false
    @State private var isShowTripDetailsView = false
    @State private var isShowDeleteConfirmation = false


    /// Grab the month
    @Query(sort: \TripHistorySummarySD.datestamp, order: .forward) private var tripHistorySummarySD: [TripHistorySummarySD]
    
    /// Find the month
    var firstFilteredMonth: TripHistorySummarySD? {
        return tripHistorySummarySD.first { tripHistorySummary in
            return tripHistorySummary.datestamp == monthDatestamp
        }
    }

    /// Sort the trips in the month
    private var sortedTrips: [TripHistoryTripsSD] {
        firstFilteredMonth?.toTripHistoryTrips?.sorted { $0.originationTimestamp < $1.originationTimestamp } ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    VStack {
                        HStack {
                            Text("\(formatDateDatestampToMonth( firstFilteredMonth!.datestamp))")
                            Spacer()
                        }
                        .font(.system(size: 20, weight: .bold))
                        .padding(.leading, 16)
                        
                        List{
                            VStack(alignment: .leading) {
                                ForEach(sortedTrips) { item in
                                    HStack {
                                        Text("\(formatDateStampDayMonth(item.originationTimestamp))")
                                            .lineLimit(1)
                                        Spacer()
                                        HStack{
                                            Text("\(formatDateStampTime(item.originationTimestamp))")
                                            Text("\(String(format: "%.1f", item.distance)) mi")
                                            Text("\(formatMMtoHHMM(minutes: item.duration))")
                                        }
                                        .font(.system(size: 14))
                                    }
                                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                    .padding(.bottom, 1)
                                    
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text("\(item.originationAddress)")
                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(formatDateStampTime(item.originationTimestamp))")
                                                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                                        }
                                        HStack {
                                            Text("\(item.destinationAddress)")
                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(formatDateStampTime(item.destinationTimestamp))")
                                                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                                        }
                                    }
                                    .font(.system(size: 14))
                                    .padding(.trailing, -16)
                                    
                                    /// Scores & Buttons
                                    HStack {
                                        
                                        /// Acceleration
                                        ///
                                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                            Circle().fill(scoreTripColor(item.scoreAcceleration)).frame(width: 32, height: 32)
                                                .overlay(
                                                    Text("Ac") // Display the progress value as a percentage
                                                        .font(.caption)
                                                        .foregroundColor(.black)
                                                )
                                        })
                                        
                                        /// Deceleration
                                        ///
                                        Button(action: {}, label: {
                                            Circle().fill(scoreTripColor(item.scoreDeceleration)).frame(width: 32, height: 32)
                                                .overlay(
                                                    Text("De") // Display the progress value as a percentage
                                                        .font(.caption)
                                                        .foregroundColor(.black)
                                                )
                                            
                                        })
                                        
                                        /// Smoothness
                                        Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                            Circle().fill(scoreTripColor(item.scoreSmoothness)).frame(width: 32, height: 32)
                                                .overlay(
                                                    Text("Sm") // Display the progress value as a percentage
                                                        .font(.caption)
                                                        .foregroundColor(.black)
                                                )
                                            
                                        })
                                        Spacer()
                                        
//                                        Text("\(formatMPH(convertMPStoMPH((item.maxSpeed)))) mph")
//                                            .font(.caption)
                                        
                                        /// DELETE Trip
                                        ///
                                        Button(role: .destructive) {
                                            tripManager.originationTimestamp = item.originationTimestamp
                                            isShowDeleteConfirmation = true
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
                                            tripManager.originationTimestamp = item.originationTimestamp
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
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                        .listStyle(.plain)
                        
                        .alert(isPresented: $isShowDeleteConfirmation) {
                            Alert(
                                title: Text("Delete Trip"),
                                message: Text("Are you sure you want to delete this trip dated:\n \(formatDateStampDayMonthTime(tripManager.originationTimestamp!))"),
                                primaryButton: .destructive(Text("Delete")) {
                                    _ = deleteHistoryTrip(tripTimestamp: tripManager.originationTimestamp!)
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        .fullScreenCover(isPresented: $isShowTripDetailsView) {
                            //TripDetailViewV2(tripTimestamp: originationTimestamp)
                            if let timestamp = tripManager.originationTimestamp {
                                //TripDetailViewV2(tripTimestamp: timestamp)
                                HistoryTripDetailView(tripTimestamp: timestamp)
                            } else {
                                Text("No trip data available.")
                            }
                        }
                        
                    }
                    Spacer()
                }
                .padding(.trailing, -8)
                Spacer()
            }
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
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HistoryMonthView(monthDatestamp: "2024-04")
}
