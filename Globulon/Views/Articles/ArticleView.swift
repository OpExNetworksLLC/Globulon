//
//  ArticlesView.swift
//  Globulon
//
//  Created by David Holeman on 02/26/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct ArticleView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var title: String?
    var summary: String?
    var content: String?
    
    var body: some View {
        HStack {
            Spacer().frame(width: 16)
           
            VStack(alignment: .leading) {
                Spacer().frame(height: 30)
                Text(title ?? "no title")
                    .font(.system(size: 24))
                    .fontWeight(.regular)
                    .padding(.bottom, 16)
                Text(summary ?? "no summary")
                    .font(.system(size: 16))
                
                Spacer().frame(height: 30)
                
                HStack {
                    let st = content ?? "No Article."
                    let content = "<meta name=viewport content=initial-scale=1.0/>" + "<div style=\"font-family: sans-serif; font-size: 15px\">" + st + "</div>"
                    HTMLStringView(htmlContent: content)
                        .border(.gray)
                }
                
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()

                }
                ) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .symbolVariant(.circle)
                            .font(.system(size: 60, weight: .ultraLight))
//                            .resizable()
//                            .foregroundColor(.white)
//                            .frame(width: 30, height: 30)
//                            .padding()
//                            .background(Color("btnNextOnboarding"))
//                            .cornerRadius(30)
                        Text("Back").foregroundColor(.blue)
                    }
                }
                .padding(0)
                //Spacer().frame(height: 30)
            }
            Spacer().frame(width: 16)
        } // end HStack
        //.background(Color("viewBackgroundColor"))
        .navigationBarTitle("FAQ")
        
    } // end View
}

#Preview {
    ArticleView()
}
