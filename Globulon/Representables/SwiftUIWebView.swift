//
//  SwiftUIWebView.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//


import SwiftUI
import WebKit
import Network

struct SwiftUIWebView: UIViewRepresentable {
    
    @Environment(\.colorScheme) private var colorScheme
    
    let url: URL?
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        return WKWebView(frame: .zero, configuration: config)  //frame CGRect
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let myURL = url else { return }
        let urlRequest = URLRequest(url: myURL)
        
        // Set background based on color scheme
        if colorScheme == .dark {
            // Dark mode
            uiView.isOpaque = false
            uiView.backgroundColor = UIColor.systemGray
        } else {
            uiView.isOpaque = false
            uiView.backgroundColor = UIColor.clear
        }
        
        /// Add a border
        //uiView.layer.borderWidth = 0.5
        
        //TODO: if problem with network handler try this by 1st accessing the handler then the published states:
        // - let networkHandler = NetworkHandler.shared
        // - let isConnected = networkHandler.isConnected
        
        LogEvent.print(module: "SwiftUIWebView()", message: "NetworkHandler.shared.isConnected: \(NetworkHandler.shared.isConnected) ")
        
        if NetworkHandler.shared.isConnected == true {
            uiView.load(urlRequest)
        } else {
            let str = "<p style=color:red>Document could not be accessed.</p><p>Check to be sure you are connected to the internet and then try again.</p>"
            let offlineContentHTML = "<meta name=viewport content=initial-scale=1.0/>" + "<div style=\"font-family: sans-serif; font-size: 15px\">" + str + "</div>"
            uiView.loadHTMLString(offlineContentHTML, baseURL: nil)
        }
        
        // TODO: Depreciated in iOS 17.4  Replaced with following code Reachability.checkReachability
//        Reachability.checkReachability { isReachable in
//            if isReachable {
//                print("Network is reachable.")
//                LogEvent.print(module: "SwiftUIWebView", message: "Network is reachable")
//                
//                uiView.load(urlRequest)
//                
//            } else {
//                let str = "<p style=color:red>Document could not be accessed.</p><p>Check to be sure you are connected to the internet and then try again.</p>"
//                let offlineContentHTML = "<meta name=viewport content=initial-scale=1.0/>" + "<div style=\"font-family: sans-serif; font-size: 15px\">" + str + "</div>"
//                uiView.loadHTMLString(offlineContentHTML, baseURL: nil)
//                LogEvent.print(module: "SwiftUIWebView", message: "Network is not reachable")
//            }
//            
//        }
        
    }
}
