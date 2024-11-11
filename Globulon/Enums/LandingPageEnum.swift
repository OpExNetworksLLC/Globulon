//
//  LandingPageEnum.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//

import Foundation

enum LandingPageEnum: Int, CaseIterable, Equatable {
    case home     = 0
    case activity = 1
    case motion   = 2
    case trips    = 3
    case history  = 4
    
    var description: String {
        switch self {
        case .home     : return "home"
        case .activity : return "activity"
        case .motion   : return "motion"
        case .trips    : return "trips"
        case .history  : return "history"
        }
    }
}
