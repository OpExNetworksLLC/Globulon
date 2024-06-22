//
//  scoreSummaryView.swift
//  ViDrive
//
//  Created by David Holeman on 5/5/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct scoreSummaryView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {

        RoundedRectangle(cornerRadius: 10)
            .fill(colorScheme == .dark ? Color.secondary : Color.black)
            .frame(width: 300, height: 200)
            .overlay(
                HStack {
                    VStack(alignment: .leading) {
                        Text("Score Summary")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                            .padding(.bottom, 8)
                        VStack(alignment: .leading) {
                            HStack {
                                
                                /// Safe Speeds
                                VStack(alignment: .leading) {
                                    Text("Safe")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    Text("Speeds")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    Text("##")
                                        .foregroundColor(.white)
                                        .font(.system(size: 32))
                                    Text("+#^")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                                
                                /// Smooth Driving
                                VStack(alignment: .leading) {
                                    Text("Smooth")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    Text("Driving")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14))
                                    Text("##")
                                        .foregroundColor(.white)
                                        .font(.system(size: 32))
                                    Text("+#^")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }
                            }
                            Spacer()
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
    scoreSummaryView()
}
