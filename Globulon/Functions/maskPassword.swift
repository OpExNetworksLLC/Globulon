//
//  maskPassword.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

func maskPassword(_ password: String) -> String {
    // Check if masking is enabled and return the appropriate result
    return AppSettings.log.isPasswordMaskEnabled ?
        String(repeating: "*", count: password.count) :
        password
}
