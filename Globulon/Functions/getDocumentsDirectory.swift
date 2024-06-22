//
//  getDocumentsDirectory.swift
//  ViDrive
//
//  Created by David Holeman on 3/21/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func getDocumentsDirectory() -> URL {
    // Find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    
    // Just use the first one, which should be the only one
    return paths[0]
}
