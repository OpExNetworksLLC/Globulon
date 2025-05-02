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

//struct SectionsJSON: Decodable {
//    let section_name: String
//    let section_desc: String
//    let section_rank: String
//
//    enum CodingKeys: String, CodingKey {
//        case section_name, section_desc, section_rank
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//
//        section_name = try container.decode(String.self, forKey: .section_name)
//        section_desc = try container.decode(String.self, forKey: .section_desc)
//
//        if let rawRank = try? container.decode(String.self, forKey: .section_rank) {
//            let trimmedRank = rawRank.trimmingCharacters(in: .whitespacesAndNewlines)
//            print("✅ Decoded section_rank: '\(trimmedRank)' for section '\(section_name)'")
//            section_rank = trimmedRank
//        } else {
//            print("❌ Failed to decode 'section_rank' for section '\(section_name)'")
//            section_rank = "?"
//        }
//    }
//}
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
