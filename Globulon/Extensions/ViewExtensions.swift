//
//  ViewExtensions.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

// MARK: Extension to get Screen Rect...
extension View {
    func getRect()->CGRect{
        return UIScreen.main.bounds
    }
}
// MARK: - Hide Keyboard on Tap outside TextField
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
// MARK: -  UIImage from View 1/2
extension UIView {
    func asImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

// MARK: -  UIImage from View 2/2
struct RectGetter: View {
    @Binding var rect: CGRect

    var body: some View {
        GeometryReader { proxy in
            self.createView(proxy: proxy)
        }
    }

    func createView(proxy: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            self.rect = proxy.frame(in: .global)
        }

        return Rectangle().fill(Color.clear)
    }
}

// MARK: - onSubmit
extension View {
    func onSubmit(perform action: @escaping () -> Void) -> some View {
        return modifier(SubmitModifier(action: action))
    }
}

struct SubmitModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            action()
        }
    }
}
