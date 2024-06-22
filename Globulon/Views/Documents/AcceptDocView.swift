//
//  AcceptDocView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct AcceptDocView: View {
    @Environment(\.presentationMode) var presentationMode
    //@ObservedObject var globalVariables = GlobalVariables()
    
    var title: String
    var subtitle: String
    var content: String
    @Binding var isAccepted: Bool
    
    var body: some View {
        HStack {
            Color("viewBackgroundColorAcceptDoc").frame(width: 8)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 32))
                    .padding(.top, 0)
                    .padding(.bottom, 24)
                Text(subtitle)
                    .font(.system(size: 24))
                    .padding(.bottom, 40)
                HTMLStringView(htmlContent: content)
                    //.border(colorScheme == .dark ? .white : .black)
                    .border(.gray)
                
                Spacer()
                
                HStack {
                    /// Declined button
                    Button(action: {
                        isAccepted = false
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Image(systemName: "arrow.left")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(Color("btnPrev"))
                                .cornerRadius(30)
                            Text("Decline").foregroundColor(.blue)
                        }
                    }

                    .disabled(isAccepted ? false : true)
                    
                    Spacer()
                    
                    /// Accepted button
                    Button(action: {
                        isAccepted = true
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Text("Accept")
                                .foregroundColor(isAccepted ? .blue : .blue)
                            Image(systemName: "arrow.right")
                                .resizable()
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(isAccepted ? Color("btnNext") : Color("btnNext"))
                                .cornerRadius(30)
                        }
                    }
                    //.disabled(isAccepted)  // Disable if if already isAccepted is true
                }
            }
            Spacer()
            Color("viewBackgroundColorAcceptDoc").frame(width: 8)
        }

        //FIX .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
        
        .padding(.top, UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first?.safeAreaInsets.top)
        
        .background(Color("viewBackgroundColorAcceptDoc"))
    }
}

struct AcceptDocView_Previews: PreviewProvider {
    static var previews: some View {
        AcceptDocView(title: "<Title>", subtitle: "You must scroll to the end to Accept.", content: termsData.content, isAccepted: .constant(false))
    }
}
