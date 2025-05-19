//
//  View+hideKeyboard.swift
//  Globulon
//
//  Created by David Holeman on 5/19/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

// MARK: - Hide Keyboard on Tap outside TextField

extension View {
    /// Dismisses the keyboard by resigning the first responder status from the currently focused input view.
    ///
    /// This function works by sending the `resignFirstResponder` action to `nil`,
    /// which propagates through the responder chain. The currently focused input
    /// (such as a `UITextField` or `UITextView`) will resign its status, causing
    /// the keyboard to dismiss.
    ///
    /// Typical use case: call this when the user taps outside an input field.
    ///
    func hideKeyboard() {
        // Send an action to resign the first responder (i.e., dismiss the keyboard).
        // `to: nil` and `from: nil` lets the system figure out which responder should handle it.
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), // the action selector
            to: nil,    // no specific target; the system finds the appropriate responder
            from: nil,  // no specific sender
            for: nil    // no specific event context
        )
    }
}
