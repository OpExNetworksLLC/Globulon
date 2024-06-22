//
//  DateInfoClass.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

class DateInfo {
    static var zeroDate: Date {
        get {
            let formatter = DateFormatter()
            let strTime = "1900-01-01 00:00:00 -0000"
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            formatter.date(from: strTime)
            return formatter.date(from: strTime)!
        }
    }
    
    class func isZeroDate(date: Date) -> Bool {
        if date == zeroDate {
            return true
        } else {
            return false
        }
    }
    
    class func convertToDate(date: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let date = (dateFormatter.date(from: date) ?? DateInfo.zeroDate) as Date
        return date
    }
}
