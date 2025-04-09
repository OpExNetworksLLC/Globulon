//
//  articlesLocation.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK: - Return where the articles are store

func articlesLocation() -> String {
    let storedTheme = UserDefaults.standard.integer(forKey: "articlesLocation")
    let articlesLocation = ArticleLocations(rawValue: storedTheme) ?? .local
    let value = articlesLocation.description
    return value
}
