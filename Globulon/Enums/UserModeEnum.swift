//
//  UserModeEnum.swift
//  ViDrive
//
//  Created by David Holeman on 2/13/24.
//

import Foundation

enum UserModeEnum: Int, CaseIterable, Equatable {
    case production = 0
    case development = 1
    case test = 2
    
    var description: String {
        switch self {
        case .production: return "production"
        case .development: return "development"
        case .test: return "test"
        }
    }
}
