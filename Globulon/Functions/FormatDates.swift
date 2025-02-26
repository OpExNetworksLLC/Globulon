//
//  FormatDates.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK: Format date into MM/dd/yyyy format
//
func formatDate(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yyyy"
    return formatter.string(from: date)
}
// MARK: Format date into m/d/yy, h:mm:ss AM/PM
func formatDateShortUS(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter.string(from: date)
}
