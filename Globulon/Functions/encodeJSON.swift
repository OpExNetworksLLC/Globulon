//
//  encodeJSON.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK:  Used by TermsClass
// TODO:  Spend time looking at this and it's use in termsData class
func encodeJSON<T: Codable>(structure: T, formatted: Bool) -> String {
    let encoder = JSONEncoder()
    if formatted { encoder.outputFormatting = [.sortedKeys, .prettyPrinted] }
    guard let jsonData = (try? encoder.encode(structure)) else { return "{}" }
    let jsonString = String(data: jsonData, encoding: .utf8)!
    return jsonString
}
