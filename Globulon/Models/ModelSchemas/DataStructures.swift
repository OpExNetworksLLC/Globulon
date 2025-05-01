//
//  DataStructures.swift
//  ViDrive
//
//  Created by David Holeman on 3/22/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation

// MARK: - Data structures

struct GPSDataBuffer: Codable, Hashable {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var speed: Double
    var processed: Bool
    var code: String
    var note: String
}

// Structures for the JSON file that contains the FAQ content
struct ArticlesJSON: Decodable {
    let updated_at: String
    let sections: [SectionsJSON]
    let articles: [ArticleJSON]
}

struct SectionsJSON: Decodable {
    let section_name: String
    let section_desc: String
    let section_rank: String
}

struct ArticleJSON: Decodable {
    let id: String
    let title: String
    let summary: String
    let search: String
    let section_names: [String]
    let label_names: [String]
    let created_at: String
    let updated_at: String
    let body: String
    let author: String
}
