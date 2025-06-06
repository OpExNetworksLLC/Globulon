//
//  ArticlesClass.swift
//  GeoGato
//
//  Created by David Holeman on 4/24/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftData
import MapKit


@MainActor
class ArticlesV1 {
    
    private static var isLoading = false
    
    @MainActor class func load(completion: @escaping @Sendable (Bool, String) -> Void) async {
        guard !isLoading else {
            completion(false, "Articles already loading")
            return
        }

        isLoading = true
        defer { isLoading = false }
        
        LogManager.event(module: "Articles.load()", message: "▶️ starting...")

        let articlesLocation = UserSettings().articlesLocation
        
        switch articlesLocation.description {
        case "remote":
            await handleRemoteLoading(completion: completion)
        case "local", "error":
            handleLocalLoading(completion: completion)
        default:
            completion(false, "Invalid articles location")
        }
        
        LogManager.event(module: "Articles.load()", message: "⏹️ ...finished")
    }
    
    @MainActor private class func handleRemoteLoading(completion: @escaping @Sendable (Bool, String) -> Void) async {
        LogManager.event(module: "Articles.load()", message: "source (.remote)")

        guard NetworkManager.shared.isConnected else {
            completion(false, "No internet connection. Connect to the internet and try again.")
            return
        }

        guard let url = URL(string: AppSettings.articlesLocation.remote) else {
            completion(false, "Invalid URL for articles file.")
            return
        }

        let isReachable = await isURLReachable(url: url)
        guard isReachable else {
            completion(false, "URL is not reachable.")
            return
        }

        let updateRequired = await isUpdateRequired()
        if updateRequired {
            await fetchAndUpdateArticles { success, message in
                if success {
                    await printSectionsAndArticles()
                }
                completion(success, message)
            }
        } else {
            completion(true, "Remote articles update is not required")
        }
    }
    
//    @MainActor private class func handleRemoteLoading(completion: @escaping @Sendable (Bool, String) -> Void) async {
//        LogManager.event(module: "Articles.load()", message: "source (.remote)")
//        
//        guard NetworkManager.shared.isConnected else {
//            completion(false, "No internet connection. Connect to the internet and try again.")
//            return
//        }
//        
//        guard let url = URL(string: AppSettings.articlesLocation.remote) else {
//            completion(false, "Invalid URL for articles file.")
//            return
//        }
//        isURLReachable(url: url) { isReachable in
//            Task { @MainActor in
//                guard isReachable else {
//                    completion(false, "URL is not reachable.")
//                    return
//                }
//                
//                isUpdateRequired { updateRequired in
//                    if updateRequired {
//                        Task {
//                            await fetchAndUpdateArticles { success, message in
//                                await MainActor.run {
//                                    if success {
//                                        printSectionsAndArticles()
//                                    }
//                                    completion(success, message)
//                                }
//                            }
//                        }
//                    } else {
//                        completion(true, "Remote articles update is not required")
//                    }
//                }
//            }
//        }
//    }
    
    private class func handleLocalLoading(completion: @escaping @Sendable (Bool, String) -> Void) {
        LogManager.event(module: "Articles.load()", message: "source (.local)")

        isUpdateRequired { updateRequired in
            Task { @MainActor in
                if updateRequired {
                    let fetched = fetchArticles(from: .local)
                    let message = fetched ? "Local sections and articles loaded" : "Sections and articles failed to load"
                    if fetched {
                        UserSettings.init().articlesDate = articlesDate()
                        printSectionsAndArticles()
                    }
                    completion(fetched, message)
                } else {
                    completion(true, "A local articles update was not required")
                }
            }
        }
    }
    
    private class func fetchAndUpdateArticles(completion: @escaping @Sendable (Bool, String) async -> Void) async {
        let fetched = fetchArticles(from: .remote)
        let message = fetched ? "Sections and articles loaded" : "Sections and articles failed to load"
        if fetched {
            printSectionsAndArticles()
        }
        await completion(fetched, message)
    }
    
