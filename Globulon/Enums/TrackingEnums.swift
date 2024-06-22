//
//  TrackingEnums.swift
//  ViDrive
//
//  Created by David Holeman on 3/4/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

enum TrackingSampleRateEnum: Int, CaseIterable, Equatable {

    case one   = 1
    case two   = 2
    case three = 3
    case four  = 4
    case five  = 5

    var id: Self { self }

    var description: String {
        //return String(self.rawValue)
        switch self {
        case .one   : return "1 sec"
        case .two   : return "2 sec"
        case .three : return "3 sec"
        case .four  : return "4 sec"
        case .five  : return "5 sec"
 }
    }
}

enum TrackingSpeedThresholdEnum: Double, CaseIterable, Equatable {
    
    case mph05 = 2.2352
    case mph10 = 4.4704
    
    var id: Self { self }
    var description: String {
        switch self {
        case .mph05 : return " 5 mph"
        case .mph10 : return "10 mph"
        }
    }
}
