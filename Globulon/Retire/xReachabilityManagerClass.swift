////
////  ReachabilityManagerClass.swift
////  ViDrive
////
////  Created by David Holeman on 3/17/24.
////  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
////
//
//import SwiftUI
//import Combine
//
//class ReachabilityManager: ObservableObject {
//    static let shared = ReachabilityManager()
//    @Published var isNetworkReachable: Bool = false
//    private var cancellables = Set<AnyCancellable>()
//    
//    private init() {
//        Reachability.checkReachability { [weak self] isReachable in
//            DispatchQueue.main.async {
//                self?.isNetworkReachable = isReachable
//            }
//        }
//    }
//}
//
///// Example use case in SwiftUI"
/////
///*
//struct ContentView: View {
//    @ObservedObject var reachabilityManager = ReachabilityManager.shared
//    
//    var body: some View {
//        VStack {
//            if reachabilityManager.isNetworkReachable {
//                Text("Network is reachable.")
//                    .foregroundColor(.green)
//            } else {
//                Text("Network is not reachable.")
//                    .foregroundColor(.red)
//            }
//        }
//        .onAppear {
//            // Optionally, perform additional actions when the view appears
//        }
//    }
//}
//*/
