//
//  WebPageView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct WebPageView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var title: String
    var subtitle: String
    var webURL: String

    @Binding var isReviewed: Bool
    
    var body: some View {

        HStack {
            VStack(alignment: .leading) {
                
                Spacer().frame(height: 16)
                
                Text("\(title)")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .padding(.bottom, 2)
                Text("\(subtitle)")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .padding(.bottom, 24)
                
                //----
                SwiftUIWebView(url: URL(string: webURL))
                    .padding(8)
                    //.border(colorScheme == .dark ? .white : .black)
                    .border(.gray)
                //----
                
                //Spacer()
                Spacer().frame(height: 30)
                
                Button(action: {
                    isReviewed = true
                    self.presentationMode.wrappedValue.dismiss()
                }
                ) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .padding()
                            .background(Color("btnNextOnboarding"))
                            .cornerRadius(30)
                        Text("Reviewed").foregroundColor(.blue)
                    }
                }
                // end HStack
                Spacer().frame(height: 32)
            }
            .padding(.leading, 16)
            // End VStack
            Spacer().frame(width: 16)
            
        }
        .edgesIgnoringSafeArea(.bottom)
        // end HStack

    }
}

#Preview {
    WebPageView(title: "title", subtitle: "subtitle", webURL: AppValues.licenseURL, isReviewed: .constant(false))
}
