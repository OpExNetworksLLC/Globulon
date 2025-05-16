//
//  AsyncProcessor.swift
//  Globulon
//
//  Created by David Holeman on 12/16/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import Combine

@MainActor class AsyncProcessor: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var description: String = "Idle"
    
    func performAsyncTask() async {
        
        guard !isProcessing else {
            LogManager.event(module: "AsyncProcessor.performAsyncTask()", message: "processing...")
            return
        }
        
        // Indicate the task has started
        self.isProcessing = true
        self.description = "Pending"
        
        do {
            LogManager.event(module: "AsyncProcessor.performAsyncTask()", message: "▶️ starting...")
            self.description = "Started"
            
            // Simulate an asynchronous operation with a delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
            
            // Simulate a successful completion
            self.isProcessing = false
            self.description = "Completed"
            
            LogManager.event(module: "AsyncProcessor.performAsyncTask()", message: "⏹️ ...finished")
        } catch {
            // Handle errors if the async task fails
            self.isProcessing = false
            LogManager.event(module: "⛔️ AsyncProcessor.performAsyncTask()", message: "Error: \(error.localizedDescription)")
        }
    }
}
