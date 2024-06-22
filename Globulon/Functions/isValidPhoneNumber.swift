//
//  isValidPhoneNumber.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK: Validate phone number as it's being entered.
func isValidPhoneNumber(testStr:String) -> Bool {
    let phoneRegEx = "\\+[1{1}]\\s\\(\\d{3}\\)\\s\\d{3}-\\d{4}$"
    let phoneTest = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
    return phoneTest.evaluate(with: testStr)
}
