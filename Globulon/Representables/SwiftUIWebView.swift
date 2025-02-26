//
//  SwiftUIWebView.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//


import SwiftUI
import WebKit
import Network

struct SwiftUIWebView: UIViewRepresentable {
    
    @Environment(\.colorScheme) private var colorScheme
    let localHTMLFileName: String? // Add support for local HTML file name
    let url: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        return WKWebView(frame: .zero, configuration: config)
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let localHTMLFileName = localHTMLFileName,
           let filePath = Bundle.main.path(forResource: fileNameWithoutExtension(localHTMLFileName), ofType: "html") {
            // Load local HTML file
            let fileURL = URL(fileURLWithPath: filePath)
            let request = URLRequest(url: fileURL)
            uiView.load(request)
            
        } else if let myURL = url { // Fallback to handling a provided URL
            let urlRequest = URLRequest(url: myURL)
            
            if colorScheme == .dark {
                uiView.isOpaque = false
                uiView.backgroundColor = UIColor.systemGray
            } else {
                uiView.isOpaque = false
                uiView.backgroundColor = UIColor.clear
            }
            
            if NetworkHandler.shared.isConnected {
                uiView.load(urlRequest)
            } else {
                let str = "<p style=color:red>Document could not be accessed.</p><p>Check to be sure you are connected to the internet and then try again.</p>"
                let offlineContentHTML = "<meta name=viewport content=initial-scale=1.0/>" + "<div style=\"font-family: sans-serif; font-size: 15px\">" + str + "</div>"
                uiView.loadHTMLString(offlineContentHTML, baseURL: nil)
            }
        } else {
            // Handle missing inputs or fallback content
            let fallbackContent = "<h1>Content Unavailable</h1><p>Unable to load the content.</p>"
            uiView.loadHTMLString(fallbackContent, baseURL: nil)
        }
    }
    
    /// Helper function to strip ".html" extension if present
    private func fileNameWithoutExtension(_ fileName: String) -> String {
        return fileName.hasSuffix(".html") ? String(fileName.dropLast(5)) : fileName
    }
}
