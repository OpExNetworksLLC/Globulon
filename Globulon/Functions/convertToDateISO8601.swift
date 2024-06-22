//
//  convertToDateISO8601.swift
//  ViDrive
//
//  Created by David Holeman on 3/31/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

/// Converts a date string into a `Date` object.
/// - Parameter dateString: The date string to convert.
/// - Returns: An optional `Date` object. Returns `nil` if the conversion fails.
///
func convertToDateISO8601(from dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // ISO 8601 format
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Set the timezone to UTC

    return dateFormatter.date(from: dateString)
}
