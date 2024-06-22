//
//  TermsView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2022 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct TermsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var userSettings: UserSettings
    
    @State var isTerms: Bool = false
    
    var body: some View {
        HStack {
            Spacer().frame(width: 16)
            VStack(alignment: .leading) {
                
                Group {
                    Spacer().frame(height: 40)
                    Image(colorScheme == .dark ? AppValues.logos.appLogoDarkMode : AppValues.logos.appLogoTransparent)
                        .resizable()
                        .frame(width: 124, height: 124, alignment: .center)
                        .padding(.bottom, 16)
                    
                    Text("Terms & Conditions")
                        .font(.system(size: 24))
                        .fontWeight(.regular)
                        .padding(.bottom, 16)
                    Text("Review the terms and conditions.  You must scroll to the end to accept")
                        .font(.system(size: 16))
                    
                    
                    Spacer().frame(height: 30)
                    
                    HStack {
                        HTMLStringView(htmlContent: termsData.content)
                        //.border(colorScheme == .dark ? .white : .black)
                            .border(.gray)
                        //                        .overlay(
                        //                            GeometryReader { proxy in
                        //                                Color.clear.onAppear { print(proxy.size.height)}
                        //                            })
                    }


                
                Spacer().frame(height: 30)
                
                HStack {
                    /// Declined button
                    Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isReset"), object: nil)
                        }
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
                    //.padding()
                    
                    Spacer()
                    
                    /// Accepted button
                    Button(action: {
                        
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            NotificationCenter.default.post(name: Notification.Name("isTerms"), object: nil)
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            HStack {
                                Text("Accept")
                                    .foregroundColor(userSettings.isTerms ? .gray : .blue)
                                Image(systemName: "arrow.right")
                                    .resizable()
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .padding()
                                    .background(userSettings.isTerms ? .gray : Color("btnNext"))
                                    .cornerRadius(30)
                            }
                        }
                    }
                    .disabled(userSettings.isTerms)  // Disable if if already isAccepted is true
                    
                } // end HStack
                Spacer().frame(height: 30)
            } // end VStack

            } // end HStack
            Spacer().frame(width: 16)
        } // end view
        .background(Color("viewBackgroundColorTerms"))
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
        
    } // end struct
}


struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView()
            .environmentObject(UserSettings())
    }
}