    private class func fetchArticles(from location: ArticleLocations) -> Bool {
        do {
            let data = try loadData(from: location)
            let sectionsCount = decodeSections(from: data)
            let articlesCount = decodeArticles(from: data)
            
            return sectionsCount > 0 && articlesCount > 0
        } catch {
            LogManager.event(module: "Articles.fetchArticles", message: "Error: \(error)")
            return false
        }
    }
    
    private class func loadData(from location: ArticleLocations) throws -> Data {
        switch location {
        case .local:
            guard let path = Bundle.main.path(forResource: AppSettings.articlesLocation.local, ofType: "json") else {
                throw NSError(domain: "Invalid path", code: 0, userInfo: nil)
            }
            return try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
        case .remote:
            guard let url = URL(string: AppSettings.articlesLocation.remote) else {
                throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
            }
            return try Data(contentsOf: url, options: .alwaysMapped)
        case .error:
            guard let path = Bundle.main.path(forResource: AppSettings.articlesLocation.error, ofType: "json") else {
                throw NSError(domain: "Invalid path", code: 0, userInfo: nil)
            }
            return try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
        }
    }
    
    private class func decodeSections(from data: Data) -> Int {
        do {
            let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: data)
            let context = ModelContainerProvider.sharedContext
            
            for section in decoded.sections {
                let sectionEntity = HelpSection(id: section.section_name, section: section.section_desc, rank: section.section_rank)
                context.insert(sectionEntity)
            }
            
