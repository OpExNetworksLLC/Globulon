//
//  MyTourDetailView.swift
//  GeoGato
//
//  Created by David Holeman on 1/24/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import Combine

struct MyTourDetailView: View {
    
    let tour: TourData
    
    var body: some View {
        List((tour.toTourPOI ?? []).sorted { $0.order_index < $1.order_index }, id: \.id) { poi in
            VStack(alignment: .leading) {
                Text(poi.title)
                    .font(.headline)
                Text(poi.sub_title)
                    .font(.subheadline)
                Text(poi.desc)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle(tour.application)
    }
}
