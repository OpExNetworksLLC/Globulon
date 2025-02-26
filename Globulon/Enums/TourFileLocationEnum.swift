//
//  TourFileLocationEnum.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

enum TourFileLocationEnum : Int, CaseIterable {
    case bundle
    case local
    case remote

    var description: String {
        switch self {
        case .bundle: return "bundle"
        case .local: return "local"
        case .remote: return "remote"
        }
    }
}