            try context.save()
            return decoded.sections.count
        } catch {
            LogManager.event(module: "Articles.decodeSections", message: "Error: \(error)")
            return 0
        }
    }
    
    private class func decodeArticles(from data: Data) -> Int {
        do {
            let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: data)
            let context = ModelContainerProvider.sharedContext
            let sections = try context.fetch(FetchDescriptor<HelpSection>())
            var articleCount = 0
            
            for section in sections {
                let articles = decoded.articles.filter { $0.section_names.contains(section.id) }
                
                for article in articles {
                    let articleEntity = HelpArticle(
                        id: article.id,
                        title: article.title,
                        summary: article.summary,
                        search: article.search.lowercased(),
                        section: article.section_names.first { $0 == section.id } ?? "",
                        body: article.body
                    )
                    articleEntity.toSection = section
                    context.insert(articleEntity)
                    articleCount += 1
                }
            }
            
            try context.save()
            return articleCount
        } catch {
            LogManager.event(module: "Articles.decodeArticles", message: "Error: \(error)")
            return 0
        }
    }
    
    private class func isUpdateRequired(completion: @escaping @Sendable (Bool) -> Void) {
        do {
            let data = try loadData(from: UserSettings().articlesLocation)
            let articlesDate = decodeArticlesDate(from: data)
            let currentArticlesDate = UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
            
            if currentArticlesDate < articlesDate {
                LogManager.event(module: "Articles.isUpdateRequired()", message: "Yes \(currentArticlesDate) = \(articlesDate)")
                completion(true)
            } else {
                LogManager.event(module: "Articles.isUpdateRequired()", message: "No \(currentArticlesDate) > \(articlesDate)")
                completion(false)
            }
        } catch {
            LogManager.event(module: "Articles.isUpdateRequired", message: "Error: \(error)")
            completion(false)
        }
    }
    
    private class func decodeArticlesDate(from data: Data) -> Date {
        do {
            let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: data)
            return DateInfo.convertToDate(date: decoded.updated_at)
        } catch {
            LogManager.event(module: "Articles.decodeArticlesDate", message: "Error: \(error)")
            return DateInfo.zeroDate
        }
    }
    
    private class func isURLReachable(url: URL, completion: @escaping @Sendable (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                completion(httpResponse.statusCode == 200)
            } else {
                completion(false)
            }
        }.resume()
    }
    
    class func deleteArticles() {
        LogManager.event(module: "Articles.deleteArticles()", message: "▶️ starting...")
        deleteEntity(named: "HelpArticle")
        deleteEntity(named: "HelpSection")
        LogManager.event(module: "Articles.deleteArticles()", message: "⏹️ ...finished")

    }
    
    private class func deleteEntity(named entityName: String) {
        let context = ModelContainerProvider.sharedContext
        
        do {
            if entityName == "HelpArticle" {
                let articles = try context.fetch(FetchDescriptor<HelpArticle>())
                guard !articles.isEmpty else {
                    LogManager.event(module: "Articles.deleteEntity()", message: "No articles data to delete")
                    return
                }
                try context.delete(model: HelpArticle.self)
            } else if entityName == "HelpSection" {
                let sections = try context.fetch(FetchDescriptor<HelpSection>())
                guard !sections.isEmpty else {
                    LogManager.event(module: "Articles.deleteEntity()", message: "No sections data to delete")
                    return
                }
                try context.delete(model: HelpSection.self)
            }
            
            LogManager.event(module: "Articles.deleteEntity()", message: "\(entityName) entity deleted")
        } catch {
            LogManager.event(module: "Articles.deleteEntity()", message: "Failed to delete \(entityName) data: \(error)")
        }
    }
    
    class func articlesDate() -> Date {
        do {
            let data = try loadData(from: UserSettings().articlesLocation)
            return decodeArticlesDate(from: data)
        } catch {
            LogManager.event(module: "Articles.articlesDate", message: "Error: \(error)")
            return UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
        }
    }
    
    class func printSectionsAndArticles() {
        do {
            let context = ModelContainerProvider.sharedContext
            let sections = try context.fetch(FetchDescriptor<HelpSection>())
// TODO:
//            var sortedSections: [HelpSection] {
//                sections.sorted { $0.rank < $1.rank }
//            }
            let sortedSections = sections.sorted {
                $0.rank.localizedStandardCompare($1.rank) == .orderedAscending
            }
            for section in sortedSections {
                print("Sorted Section: [\(section.section)] (\(section.toArticles?.count ?? 0))")
                
                var index = 0
                while index < section.toArticles?.count ?? 0 {
                    print("- \(section.toArticles?[index].title ?? "")")
                    index += 1
                }
            }
        } catch {
            LogManager.event(module: "Articles.printSectionsAndArticles", message: "Error: \(error)")
        }
    }

    private class func isURLReachable(url: URL) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        return await withCheckedContinuation { continuation in
            URLSession.shared.dataTask(with: request) { _, response, _ in
                if let httpResponse = response as? HTTPURLResponse {
                    continuation.resume(returning: httpResponse.statusCode == 200)
                } else {
                    continuation.resume(returning: false)
                }
            }.resume()
        }
    }
    
    private class func isUpdateRequired() async -> Bool {
        do {
            let data = try loadData(from: UserSettings().articlesLocation)
            let articlesDate = decodeArticlesDate(from: data)
            let currentArticlesDate = UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate

            if currentArticlesDate < articlesDate {
                LogManager.event(module: "Articles.isUpdateRequired()", message: "Yes \(currentArticlesDate) = \(articlesDate)")
                return true
            } else {
                LogManager.event(module: "Articles.isUpdateRequired()", message: "No \(currentArticlesDate) > \(articlesDate)")
                return false
            }
        } catch {
            LogManager.event(module: "Articles.isUpdateRequired", message: "Error: \(error)")
            return false
        }
    }
    
}
//extension Articles {
//    static func loadAsync() async -> (Bool, String) {
//        await withCheckedContinuation { continuation in
//            Task { @MainActor in
//                await Articles.load { success, message in
//                    continuation.resume(returning: (success, message))
//                }
//            }
//        }
//    }
//}
//extension Articles {
//    static func loadAsync() async -> (Bool, String) {
//        await withCheckedContinuation { continuation in
//            Task {
//                await Articles.load { success, message in
//                    continuation.resume(returning: (success, message))
//                }
//            }
//        }
//    }
//}
