//
//  ToursView.swift
//  GeoGato
//
//  Created by David Holeman on 1/28/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

struct ToursView: View {
    
    @Binding var isShowSideMenu: Bool
    
    @EnvironmentObject var appEnvironment: AppEnvironment
    
    @State private var isShowHelp = false
    @State private var isProcessing = false
    
    @Query(sort: \CatalogToursData.catalog_id, order: .forward) private var catalogToursData: [CatalogToursData]

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    let allTours = catalogToursData.compactMap { $0.toCatalogTour }.flatMap { $0 }
                    let sortedTours = allTours.sorted { $0.order_index < $1.order_index }

                    ForEach(sortedTours, id: \.tour_id) { tour in
                        NavigationLink(destination: TourDetailView(tour: tour)) {
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
                                    .font(.headline)
                                Text(tour.sub_title)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(tour.tour_directory)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                Task {
                                    isProcessing = true  // ✅ Show spinner

                                    // Download the tour file
                                    await GitHubManager.download(
                                        directory: tour.tour_directory
                                    )

                                    sleep(1)

                                    let (_, _) = await TourDataManager.load(
                                        source: tour.tour_id + ".json",
                                        appRelativePath: "Tours/" + tour.tour_id
                                    )

                                    updateIsActive(for: tour, to: true) // Activate

                                    isProcessing = false // ✅ Hide spinner
                                }
                            } label: {
                                Label("Activate", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                updateIsActive(for: tour, to: false) // Deactivate
                            } label: {
                                Label("Deactivate", systemImage: "xmark.circle")
                            }
                            .tint(.red)
                        }
                    }
                }
                .listStyle(.plain)
                .disabled(isProcessing) // ✅ Prevent interactions while loading
                .opacity(isProcessing ? 0.3 : 1.0) // ✅ Dim list when loading

                // ✅ Overlay the progress indicator (spinner)
                if isProcessing {
                    VStack {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
                    }
                }
            }
        }
    }

    /// Updates the `isActive` status for the given `CatalogTourData`.
    private func updateIsActive(for tour: CatalogTourData, to status: Bool) {
        guard let modelContext = tour.modelContext else {
            LogEvent.print(module: "", message: "❌ No ModelContext available for this CatalogTourData instance.")
            return
        }
        tour.isActive = status

        do {
            try modelContext.save()

        } catch {
            LogEvent.print(module: "", message: "❌ Failed to save changes: \(error)")
        }
    }
}

#Preview {
    ToursView(isShowSideMenu: .constant(false))
}


// cache example:
//            List {
//                ForEach(AppEnvironment.shared.catalogToursCache
//                    .flatMap { $0.toCatalogTour ?? [] }
//                    .sorted { $0.order_index < $1.order_index }, id: \.tour_id) { tour in
//                    NavigationLink(destination: TourDetailView(tour: tour)) {
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(tour.tour_id)
//                                    .font(.headline)
//                                    .padding(.trailing, 8)
//
//                                if tour.isActive {
//                                    Circle()
//                                        .fill(Color.green)
//                                        .frame(width: 10, height: 10) // Small green circle
//                                }
//
//                                Spacer()
//                            }
//                            Text(tour.title)
//                                .font(.headline)
//                            Text(tour.tour_file)
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                            Text(tour.desc)
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                        }
//                    }
//                    .swipeActions(edge: .leading) {
//                        Button {
//                            Task {
//                                let (_, _) = await TourDataManager.load(source: tour.tour_file)
//                                //updateIsActive(for: tour, to: true)
//                            }
//                        } label: {
//                            Label("Activate", systemImage: "checkmark.circle")
//                        }
//                        .tint(.green)
//                    }
//                    .swipeActions(edge: .trailing) {
//                        Button {
//                            print("tour_id: \(tour.tour_id)")
//                        } label: {
//                            Label("Deactivate", systemImage: "xmark.circle")
//                        }
//                        .tint(.red)
//                    }
//                }
//            }
//           .listStyle(.plain)
