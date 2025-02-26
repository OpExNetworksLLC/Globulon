////
//  TourDetailView.swift
//  GeoGato
//
//  Created by David Holeman on 1/28/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import Combine

struct TourDetailView: View {
    
    let tour: CatalogTourData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tour.title)
                .font(.title)
                .bold()
            
            Text(tour.sub_title)
                .font(.title2)
                .foregroundColor(.gray)
            
            Text(tour.desc)
                .font(.body)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Expand VStack and align to leading
        .padding()
        .navigationTitle("Tour Details")
    }
}
