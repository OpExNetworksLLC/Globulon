//
//  HistoryView.swift
//  ViDrive
//
//  Created by David Holeman on 5/5/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # HistoryView
/// Display summary of trips by month
///
/// # Version History
/// ### 0.1.0.62
/// # - cleaned up toolbar and toolbar items
/// # - *Date*: 07/12/24

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Binding var isShowSideMenu: Bool
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \TripHistorySummarySD.datestamp, order: .forward) private var tripHistorySummarySD: [TripHistorySummarySD]
    
    @StateObject private var tripManager = TripManager()
    
    @State private var isShowHelp = false
    @State private var isProcessing = false
    
    @State private var isShowHistoryMonthView = false
    
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
                if tripHistorySummarySD.isEmpty {
                    Text("No trips available")
                } else {
                    List {
                        ForEach(tripHistorySummarySD.sorted(by: { $0.datestamp > $1.datestamp }) , id: \.self) { month in
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(formatDateDatestampToMonthYear(month.datestamp))")
                                        .lineLimit(1)
                                    Spacer()
                                    HStack {
                                        Text("\(month.totalTrips) trips")
                                        Text("\(String(format: "%.1f", month.totalDistance)) mi")
                                            .padding(.trailing, 4)
                                        Text("\(formatMMtoHHMM(minutes: month.totalDuration))")
                                    }
                                    .font(.system(size: 14))
                                }
                                .fontWeight(.bold)
                                
                                VStack(alignment: .leading) {
                                    if month.toTripHistoryTrips?.count ?? 0 > 0 {
                                        Text("first trip: \(formatDateStampDayMonthTime(month.toTripHistoryTrips![0].originationTimestamp))")
                                        Text("last trip: \(formatDateStampDayMonthTime(month.toTripHistoryTrips![month.toTripHistoryTrips!.count - 1].originationTimestamp))")
                                    }
                                }
                                .font(.system(size: 14))
                                
                                HStack {
                                    
                                    /// Acceleration
                                    ///
                                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                        Circle().fill(scoreTripColor(month.totalAcceleration)).frame(width: 32, height: 32)
                                            .overlay(
                                                Text("Ac") // Display the progress value as a percentage
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                            )
                                    })
                                    
                                    /// Deceleration
                                    ///
                                    Button(action: {}, label: {
                                        Circle().fill(scoreTripColor(month.totalDeceleration)).frame(width: 32, height: 32)
                                            .overlay(
                                                Text("De") // Display the progress value as a percentage
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                            )
                                        
                                    })
                                    
                                    /// Smoothness
                                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                                        Circle().fill(scoreTripColor(month.totalSmoothness)).frame(width: 32, height: 32)
                                            .overlay(
                                                Text("Sm") // Display the progress value as a percentage
                                                    .font(.caption)
                                                    .foregroundColor(.black)
                                            )
                                        
                                    })
                                    
                                    Text("\(formatMPH(convertMPStoMPH((month.highestSpeed)))) mph")
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    /// DETAILS
                                    ///
                                    Button(action: {
                                        /// Do stuff
                                        ///
                                        tripManager.monthDatestamp = month.datestamp
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            isShowHistoryMonthView.toggle()
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
                    .fullScreenCover(isPresented: $isShowHistoryMonthView) {
                        if let monthDatestamp = tripManager.monthDatestamp {
                            HistoryMonthView(monthDatestamp: monthDatestamp)
                        } else {
                            Text("No trip data available.")
                        }
                    }
                }
                
            }
           
            .task() {
                /// Do stuff that happens before the VStack displays it's items
                
            }
            .onAppear {
                if tripHistorySummarySD.isEmpty {
                    // Dismiss the view if there are no trips
                    isShowHistoryMonthView = false
                }
            }
            .navigationBarTitle("History", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isShowSideMenu.toggle()
                    }) {
                        Image(systemName: "square.leftthird.inset.filled")
                            .font(.system(size: 26, weight: .ultraLight))
                            .frame(width: 35, height: 35)
                            .foregroundColor(AppValues.pallet.primaryLight)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        
                        isProcessing = true
                        
                        /// purge trips over the limit
                        //  TODO: Reinstate if we want to auto purge.
                        //
                        //  TODO: replace this function with one that purges monthly summaries
                        //_ = purgeTripSummariesSDbyCount(tripLimit: UserSettings.init().tripHistoryLimit)
                        
                        /// Clear out the old trips
                        if UserSettings.init().isTripReprocessingAllowed { deleteTripSummariesSD() }
                        
                        /// Process new trips
                        Task {

                            // TODO: Replace this with some function to reprocess the monthly summaries
                            //await processTask()
                            
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
                ToolbarItem(placement: .principal) {
                    Image("appLogoTransparent")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                        .foregroundColor(AppValues.pallet.primaryLight)
                }
            }
            Spacer()
            
        }
    }
}

#Preview {
    HistoryView(isShowSideMenu: .constant(false))
}
