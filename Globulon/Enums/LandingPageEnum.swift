//
//  LandingPageEnum.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//

import Foundation

enum LandingPageEnum: Int, CaseIterable, Equatable {
    case home     = 0
    case location = 1
    case feed     = 2
    case trips    = 3
    case history  = 4
    
    var description: String {
        switch self {
        case .home     : return "home"
        case .location : return "location"
        case .feed     : return "feed"
        case .trips    : return "trips"
        case .history  : return "history"
        }
    }
}
