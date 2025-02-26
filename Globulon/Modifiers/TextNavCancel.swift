//
//  TextNavCancel.swift
//  Globulon
//
//  Created by David Holeman on 02/26/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct TextNavCancel: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        Text("Cancel")
            .foregroundStyle(
                colorScheme == .dark ? AppSettings.pallet.primaryLight : AppSettings.pallet.primary,
                colorScheme == .dark ? AppSettings.pallet.primaryLight : AppSettings.pallet.primary
            )
    }
}
