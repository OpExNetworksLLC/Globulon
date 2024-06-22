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
                colorScheme == .dark ? AppValues.pallet.primaryLight : AppValues.pallet.primary,
                colorScheme == .dark ? AppValues.pallet.primaryLight : AppValues.pallet.primary
            )
            .aspectRatio(contentMode: .fit)
    }
}
