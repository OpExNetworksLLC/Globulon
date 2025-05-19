//
//  View+getRect.swift
//  Globulon
//
//  Created by David Holeman on 5/19/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

/// An extension on `View` that retrieves the bounds of the main screen
///
extension View {
    /// Retrieves the bounds of the main screen.
    ///
    /// - Returns: A `CGRect` representing the dimensions of the device's main screen.
    ///
    /// This can be useful for layout calculations or animations that depend on screen size.
    func getRect() -> CGRect {
        UIScreen.main.bounds
    }
}
