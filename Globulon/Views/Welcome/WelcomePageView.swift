//
//  WelcomePageView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

// MARK: Pageview with detail
struct WelcomePageView: View {
    let imageName: String
    //@Binding var isWelcomed: Bool
    
    var body: some View {
        VStack {
            Spacer().frame(height: 50)
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                //.padding()
            //Spacer()
        }
    }
}

#Preview {
    WelcomePageView(imageName: "roadtripDesert")
}
