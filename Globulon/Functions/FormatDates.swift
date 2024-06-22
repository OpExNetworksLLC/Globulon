//
//  FormatDates.swift
//  ViDrive
//
//  Created by David Holeman on 2/15/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// Format the date for display
//
func formatDateStampM(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
    return formatter.string(from: date)
}

// MARK: dd/mm/yy hh:mm:ss am/pm
func formatDateStampA(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-YY hh:mm:ss a"
    return formatter.string(from: date)
}

// MARK:
func formatDateStampDayMonthTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d  hh:mm a"
    formatter.amSymbol = "am"
    formatter.pmSymbol = "pm"
    return formatter.string(from: date)
}

// MARK:
func formatDateStampDayMonth(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter.string(from: date)
}

// MARK:
func formatDateStampTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm a"
    formatter.amSymbol = "am"
    formatter.pmSymbol = "pm"
    return formatter.string(from: date)
}

// MARK: Format date into MM/dd/yyyy format
func formatDateUS(date: Date) -> String {
    let formatter = DateFormatter()
    //formatter.dateStyle = .short
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

// MARK: Export filename with date
func formatDateStampFile(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "YYYY-MM-dd HH-mm-ss"
    return formatter.string(from: date)
}

func formatDateYearMonth(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM"
    return formatter.string(from: date)
}

func formatDateDatestampToMonthYear(_ date: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"

    if let result = dateFormatter.date(from: date) {
        dateFormatter.dateFormat = "MMMM  yyyy"
        return dateFormatter.string(from: result)
    } else {
        /// Return what was submitted if it can't be reformatted
        return date
    }
}

func formatDateDatestampToYear(_ date: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"

    if let result = dateFormatter.date(from: date) {
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: result)
    } else {
        /// Return what was submitted if it can't be reformatted
        return date
    }
}

func formatDateDatestampToMonth(_ date: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"

    if let result = dateFormatter.date(from: date) {
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: result)
    } else {
        /// Return what was submitted if it can't be reformatted
        return date
    }
}

func formatTimestampToDatestamp(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"
    return dateFormatter.string(from: date)
}
