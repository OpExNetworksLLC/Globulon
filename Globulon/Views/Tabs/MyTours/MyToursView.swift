//
//  MyToursView.swift
//  GeoGato
//
//  Created by David Holeman on 1/24/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

struct MyToursView: View {
    
    @Binding var isShowSideMenu: Bool
    
    @EnvironmentObject var appEnvironment: AppEnvironment
    
    @State private var isShowHelp = false
    
    @Query(sort: \TourData.tour_id, order: .forward) private var tourData: [TourData]

    var body: some View {
        NavigationStack {
            List(tourData, id: \.tour_id) { tour in
                NavigationLink(destination: MyTourDetailView(tour: tour)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(tour.tour_id)
                                .font(.headline)
                                .padding(.trailing, 8)
                            
                            if tour.isActive {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10) // Small green circle
                            }
                            
                            Spacer()
                        }
                        Text(tour.title)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(tour.sub_title)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        updateIsActive(for: tour, to: true)
                        Task {
                            await TourDataManager.setActiveTour(tourID: tour.tour_id)
                            //appEnvironment.activeTourID = tour.tour_id
                        }
                    } label: {
                        Label("Activate", systemImage: "plus.circle")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        Task {
                            updateIsActive(for: tour, to: false)
                            LocationHandler.shared.loadTourData(for: "")
                        }
                    } label: {
                        Label("Deactivate", systemImage: "xmark.circle")
                    }
                    .tint(.yellow)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        Task {
                            await TourDataManager.deleteTourDataByID(for: tour.tour_id)
                            LocationHandler.shared.loadTourData(for: "")
                        }
                    } label: {
                        Label("Delete", systemImage: "minus.circle")
                    }
                    .tint(.red)
                }
            }
            .listStyle(.plain)
        }
    }
    /// Updates the `isActive` status for a given `TourData` record.
    private func updateIsActive(for tour: TourData, to status: Bool) {
        guard let modelContext = tour.modelContext else {
            print("Error: No ModelContext available for this TourData instance.")
            return
        }
                
        /// Tour was true
        if tour.isActive == true {
            appEnvironment.activeTourID = ""
        } else {
            appEnvironment.activeTourID = tour.tour_id
        }
        
        // Update the property
        tour.isActive = status
        

        //appEnvironment.activeTourID = status ? tour.tour_id : ""

        do {
            // Save the changes to the database
            try modelContext.save()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

#Preview {
    MyToursView(isShowSideMenu: .constant(false))
}
