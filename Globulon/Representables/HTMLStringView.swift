//
//  HTMLStringView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import WebKit
import SwiftUI

struct HTMLStringView: UIViewRepresentable {
    
    @Environment(\.colorScheme) private var colorScheme
    
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
        
        // Set background based on color scheme
        if colorScheme == .dark {
            // Dark mode
            uiView.isOpaque = false
            uiView.backgroundColor = UIColor.systemGray
        } else {
            uiView.isOpaque = false
            uiView.backgroundColor = UIColor.clear
        }
    }

}
