//
//  ButtonModifiers.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct RoundedCorners: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(10)
            .overlay(
                   RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 1)
               )
    }
}
