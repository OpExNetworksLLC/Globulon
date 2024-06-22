//
//  CircularScoreView.swift
//  ViDrive
//
//  Created by David Holeman on 3/25/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct CircularScoreView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let score: Int // Step 1: Change to Double
    
    var body: some View {

        var fill: Color {
            switch score {
            case ...69:
                return .red
            case 70...79:
                return Color(red: 1.0, green: 0.5, blue: 0.5)
            case 80...89:
                return Color(red: 1.0, green: 1.0, blue: 0.5)
            case 90...:
                return Color(red: 0.5, green: 1.0, blue: 0.5)
            default:
                return Color(red: 0.5, green: 1.0, blue: 0.5)
            }
        }

        ZStack {
            
            Circle()
                .fill(fill)
                .opacity(1.0)
                .overlay(
                    Text("\(Int(score))%") // Display the progress value as a percentage
                        .font(.caption) // Customize the font of the text
                    
                        .foregroundColor(.black)
                )
        }
    }
}

struct circle: View {
    var body: some View {
        CircularScoreView(score: 75)
            .frame(width: 48,height: 48)
    }
}

#Preview {
    circle()
}
