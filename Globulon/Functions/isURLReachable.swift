//
//  isUrLReachable.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

// MARK: is URL reachable
func isURLReachable(url: URL, completion: @escaping (Bool) -> Void) {
    let session = URLSession.shared
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD" // Use HEAD request to check for the existence of the resource without downloading the entire content
    
    let task = session.dataTask(with: request) { (data, response, error) in
        if let httpResponse = response as? HTTPURLResponse {
            // Check if the status code indicates success
            print("* no error reaching url \(httpResponse.statusCode)")
            completion((200...299).contains(httpResponse.statusCode))
        } else {
            // If there's no HTTP response or an error occurred, consider the URL unreachable
            print("* error reaching url")
            completion(false)
        }
    }
    
    task.resume()
}
