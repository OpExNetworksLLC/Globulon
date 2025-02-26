//
//  ImageNavCancel.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct ImageNavCancel: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Image("symNavCancel")
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(
                colorScheme == .dark ? AppSettings.pallet.primaryLight : AppSettings.pallet.primary,
                colorScheme == .dark ? AppSettings.pallet.primaryLight : AppSettings.pallet.primary
            )
            .aspectRatio(contentMode: .fit)
    }
}
