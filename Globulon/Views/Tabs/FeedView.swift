//
//  FeedView.swift
//  ViDrive
//
//  Created by David Holeman on 2/14/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData
import CoreLocation

struct FeedView: View {
    @Binding var isShowSideMenu: Bool
    
    @Environment(\.modelContext) private var modelContext
    
    @State var isShowHelp = false
    @State var isRecording = false
    
    @Query(
        //sort: \LocationDataSD.timestamp, order: .reverse
    ) private var items: [GpsJournalSD]
    
    var body: some View {
        // Top menu
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Counter: \(items.count)\nlat: \(CLLocationManager().location?.coordinate.latitude ?? 0.0)   lng: \(CLLocationManager().location?.coordinate.longitude ?? 0.0)")
                        Spacer()
                    }
                }
                .padding()
                Divider()
                Spacer()
                
                // sort decending and limit the list to 20 items
                List {
                    ForEach(items.sorted(by: {$0.timestamp > $1.timestamp}).prefix(20)) { item in
                        VStack(alignment: .leading) {
                            Text("\(formatDateStampA(item.timestamp))")
                                .fontWeight(.bold)
                            Text("\(formatMPH(convertMPStoMPH(item.speed))) mph  lat: \(item.latitude) lng: \(item.longitude)")
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                
                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            
            .navigationBarItems(leading: Button(action: {
                isShowSideMenu.toggle()
            }) {
                Image(systemName: "square.leftthird.inset.filled")
                    .font(.system(size: 26, weight: .ultraLight))
                    .frame(width: 35, height:35)
                    .foregroundColor(AppValues.pallet.primaryLight)
                
            }, trailing: Button(action: {
                // Do stuff
                isRecording.toggle()
                if isRecording {
                    //locationManager.startUpdatingtLocation()
                } else {
                    //locationManager.stopUpdatingLocation()
                }
            }) {
                if isRecording {
                    Image(systemName: "record.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color.red)
                        .frame(width: 35, height: 35)
                    Text("recording")
                        .foregroundColor(AppValues.pallet.primaryLight)

                } else {
                    Image(systemName: "record.circle")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(AppValues.pallet.primaryLight)
                        .foregroundColor(Color.red)
                        .frame(width: 35, height: 35)
                    Text("record")
                        .foregroundColor(AppValues.pallet.primaryLight)
                }
            })
            //.fullScreenCover(isPresented: $isShowHelp, content: {
            .sheet(isPresented: $isShowHelp, content: {
                // Content of the sheet
                HelpSheetView(isShowHelp: $isShowHelp)
            })
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("appLogoTransparent")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                    .foregroundColor(AppValues.pallet.primaryLight)                }
            }
        }
    }
    
}

#Preview {
    FeedView(isShowSideMenu: .constant(false))
}

