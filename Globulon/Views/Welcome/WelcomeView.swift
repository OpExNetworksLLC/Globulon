//
//  WelcomeView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    //@Binding var isWelcomed: Bool
    @State private var currentTab = 0
    @State var showDismissButton: Bool = false
    
    var titles = [
        "City driving",
        "About town",
        "Scenic roadtrip"
    ]
    
    var subTitles =  [
        "Juggle commuting into the city",
        "Manage trips running errands in town",
        "Enjoy a roadtrip to experience new sights"
    ]
    
    var images = [
        "roadtripCity",
        "roadtripTown",
        "roadtripDesert"
    ]

    
    var body: some View {
        TabView(selection: $currentTab) {
            WelcomePageView(
                imageName: images[currentTab]
                )
                .tag(0)
            WelcomePageView(
                imageName: images[currentTab]
                )
                .tag(1)
            WelcomePageView(
                imageName: images[currentTab]
                )
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))  // hide the dots
        .tabViewStyle(PageTabViewStyle())
        .padding(.bottom, -32)
        
        VStack {
            Color.gray.frame(height: 1)
            Spacer().frame(height: 32)
            HStack {
                Text(titles[currentTab])
                    .font(.system(size: 24))
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.bottom, 16)
            HStack {
                Text(subTitles[currentTab])
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.leading, 16)
            
            Spacer().frame(height: 124)

            HStack {
                PageControl(numberOfPages: images.count, currentPageIndex: $currentTab)
                    .frame(width: 75)
                Text("swipe image")
                    .offset(x: -8)
                Spacer()
                    Button(action: {
                        /// Toggle the variable to let the rest of the app know the welcome has been completed and exited
                        // isWelcomed.toggle()
                        ///
                        /// or if you don't want state to control this you can store and dispatch/notify to return to the main queue and return that flow.
                        ///
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isWelcomed"), object: nil)
                        }
                        
                    }, label: {
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(currentTab == images.count - 1 ? .white : .clear)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(currentTab == images.count - 1 ? Color("btnNextWelcome") : Color.clear)
                                .cornerRadius(30)
                                .padding(.trailing, 16)
                    }
                    )
            }
        }
        .background(Color("viewBackgroundColorWelcome"))
    }
}


#Preview {
    WelcomeView()
}

