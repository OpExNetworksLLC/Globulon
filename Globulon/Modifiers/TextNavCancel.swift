//
//  TextNavCancel.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct TextNavCancel: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Text("Cancel")
            .foregroundStyle(
                colorScheme == .dark ? AppValues.pallet.primaryLight : AppValues.pallet.primary,
                colorScheme == .dark ? AppValues.pallet.primaryLight : AppValues.pallet.primary
            )
    }
}
