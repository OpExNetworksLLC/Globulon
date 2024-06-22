//
//  fileURLInDocumentsDirectory.swift
//  ViDrive
//
//  Created by David Holeman on 3/22/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func fileURLInDocumentsDirectory(fileName: String) -> URL? {
    // Get the path to the Documents directory
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("Documents directory not found.")
        return nil
    }
    
    // Append the file name to the Documents directory path
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    return fileURL
}
