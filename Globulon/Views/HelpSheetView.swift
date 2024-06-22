//
//  HelpSheetView.swift
//  ViDrive
//
//  Created by David Holeman on 2/14/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct HelpSheetView: View {
    @Binding var isShowHelp: Bool
    var body: some View {
        VStack {
//            RoundedRectangle(cornerRadius: 5)
//                .frame(width: 36, height: 6)
//                .foregroundColor(.gray)
//            .padding(.top, 8)
//            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text("Help:")
                        .padding(.bottom, 8)
                    Spacer()
                }
                .presentationDetents([.medium, .large])
                .padding(.top, 32)
                Spacer()
            }
            Spacer()

            Button(action: {
                isShowHelp = false
            }) {
                HStack {
                    Spacer()
                    Text("Dismiss")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                    Spacer()
                }
            }
            //.frame(maxWidth: .infinity)
            .background(Color.green)
            .edgesIgnoringSafeArea(.horizontal)
            .cornerRadius(5)
        }
        .padding()
    }
}

#Preview {
    HelpSheetView(isShowHelp: .constant(true) )
}
