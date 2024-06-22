//
//  ArticleLocationsEnum.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

enum ArticleLocations : Int, CaseIterable {
    case local
    case remote
    case error

    var description: String {
        switch self {
        case .local: return "local"
        case .remote: return "remote"
        case .error: return "error"
        }
    }
}
