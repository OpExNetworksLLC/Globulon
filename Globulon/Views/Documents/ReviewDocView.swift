//
//  ReviewDocView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct ReviewDocView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var title: String
    var subtitle: String
    var content: String
    
    //@Binding var content: String
    @Binding var isReviewed: Bool
    
    var body: some View {

        HStack {
            Color(UIColor.clear).frame(width: 8)
            VStack(alignment: .leading) {
                Spacer().frame(height: 20)
                Text("\(title)")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .padding(.bottom, 2)
                Text("\(subtitle)")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .padding(.bottom, 24)
                
                HTMLStringView(htmlContent: content)
                    .padding(8)
                    //.border(colorScheme == .dark ? .white : .black)
                    .border(.gray)
                
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
                        Text("Reviewed").foregroundColor(.btnPrev)
                    }
                }
                .padding(0)
                Spacer().frame(height: 30)
                
            }
            // end VStack
            Spacer()
            Color(UIColor.clear).frame(width: 8)
        }
        .background(Color("viewBackgroundColorOnboarding"))
        .edgesIgnoringSafeArea(.bottom)

    }
    
}

#Preview {
    ReviewDocView(title: "<Title>", subtitle: "<sub-title>", content: "content", isReviewed: .constant(false))
}
