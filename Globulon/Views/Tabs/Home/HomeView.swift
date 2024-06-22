//
//  HomeView.swift
//  ViDrive
//
//  Created by David Holeman on 2/14/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

struct CircularProgressView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let progress: Int // Step 1: Change to Double
    
    var body: some View {
        ZStack {
            // Background for the progress bar
            Circle()
                .stroke(lineWidth: 3)
                .opacity(0.1)
                .foregroundColor(.gray)
            
            // Foreground or the actual progress bar
            Circle()
                .trim(from: 0.0, to: min(CGFloat(Double(progress) * 0.01), 1.0)) // Steps 2 & 3: Multiply by 0.01 and convert to CGFloat
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .foregroundColor(.green)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
                .overlay(
                    Text("\(Int(progress))%") // Display the progress value as a percentage
                        .font(.caption) // Customize the font of the text
                    
                        .foregroundColor(colorScheme == .dark ? .white : .black) // Set the color of the text
                )
        }
    }
}

func medianScoreSmoothness(tripSummaries: [TripSummariesSD]) -> Double? {
    let sortedScores = tripSummaries.map { $0.scoreSmoothness }.sorted()
    if sortedScores.isEmpty {
        return nil
    } else if sortedScores.count % 2 == 0 {
        return (sortedScores[(sortedScores.count / 2) - 1] + sortedScores[sortedScores.count / 2]) / 2.0
    } else {
        return sortedScores[sortedScores.count / 2]
    }
}

struct HomeView: View {
    
    @Binding var isShowSideMenu: Bool
    
    @StateObject var networkManager = NetworkStatus.shared
    
    @State private var isShowHelp = false
    
    @Query(
    ) private var tripSummariesSD: [TripSummariesSD]
    
    var body: some View {
        
        let scoreDriving = Int(medianScoreSmoothness(tripSummaries: tripSummariesSD) ?? 0)
        var scoreTripCount: Int {
            let tripCount = tripSummariesSD.count
            if tripCount < 5 {
                // Calculate the percentage of trips out of 100
                // Assuming each trip counts equally towards the total, and you have less than 5 trips
                let percentage = (tripCount * 100) / 5
                return percentage
            } else {
                // If 5 or more trips, return 100
                return 100
            }
        }
        
        var isDriverCertified: Bool {
            if scoreDriving >= 90  &&  scoreTripCount == 100 {
                return true
            } else {
                return false
            }
        }
        
        
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Your driving summary")
                        .font(.system(size: 24))
                        .padding(.top, 24)
                    Spacer()
                }
            }
            .padding(.leading, 16)
            
            ScrollView {
                VStack(alignment: .leading) {
                    
                    /// Scores
                    ///
                    VStack(alignment: .leading) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                
                                drivingSummaryView()
                                scoreSummaryView()
                            }
                            .padding()
                        }
                    }
                    
                    /// Certificates
                    ///
                    VStack(alignment: .leading) {
                        HStack {
                            
                            VStack(alignment: .leading) {
                                
                                Button(action: {
                                    // Do stuff
                                    print("trips")
                                }) {
                                    VStack(alignment: .center) {
                                        
                                        CircularProgressView(progress: scoreTripCount)
                                            .frame(width: 48, height: 48)
                                        Text("Trips")
                                    }
                                    .frame(width: 96,height: 96)
                                }
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                    .stroke(.blue, lineWidth: 1)
                                )
                                
                                Spacer()
                                
                                Button(action: {
                                    // Do stuff
                                    print("score")
                                }) {
                                    VStack(alignment: .center) {
                                        
                                        CircularProgressView(progress: scoreDriving)
                                            .frame(width: 48, height: 48)
                                        Text("Score")
                                    }
                                    .frame(width: 96,height: 96)
                                }
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                    .stroke(.blue, lineWidth: 1)
                                )
                                
                                
                            }
                            
                            Button(action: {
                                // Do stuff
                                print("certificate")
                            }) {
                                VStack(alignment: .center) {
                                    
                                    Image(isDriverCertified ? .videntiyCertified : .videntityUncertified)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 164, height: 164)
                                    
                                    Text("Certificate")
                                        .padding(.bottom, 16)
                                }
                                .frame(width: 200,height: 200)
                            }
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                                .stroke(.blue, lineWidth: 1)
                            )
                            
                            Spacer()
                            
                        }
                    }
                    .padding(.leading, 16)
                    Spacer()
                    
                }
                .navigationBarTitle("", displayMode: .inline)
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
                        if networkManager.isConnected {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isShowHelp.toggle()
                        }) {
                            Image(systemName: "questionmark")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(AppValues.pallet.primaryLight)
                                .frame(width: 35, height: 35)
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
                .fullScreenCover(isPresented: $isShowHelp) {
                    NavigationView {
                        ArticlesSearchView()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: {
                                        isShowHelp.toggle()
                                    }) {
                                        ImageNavCancel()
                                    }
                                }
                                ToolbarItem(placement: .principal) {
                                    Text("search")
                                }
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(isShowSideMenu: .constant(false))
    //.environmentObject(NetworkMonitor())
}
