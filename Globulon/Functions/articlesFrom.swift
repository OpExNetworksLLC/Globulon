//
//  articlesFrom.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK:
func articlesFrom() -> String {
    let storedTheme = UserDefaults.standard.integer(forKey: "articlesLocation")
    let articlesLocation = ArticleLocations(rawValue: storedTheme) ?? .local
    let value = articlesLocation.description
    return value
}
