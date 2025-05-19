//
//  View+onSubmit.swift
//  Globulon
//
//  Created by David Holeman on 5/19/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

// MARK: - SubmitModifier

/// A custom SwiftUI `ViewModifier` that listens for keyboard dismissal and triggers a given action.
///
/// This modifier listens for `UIResponder.keyboardWillHideNotification` from the system.
/// When the keyboard is about to be dismissed, it executes the provided closure. This is
/// useful for saving data or reacting to text input completion in forms or text fields.

struct SubmitModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        // Attach a listener to the view that triggers when the keyboard will hide
        content.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            action()
        }
    }
}

// MARK: - View Extension for onSubmit

extension View {
    /// A convenience method that applies the `SubmitModifier` to any view.
    ///
    /// Use this to execute custom logic (like saving form data) when the keyboard is dismissed.
    /// It abstracts away the notification handling, making it easy to attach this behavior
    /// in a declarative SwiftUI style.
    ///
    /// - Parameter action: The closure to execute when the keyboard is dismissed.
    /// - Returns: A modified view that responds to keyboard dismissal.
    func onSubmit(perform action: @escaping () -> Void) -> some View {
        self.modifier(SubmitModifier(action: action))
    }
}
