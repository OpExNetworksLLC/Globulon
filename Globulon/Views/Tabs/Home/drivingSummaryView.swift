//
//  drivingSummaryView.swift
//  Globulon
//
//  Created by David Holeman on 5/5/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/// # drivingSummaryView
/// Show summary of driver metrics
///
/// # Version History
/// ### 0.1.0.64
/// # - Fixed an index problem with loading prior month on record score.  Was casing the app to crash.
/// # - *Date*: 07/14/24

import SwiftUI
import SwiftData

struct drivingSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Query(
    ) private var tripSummariesSD: [TripSummariesSD]
    
    /// Grab the months
    @Query(sort: \TripHistorySummarySD.datestamp, order: .reverse) private var tripHistorySummarySD: [TripHistorySummarySD]
    
    @State private var thisMonthTripCount: String = ""
    @State private var pastMonthTripCount: String = ""
    @State private var thisMonthTripCountDelta: String = ""

    @State private var thisMonthDistance: String = ""
    @State private var pastMonthDistance: String = ""
    @State private var thisMonthDistanceDelta: String = ""
    
    @State private var thisMonthDuration: String = ""
    @State private var pastMonthDuration: String = ""
    @State private var thisMonthDurationDelta: String = ""
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(colorScheme == .dark ? Color.secondary : Color.black)
            .frame(width: 300, height: 200)
            .overlay(
                HStack {
                    VStack(alignment: .leading) {
                        Text("Driving")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                            .padding(.bottom, 8)
                        VStack(alignment: .leading) {
                            HStack {
                                
                                /// Total Trips
                                VStack(alignment: .leading) {
                                    Text("Trips")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    Text("Taken")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    HStack(alignment: .bottom, spacing: 1) {
                                        Text("\(thisMonthTripCount)")
                                            .foregroundColor(.white)
                                            .font(.system(size: 32))
                                        Text("\(thisMonthTripCountDelta)")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18))
                                            .padding(.bottom, 4)
                                    }
                                    Text("\(pastMonthTripCount)")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                                
                                /// Miles Driven
                                VStack(alignment: .leading) {
                                    Text("Miles")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    Text("Driven")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    
                                    HStack(alignment: .bottom, spacing: 1) {
                                        Text("\(thisMonthDistance)")
                                            .foregroundColor(.white)
                                            .font(.system(size: 32))
                                        Text("\(thisMonthDistanceDelta)")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18))
                                            .padding(.bottom, 4)
                                    }
                                    
                                    Text("\(pastMonthDistance)")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                                
                                /// Time Driving
                                VStack(alignment: .leading) {
                                    Text("Time")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    Text("Driving")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    HStack(alignment: .bottom, spacing: 1) {
                                        Text("\(thisMonthDuration)")
                                            .foregroundColor(.white)
                                            .font(.system(size: 32))
                                        Text("\(thisMonthDurationDelta)")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18))
                                            .padding(.bottom, 4)
                                    }
                                    Text("\(pastMonthDuration)")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }

                            }
                            Spacer()
                        }
                        .task {
                            thisMonthTripCount = String(tripHistorySummarySD.first?.totalTrips ?? 0)
                            thisMonthDistance = String(format: "%.0f", tripHistorySummarySD.first?.totalDistance ?? 0)
                            thisMonthDuration = formatMMtoHHMM(minutes: tripHistorySummarySD.first?.totalDuration ?? 0)
                            
                            if tripHistorySummarySD.count > 1 {
                                pastMonthTripCount = String(tripHistorySummarySD[1].totalTrips)
                                if tripHistorySummarySD[0].totalTrips > tripHistorySummarySD[1].totalTrips {
                                    thisMonthTripCountDelta = "↑"
                                } else if tripHistorySummarySD[0].totalTrips < tripHistorySummarySD[1].totalTrips {
                                    thisMonthTripCountDelta = "↓"
                                } else {
                                    thisMonthTripCountDelta = " "
                                }

                                
                                pastMonthDistance = String(format: "%.0f", tripHistorySummarySD[1].totalDistance)
                                if tripHistorySummarySD[0].totalDistance > tripHistorySummarySD[1].totalDistance {
                                    thisMonthDistanceDelta = "↑"
                                } else if tripHistorySummarySD[0].totalDistance < tripHistorySummarySD[1].totalDistance {
                                    thisMonthDistanceDelta = "↓"
                                } else {
                                    thisMonthDistanceDelta = " "
                                }
                                
                                pastMonthDuration = formatMMtoHHMM(minutes: tripHistorySummarySD[1].totalDuration)
                                if tripHistorySummarySD[0].totalDuration > tripHistorySummarySD[1].totalDuration {
                                    thisMonthDurationDelta = "↑"
                                } else if tripHistorySummarySD[0].totalDuration < tripHistorySummarySD[1].totalDuration {
                                    thisMonthDurationDelta = "↓"
                                } else {
                                    thisMonthDurationDelta = " "
                                }
                            }
                            
                        }
                        Text("Since...")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                            .padding(.bottom, 8)
                        Spacer()
                    }
                    Spacer()
                }
                    .padding(.leading, 8)
                    .padding(.top, 8)
                    
            )
    }
}

#Preview {
    drivingSummaryView()
}
