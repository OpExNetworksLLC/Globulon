import Foundation
import CoreLocation
import SwiftData
import MapKit

@MainActor
final class ArticlesV2 {
    
    private static let loadingState = LoadingState()

    static func load() async -> (Bool, String) {
        guard await loadingState.begin() else {
            return (false, "🔁 Articles already loading")
        }
        defer { Task { await loadingState.end() } }

        LogEvent.print(module: "Articles.load()", message: "▶️ starting...")

        let location = UserSettings().articlesLocation
        let result: (Bool, String)

        do {
            switch location.description {
            case "remote":
                result = try await handleLoading(from: .remote)
            case "local", "error":
                result = try await handleLoading(from: location)
            default:
                result = (false, "❌ Invalid articles location")
            }
        } catch {
            result = (false, "❌ Failed to load articles: \(error.localizedDescription)")
        }
        return result
    }

    private static func handleLoading(from location: ArticleLocations) async throws -> (Bool, String) {

        let emoji: String
        switch location {
        case .remote:
            emoji = "🌍"
        case .local:
            emoji = "📂"
        case .error:
            emoji = "❗"
        }

        LogEvent.print(module: "Articles.handleLoading()", message: "\(emoji) Source: \(location.description)")

        if location == .remote {
            guard NetworkManager.shared.isConnected else {
                return (false, "📡 No internet connection. Connect to the internet and try again.")
            }

            guard let url = URL(string: AppSettings.articlesLocation.remote), try await isURLReachable(url: url) else {
                return (false, "📡 Remote URL is invalid or unreachable.")
            }
        }

        if try await isUpdateRequired(for: location) {
            LogEvent.print(module: "Articles.handleLoading()", message: "🔁 Update is required for \(location.description)")
            
            deleteArticles()
            LogEvent.print(module: "Articles.handleLoading()", message: "🗑️ Old data deleted")

            let fetched = try fetchAndStoreArticles(from: location)
            if fetched {
                let newDate = try articlesDate(for: location)
                UserSettings().articlesDate = newDate
                LogEvent.print(module: "Articles.handleLoading()", message: "✅ Articles date updated: \(newDate)")

                printSectionsAndArticles()
                return (true, "⬆️ \(location.description.capitalized) sections and articles loaded")
            } else {
                return (false, "❌ Failed to load sections and articles from \(location.description)")
            }
        } else {
            LogEvent.print(module: "Articles.handleLoading()", message: "🔄 Update not required for \(location.description)")
            return (true, "⚪ \(location.description.capitalized) articles update not required")
        }
    }

    private static func fetchAndStoreArticles(from location: ArticleLocations) throws -> Bool {
        let data = try loadData(from: location)
        
        // Validate data before deletion
        _ = try decodeArticlesDate(from: data)
        LogEvent.print(module: "Articles.fetchAndStoreArticles", message: "✅ Validated articles JSON format")

        deleteArticles()
        LogEvent.print(module: "Articles.fetchAndStoreArticles", message: "🧼 Old data deleted after validation")

        let sectionsCount = try decodeSections(from: data)
        let articlesCount = try decodeArticles(from: data)
        return sectionsCount > 0 && articlesCount > 0
    }

    private static func loadData(from location: ArticleLocations) throws -> Data {
        switch location {
        case .local, .error:
            let fileName = location == .local ? AppSettings.articlesLocation.local : AppSettings.articlesLocation.error
            guard let path = Bundle.main.path(forResource: fileName, ofType: "json") else {
                throw NSError(domain: "Invalid path", code: 0, userInfo: nil)
            }
            return try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
        case .remote:
            guard let url = URL(string: AppSettings.articlesLocation.remote) else {
                throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
            }
            let data = try Data(contentsOf: url, options: .alwaysMapped)
            LogEvent.print(module: "Articles.loadData()", message: "📡 Fetched data from remote")
            return data
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

    private static func isUpdateRequired(for location: ArticleLocations) async throws -> Bool {
        let data = try loadData(from: location)
        let fileDate = try decodeArticlesDate(from: data)
        let currentDate = UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
        LogEvent.print(module: "Articles.isUpdateRequired()", message: "🧪 \(currentDate) < \(fileDate)")
        return currentDate < fileDate
    }

    private static func decodeArticlesDate(from data: Data) throws -> Date {
        let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: data)
        return DateInfo.convertToDate(date: decoded.updated_at)
    }

    static func articlesDate(for location: ArticleLocations) throws -> Date {
        let data = try loadData(from: location)
        return try decodeArticlesDate(from: data)
    }

    private static func isURLReachable(url: URL) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
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
            switch entityName {
            case "HelpArticle":
                let articles = try context.fetch(FetchDescriptor<HelpArticle>())
                guard !articles.isEmpty else {
                    LogEvent.print(module: "Articles.deleteEntity()", message: "No articles to delete")
                    return
                }
                try context.delete(model: HelpArticle.self)
            case "HelpSection":
                let sections = try context.fetch(FetchDescriptor<HelpSection>())
                guard !sections.isEmpty else {
                    LogEvent.print(module: "Articles.deleteEntity()", message: "No sections to delete")
                    return
                }
                try context.delete(model: HelpSection.self)
            default:
                return
            }

            try context.save()
            LogEvent.print(module: "Articles.deleteEntity()", message: "\(entityName) entity deleted")
        } catch {
            LogEvent.print(module: "Articles.deleteEntity()", message: "Failed to delete \(entityName): \(error)")
        }
    }

    static func printSectionsAndArticles() {
        do {
            let context = ModelContainerProvider.sharedContext
            let sections = try context.fetch(FetchDescriptor<HelpSection>())
            let sortedSections = sections.sorted {
                $0.rank.localizedStandardCompare($1.rank) == .orderedAscending
            }

            LogEvent.print(module: "Articles.printSectionsAndArticles()", message: "🧾 Sections fetched: \(sortedSections.count)")

            for section in sortedSections {
                LogEvent.print(module: "Articles.printSectionsAndArticles()", message: "Section: [\(section.rank)] \(section.section) (\(section.toArticles?.count ?? 0))")
                for article in section.toArticles ?? [] {
                    LogEvent.print(module: "Articles.printSectionsAndArticles()", message: "- \(article.title)")
                }
            }

            LogEvent.print(module: "Articles.printSectionsAndArticles()", message: "✅ Finished printing all sections and articles.")
        } catch {
            LogEvent.print(module: "Articles.printSectionsAndArticles()", message: "❌ Error: \(error)")
        }
    }
}

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
