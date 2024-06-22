//
//  saveTextToFile.swift
//  ViDrive
//
//  Created by David Holeman on 3/21/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func saveTextToFile(_ text: String, fileName: String) {
    let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
    
    do {
        // Write the text to the file
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        print("File saved: \(fileURL.absoluteString)")
    } catch {
        // Handle any errors
        print("Failed to save file: \(error.localizedDescription)")
    }
}
