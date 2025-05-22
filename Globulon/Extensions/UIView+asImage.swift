//
//  UIView+asImage.swift
//  Globulon
//
//  Created by David Holeman on 5/19/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

// MARK: - SwiftUI Rect Getter

/// A utility SwiftUI view that reads and reports its size and position in global coordinates.
///
/// Use `RectGetter` to dynamically capture the global frame of any SwiftUI view by embedding it
/// and binding it to a `CGRect` state variable. This is particularly useful when you need layout
/// information for animation or coordinate conversion.
///
struct RectGetter: View {
    @Binding var rect: CGRect

    var body: some View {
        GeometryReader { proxy in
            createView(proxy: proxy)
        }
    }

    /// Captures the global frame from the geometry proxy and assigns it asynchronously.
    private func createView(proxy: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            self.rect = proxy.frame(in: .global)
        }
        return Rectangle().fill(Color.clear) // invisible element just to enable frame capture
    }
}

// MARK: - UIView Snapshot

extension UIView {
    /// Captures a snapshot of the view within the specified bounds and returns it as a `UIImage`.
    ///
    /// - Parameter rect: The rectangle to snapshot, usually the bounds of the view.
    /// - Returns: A `UIImage` rendering of the current visual contents of the view in the given rect.
    ///
    /// Useful for rendering view content as an image, for example in exporting, sharing, or caching.
    func asImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
