import Foundation
import CoreLocation
import SwiftData
import MapKit

@MainActor
final class ArticlesV2 {
    
    private static let loadingState = LoadingState()
    
    static func load() async -> (Bool, String) {
        guard await loadingState.begin() else {
            return (false, "Articles already loading")
        }
        defer { Task { await loadingState.end() } }
        
        LogEvent.print(module: "Articles.load()", message: "▶️ starting...")
        
        let articlesLocation = UserSettings().articlesLocation
        
        do {
            switch articlesLocation.description {
            case "remote":
                let result = try await handleRemoteLoading()
                return result
            case "local", "error":
                let result = try await handleLocalLoading()
                return result
            default:
                return (false, "Invalid articles location")
            }
        } catch {
            return (false, "Failed to load articles: \(error.localizedDescription)")
        }
    }
    
    private static func handleRemoteLoading() async throws -> (Bool, String) {
        LogEvent.print(module: "Articles.load()", message: "source (.remote)")
        
        guard NetworkManager.shared.isConnected else {
            return (false, "No internet connection. Connect to the internet and try again.")
        }
        
        guard let url = URL(string: AppSettings.articlesLocation.remote) else {
            return (false, "Invalid URL for articles file.")
        }
        
        guard try await isURLReachable(url: url) else {
            return (false, "URL is not reachable.")
        }
        
        if try await isUpdateRequired() {
            let fetched = try fetchArticles(from: .remote)
            if fetched {
                printSectionsAndArticles()
                return (true, "Sections and articles loaded")
            } else {
                return (false, "Sections and articles failed to load")
            }
        } else {
            return (true, "Remote articles update is not required")
        }
    }
    
    private static func handleLocalLoading() async throws -> (Bool, String) {
        LogEvent.print(module: "Articles.handleLocalLoading()", message: "source (.local)")
        
        if try await isUpdateRequired() {
            let fetched = try fetchArticles(from: .local)
            if fetched {
                UserSettings().articlesDate = try articlesDate()
                printSectionsAndArticles()
                return (true, "Local sections and articles loaded")
            } else {
                return (false, "Sections and articles failed to load")
            }
        } else {
            return (true, "A local articles update was not required")
        }
    }
    
    private static func fetchArticles(from location: ArticleLocations) throws -> Bool {
        let data = try loadData(from: location)
        let sectionsCount = try decodeSections(from: data)
        let articlesCount = try decodeArticles(from: data)
        return sectionsCount > 0 && articlesCount > 0
    }
    
    private static func loadData(from location: ArticleLocations) throws -> Data {
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
    
    private static func decodeSections(from data: Data) throws -> Int {
        let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: data)
        let context = ModelContainerProvider.sharedContext
        
        for section in decoded.sections {
            let sectionEntity = HelpSection(id: section.section_name, section: section.section_desc, rank: section.section_rank)
            context.insert(sectionEntity)
        }
        
        try context.save()
        return decoded.sections.count
    }
    
    private static func decodeArticles(from data: Data) throws -> Int {
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
    }
    
    private static func isUpdateRequired() async throws -> Bool {
        let data = try loadData(from: UserSettings().articlesLocation)
        let articlesDate = try decodeArticlesDate(from: data)
        let currentArticlesDate = UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
        return currentArticlesDate < articlesDate
    }
    
    private static func decodeArticlesDate(from data: Data) throws -> Date {
        let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: data)
        return DateInfo.convertToDate(date: decoded.updated_at)
    }
    
    private static func isURLReachable(url: URL) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        return httpResponse.statusCode == 200
    }
    
    static func deleteArticles() {
        LogEvent.print(module: "Articles.deleteArticles()", message: "▶️ starting...")
        deleteEntity(named: "HelpArticle")
        deleteEntity(named: "HelpSection")
        LogEvent.print(module: "Articles.deleteArticles()", message: "⏹️ ...finished")
    }
    
    private static func deleteEntity(named entityName: String) {
        let context = ModelContainerProvider.sharedContext
        
        do {
            if entityName == "HelpArticle" {
                let articles = try context.fetch(FetchDescriptor<HelpArticle>())
                guard !articles.isEmpty else {
                    LogEvent.print(module: "Articles.deleteEntity()", message: "No articles data to delete")
                    return
                }
                try context.delete(model: HelpArticle.self)
            } else if entityName == "HelpSection" {
                let sections = try context.fetch(FetchDescriptor<HelpSection>())
                guard !sections.isEmpty else {
                    LogEvent.print(module: "Articles.deleteEntity()", message: "No sections data to delete")
                    return
                }
                try context.delete(model: HelpSection.self)
            }
            
            LogEvent.print(module: "Articles.deleteEntity()", message: "\(entityName) entity deleted")
        } catch {
            LogEvent.print(module: "Articles.deleteEntity()", message: "Failed to delete \(entityName) data: \(error)")
        }
    }
    
    static func articlesDate() throws -> Date {
        let data = try loadData(from: UserSettings().articlesLocation)
        return try decodeArticlesDate(from: data)
    }
    
    static func printSectionsAndArticles() {
        do {
            let context = ModelContainerProvider.sharedContext
            let sections = try context.fetch(FetchDescriptor<HelpSection>())
            let sortedSections = sections.sorted {
                $0.rank.localizedStandardCompare($1.rank) == .orderedAscending
            }
            for section in sortedSections {
                print("Sorted Section: \(section.section) (\(section.toArticles?.count ?? 0))")
                
                var index = 0
                while index < section.toArticles?.count ?? 0 {
                    print("- \(section.toArticles?[index].title ?? "")")
                    index += 1
                }
            }
        } catch {
            LogEvent.print(module: "Articles.printSectionsAndArticles", message: "Error: \(error)")
        }
    }
}

// Actor to manage loading state
actor LoadingState {
    private var isLoading = false
    
    func begin() -> Bool {
        guard !isLoading else { return false }
        isLoading = true
        return true
    }
    
    func end() {
        isLoading = false
    }
}
