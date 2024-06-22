//
//  ArticlesClass.swift
//  ViDrive
//
//  Created by David Holeman on 3/9/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftData
import MapKit

/// Structures for the JSON file that contains the FAQ content
///
struct ArticlesJSON : Decodable {
    let updated_at: String
    let sections: [SectionsJSON]
    let articles: [ArticleJSON]
}
struct ResponseData: Decodable {
    var articlesJSON: [ArticlesJSON]
}

struct SectionsJSON: Decodable {
    let section_name: String
    let section_desc: String
    let section_rank: String
}
struct ArticleJSON : Decodable {
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
class Articles {
    
    class func load(completion: @escaping (Bool, String) -> Void) {
        let articlesLocation = UserSettings.init().articlesLocation
        
        if articlesLocation.description == "remote" {
            
            LogEvent.print(module: "Articles.load()", message: "Loading remote articles")
            print("** internet reachable: \(InternetReachability.shared.isInternetReachable())")
            
            if InternetReachability.shared.isInternetReachable() {
                print("* internet is reachable")
                // Check to see if the URL is accessible
                if let url = URL(string: AppValues.articlesLocation.remote) {
                    isURLReachable(url: url) { (isReachable) in
                        if isReachable {
                            print("** URL is reachable.")
                            // Check to see if an update is required
                            isUpdateRequired(articlesLocation: UserSettings.init().articlesLocation) { result in
                                var fetched = false
                                if result == true {
                                    print("** Remote update is required")
                                    fetched = fetchArticles(articlesLocation: UserSettings.init().articlesLocation)
                                    if fetched {
                                        let message = "Sections and articles loaded"
                                        LogEvent.print(module: "Articles.load", message: message)
                                        completion(true, message)
                                    } else {
                                        fetched = fetchArticles(articlesLocation: .error)
                                        if result {
                                            let message = "Error accessing articles.  Loaded problem article."
                                            LogEvent.print(module: "Articles.load", message: message)
                                            completion(false, message)
                                        } else {
                                            let message = "Sections and articles failed to load"
                                            LogEvent.print(module: "Articles.load", message: message)
                                            completion(false, message)
                                        }
                                    }
                                } else {
                                    let message = "Remote update is not required"
                                    completion(true, message)
                                }
                            }
                        } else {
                            let message = "URL is not reachable."
                            completion(false, message)
                            // Skip trying to load since the URL is not reachable.  If the articles are empty load error article and set location to error.
                        }
                    }
                } else {
                    let message = "Invalid URL for articles file."
                    completion(false, message)
                    // Skip trying to load since the url is invalid.  If the articles are empty load error article and set location to error.
                }
            } else {
                //TODO: Check to see if not articles are loaded and if not then we need load error article and set location to error.
                let message = "No internet connection.  Connect to the internet and try again."
                completion(false, message)
            }
            
        }
        
        if articlesLocation.description == "local" || articlesLocation.description == "error" {
            LogEvent.print(module: "Articles.load()", message: "Loading local articles")
            isUpdateRequired(articlesLocation: UserSettings.init().articlesLocation) { result in
                var fetched = false
                if result == true {
                    fetched = fetchArticles(articlesLocation: UserSettings.init().articlesLocation)
                    if fetched {
                        let message = "local Sections and articles loaded"
                        LogEvent.print(module: "Articles.load", message: message)
                        completion(true, message)
                    } else {
                        fetched = fetchArticles(articlesLocation: .error)
                        if result {
                            let message = "Error accessing articles.  Loaded problem article."
                            LogEvent.print(module: "Articles.load", message: message)
                            completion(false, message)
                        } else {
                            let message = "Sections and articles failed to load"
                            LogEvent.print(module: "Articles.load", message: message)
                            completion(false, message)
                        }
                    }
                } else {
                    let message = "A local update was not requried"
                    completion(false, message)
                }
            }
        }

    }
    
    // MARK:  Retrieve the articles
    //
    class func fetchArticles(articlesLocation: ArticleLocations) -> Bool {
        var articleCount = 0
        var articleIndex = 0
        var sectionsCount = 0
        var sectionIndex = 0
        
        /// Delete the articles then the sections.
        /// deleteEntityByName(entity: "ArticlesSD")
        /// deleteEntityByName(entity: "SectionsSD")
        deleteArticles()
        
        do {
            LogEvent.print(module: "Articles.loadArticles", message: "Loading \(articlesLocation) sections and articles...")
            
            var myPath = ""
            var myData = Data()
            switch ArticleLocations(rawValue: articlesLocation.rawValue) {
            case .local:
                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.local, ofType: "json")!
                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
                sectionsCount = decodeSections(myData, &sectionsCount)
                articleCount = decodeArticles(myData, &sectionIndex, &articleIndex, &articleCount)
                _ = Articles.updateArticlesDate(date: Articles.articlesDate())
            case .remote:
                let urlString = AppValues.articlesLocation.remote
                let url = URL(string: urlString)!
                
                let session = URLSession.shared
                let task = session.dataTask(with: url) { (data, response, error) in
                    if let error = error {
                        LogEvent.print(module: "Articles.fetchArticles", message: "Error saving articles.json: \(error)")
                        return
                    }
                    guard let myData = data else {
                        LogEvent.print(module: "Articles.fetchArticles", message: "no JSON data received")
                        return
                    }
                    sectionsCount = decodeSections(myData, &sectionsCount)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        articleCount = decodeArticles(myData, &sectionIndex, &articleIndex, &articleCount)
                    }
                }
                task.resume()
                _ = Articles.updateArticlesDate(date: Articles.articlesDate())
            case .error:
                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.error, ofType: "json")!
                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
                sectionsCount = decodeSections(myData, &sectionsCount)
                articleCount = decodeArticles(myData, &sectionIndex, &articleIndex, &articleCount)
                // set to zero date so during next load it will an update is required based on the date check and try again.
                _ = Articles.updateArticlesDate(date: Articles.articlesDate())
            default:
                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.local, ofType: "json")!
                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
                sectionsCount = decodeSections(myData, &sectionsCount)
                articleCount = decodeArticles(myData, &sectionIndex, &articleIndex, &articleCount)
                _ = Articles.updateArticlesDate(date: Articles.articlesDate())
            }
        } catch {
            LogEvent.print(module: "Articles.fetchArticles", message: "Error: \(error)")
        }
        
        if articleCount >= 0 && sectionsCount >= 0 {
        //if articleCount > 0 && sectionsCount > 0 {
            LogEvent.print(module: "Articles.fetchArticles", message: "Sections and articles loaded successfully")
            return true
        } else {
            LogEvent.print(module: "Articles.fetchArticles", message: "Sections and articles failed to load successfully")
            return false
        }
        
    }
    
    // MARK:  Decode the articles in the json file
    //
    fileprivate static func decodeArticles(_ myData: Data, _ sectionIndex: inout Int, _ articleIndex: inout Int, _ articleCount: inout Int)  -> Int {
        // Decode the json
        do {
            LogEvent.print(module: "Articles.decodeArticles", message: "Decoding ArticlesSD")
            let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: myData)
            
            guard let container = AppEnvironment.sharedModelContainer else {
                LogEvent.print(module: "Articles.decodeArticles()", message: ".sharedModelContainer has not been initialized")
                return 0
            }
            
           // let container = try ModelContainer(for: SectionsSD.self, ArticlesSD.self)
            
            let context = ModelContext(container)
            
            let sectionsSD = try context.fetch(FetchDescriptor<SectionsSD>())
            
            /// While in the section loop through the articles that match that section and load them into the ArticlesEntity.
            ///
            while sectionIndex < sectionsSD.count {
                
                articleIndex = 0
                while articleIndex < decoded.articles.count {
                    
                    /// Loop throught he section names and tie article back to the appropriate section
                    var myIndex = 0
                    while myIndex < decoded.articles[articleIndex].section_names.count {
                        
                        if decoded.articles[articleIndex].section_names[myIndex] == sectionsSD[sectionIndex].id {
                            
                            let myArticle = ArticlesSD(
                                id: decoded.articles[articleIndex].id,
                                title: decoded.articles[articleIndex].title,
                                summary: decoded.articles[articleIndex].summary,
                                search: decoded.articles[articleIndex].search.lowercased(),
                                section: decoded.articles[articleIndex].section_names[myIndex],
                                body: decoded.articles[articleIndex].body)
                            
                            //context.insert(object: myArticle)
                            context.insert(myArticle)
                            
                            /// Link the article to it's section
                            myArticle.toSection = sectionsSD[sectionIndex]
                            
                            do {
                                try context.save()
                                articleCount+=1
                                LogEvent.print(module: "Article.loadArticles", message: "Saved \(myArticle.id), \(myArticle.title) to Section -> \(myArticle.section)")
                            } catch let error as NSError {
                                LogEvent.print(module: "Articles.decodeArticles", message: "Error saving myArticle: \(error)")
                            }
                            //articleCount+=1
                        }
                        myIndex+=1
                    }
                    articleIndex+=1
                }
                sectionIndex+=1
            }
        } catch let error as NSError {
            LogEvent.print(module: "Articles.decodeSection", message: error)
        }
        LogEvent.print(module: "Articles.loadArticles", message: "Total articles loaded: \(articleCount)")
        return articleCount
    }
    
    // MARK:  Decode the sections in the json file
    //
    fileprivate static func decodeSections(_ myData: Data, _ sectionsCount: inout Int) -> Int {
        
        var sectionsCount = 0
        
        do {
            
            LogEvent.print(module: "Articles.decodeSections", message: "Decoding SectionsSD")
            let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: myData)

            guard let container = AppEnvironment.sharedModelContainer else {
                LogEvent.print(module: "Articles.decodeSections()", message: ".sharedModelContainer has not been initialized")
                return 0
            }
            
            //let container = try ModelContainer(for: SectionsSD.self, ArticlesSD.self)
            let context = ModelContext(container)
            
            while sectionsCount < decoded.sections.count {
                
                let mySection = SectionsSD(id: decoded.sections[sectionsCount].section_name, section: decoded.sections[sectionsCount].section_desc, rank: decoded.sections[sectionsCount].section_rank)
                
                context.insert(mySection)
                
                do {
                    try context.save()
                    LogEvent.print(module: "Article.loadSections", message: "saved SectionsSD: \(decoded.sections[sectionsCount].section_name), \(decoded.sections[sectionsCount].section_desc), \(decoded.sections[sectionsCount].section_rank)")
                    
                } catch let error as NSError {
                    LogEvent.print(module: "Articles.loadSection", message: "Error saving mySection: \(error)")
                }
                sectionsCount+=1
                
            }
            
        } catch let error as NSError {
            LogEvent.print(module: "Articles.loadSection", message: "Error accessing data source: \(error)")
        }
        LogEvent.print(module: "Articles.loadArticles", message: "Total sections loaded: \(sectionsCount)")
        return sectionsCount
    }
    
    // MARK: Return date of article
    class func articlesDate() -> Date {
        /// Get for whichever location is current in settings.
        LogEvent.print(module: "Articles.articlesDate", message: "Getting \(UserSettings.init().articlesLocation.description) date")

        var myPath = ""
        var myData = Data()
        do {
            switch ArticleLocations(rawValue: UserSettings.init().articlesLocation.rawValue) {
            case .local:
                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.local, ofType: "json")!
                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
                let date = decodeArticlesDateV2(myData)
                LogEvent.print(module: "Articles.articlesDate", message: "\(UserSettings.init().articlesLocation.description) date: \(date)")
                return date
            case .remote:
//                var fetchDate: Date?
//
//                fetchRemoteArticlesDate { date in
//                    fetchDate = date
//                    // finds the correct date
//                    print("* fetchDate1: \(String(describing: fetchDate))" )
//                }
//
//
//                // How can I receive the date from fetchRemoteArticlesData?
//                print("* fetchDate2: \(fetchDate ?? DateInfo.zeroDate)")
//                return fetchDate ?? DateInfo.zeroDate
                
                let urlString = AppValues.articlesLocation.remote
                let url = URL(string: urlString)!
                
                let session = URLSession.shared
                let task = session.dataTask(with: url) { (data, response, error) in
                    if let error = error {
                        LogEvent.print(module: "Articles.fetchArticles", message: "Error saving articles.json: \(error)")
                        return
                    }
                    guard let myData = data else {
                        LogEvent.print(module: "Articles.fetchArticles", message: "no JSON data received")
                        return
                    }
                    let fetchDate = decodeArticlesDateV2(myData)
                    LogEvent.print(module: "Articles.articlesDate", message: "\(UserSettings.init().articlesLocation.description) date: \(fetchDate)")
                    
                    // finds the correct date
                    print("**1 fetchDate: \(fetchDate)")

                }
                task.resume()
                
                myData = try Data(contentsOf: url, options: .alwaysMapped)
                let fetchDate = decodeArticlesDateV2(myData)
                LogEvent.print(module: "Articles.articlesDate", message: "\(UserSettings.init().articlesLocation.description) date: \(fetchDate)")
                
                print("**2 fetchDate: \(fetchDate)")
                return fetchDate
                
            case .error:
                //TODO: May just need to return zerodate
                
//                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.error, ofType: "json")!
//                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
//                let date = decodeArticlesDateV2(myData)
//                LogEvent.print(module: "Articles.articlesDate", message: "\(UserSettings.init().articlesLocation.description) date: \(date)")
//                return date
                return DateInfo.zeroDate
            default:
                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.local, ofType: "json")!
                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
                let date = decodeArticlesDateV2(myData)
                LogEvent.print(module: "Articles.articlesDate", message: "\(UserSettings.init().articlesLocation.description) date: \(date)")
                return date
            }
        } catch {
            LogEvent.print(module: "Articles.articlesDate", message: "Error: \(error)")
            return UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
        }
    }

    
    // MARK:  Delete all the article entities to delete the articles
    //
    class func deleteArticles() {
        
        LogEvent.print(module: "Articles.deleteArticles()", message: "Deleting articles...")

        /// Delete the articles then the sections.
        Articles.deleteEntityByName(entity: "ArticlesSD")
        Articles.deleteEntityByName(entity: "SectionsSD")
        
        ///  Reset the user setting to a zero data to indicated that the articles are not loaded.
        //UserSettings.init().articlesDate = DateInfo.zeroDate
        
    }
    
    // MARK:  Delete entity by name
    //
    class func deleteEntityByName(entity: String) {
        
        // Access the sharedModelContainer
        guard let container = AppEnvironment.sharedModelContainer else {
            LogEvent.print(module: "Articles.deleteEntityByName()", message: ".sharedModelContainer has not been initialized")
            return
        }
        let context = ModelContext(container)

//        do {
//            /// Fetch data
//            let articlesSD = try context.fetch(FetchDescriptor<ArticlesSD>())
//
//            /// Is there any data and if not return out
//            guard !articlesSD.isEmpty else {
//                LogEvent.print(module: "Articles.deleteEntityByName()", message: "No articles data to delete")
//                return
//            }
//        } catch {
//            LogEvent.print(module: "Articles.deleteEntityByName()", message: "Failed to delete articles data: \(error)")
//        }

        
        switch (entity) {
        case "ArticlesSD":
            do {
                /// Fetch data
                let articlesSD = try context.fetch(FetchDescriptor<ArticlesSD>())
                
                /// Is there any data and if not return out
                guard !articlesSD.isEmpty else {
                    LogEvent.print(module: "Articles.deleteEntityByName()", message: "No articles data to delete")
                    return
                }
            } catch {
                LogEvent.print(module: "Articles.deleteEntityByName()", message: "Failed to delete articles data: \(error)")
            }
            
            do {
                try context.delete(model: ArticlesSD.self)
                LogEvent.print(module: "Articles.deleteEntityByName()", message: "\(entity) entity deleted")
            } catch {
                LogEvent.print(module: "Articles.deleteEntityByName()", message: "\(entity) entity not deleted successfully")
            }
        case "SectionsSD":
            do {
                /// Fetch data
                let articlesSD = try context.fetch(FetchDescriptor<SectionsSD>())
                
                /// Is there any data and if not return out
                guard !articlesSD.isEmpty else {
                    LogEvent.print(module: "Articles.deleteEntityByName()", message: "No secctions data to delete")
                    return
                }
            } catch {
                LogEvent.print(module: "Articles.deleteEntityByName()", message: "Failed to delete sections data: \(error)")
            }
            
            do {
                try context.delete(model: SectionsSD.self)
                LogEvent.print(module: "Articles.deleteEntityByName()", message: "\(entity) entity deleted")
            } catch {
                LogEvent.print(module: "Articles.deleteEntityByName()", message: "\(entity) entity not deleted successfully")
            }
        default:
            do {
                try context.delete(model: ArticlesSD.self)
                LogEvent.print(module: "Articles.deleteEntityByName()", message: "\(entity) entity deleted")
            } catch {
                LogEvent.print(module: "Articles.deleteEntityByName()", message: "\(entity) entity not deleted successfully")
            }
        }
    }
    
    // MARK: Is an update required
    //
    class func isUpdateRequired(articlesLocation: ArticleLocations, completion: @escaping (Bool) -> Void) {

        do {
            switch ArticleLocations(rawValue: articlesLocation.rawValue) {
            case .local:
                let myPath = Bundle.main.path(forResource: AppValues.articlesLocation.local, ofType: "json")
                let myData = try Data(contentsOf: URL(fileURLWithPath: myPath!), options: .alwaysMapped)
                completion(decodeArticlesDate(myData))
            case .remote:
                print("* remote")
                let urlString = AppValues.articlesLocation.remote
                let url = URL(string: urlString)!
                
                let session = URLSession.shared
                let task = session.dataTask(with: url) { (data, response, error) in
                    if let error = error {
                        LogEvent.print(module: "Articles.isUpdateRequired", message: "Error: \(error)")
                        completion(false)
                        return
                    }
                    guard let myData = data else {
                        LogEvent.print(module: "Articles.isUpdateRequired", message: "no JSON data received")
                        completion(false)
                        return
                    }
                    let resultX = decodeArticlesDate(myData)
                    print("* resultX: \(resultX)")
                    completion(resultX)
                }
                task.resume()
                
            case .error:
                let myPath = Bundle.main.path(forResource: AppValues.articlesLocation.error, ofType: "json")
                let myData = try Data(contentsOf: URL(fileURLWithPath: myPath!), options: .alwaysMapped)
                completion(decodeArticlesDate(myData))
                
            default:
                let myPath = Bundle.main.path(forResource: AppValues.articlesLocation.error, ofType: "json")
                let myData = try Data(contentsOf: URL(fileURLWithPath: myPath!), options: .alwaysMapped)
                completion(decodeArticlesDate(myData))
            }
        } catch {
            LogEvent.print(module: "Articles.isUpdateRequired", message: "Error: \(error)")
            completion(false)
        }
    }
    
    fileprivate static func decodeArticlesDate(_ myData: Data) -> Bool {
        do {
            print("* decoding the articles date V2")
            
            // Decode the json
            let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: myData)
            
            let articlesDate = UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
            
            if articlesDate < DateInfo.convertToDate(date: decoded.updated_at)
            {
                LogEvent.print(module: "Articles.decodeArticlesDate", message: "Articles Status: \(decoded.updated_at) > \(articlesDate) An udpate is required")
                //UserDefaults.standard.set(DateInfo.convertToDate(date: decoded.updated_at), forKey: "articlesDate")
                return true
            } else {
                LogEvent.print(module: "Articles.decodeArticlesDate", message: "Articles Status: \(decoded.updated_at) <= \(articlesDate) An update is not required")
                return false
            }
        } catch {
            LogEvent.print(module: "Articles.decodeArticlesDate", message: "Unexpected error: \(error)")
            return false
        }
    }
    
    fileprivate static func decodeArticlesDateV2(_ myData: Data) -> Date {
        do {
            print("* decoding the articles date V2")
            
            // Decode the json
            let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: myData)
            
            let articlesDate = UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
            
            if articlesDate < DateInfo.convertToDate(date: decoded.updated_at)
            {
                LogEvent.print(module: "Articles.decodeArticlesDateV2", message: "Articles Status: \(decoded.updated_at) > \(articlesDate) Source has a more recent date")
                return DateInfo.convertToDate(date: decoded.updated_at)
            } else {
                LogEvent.print(module: "Articles.decodeArticlesDateV2", message: "Articles Status: \(decoded.updated_at) <= \(articlesDate) An update is not required")
                return DateInfo.convertToDate(date: decoded.updated_at)
            }
        } catch {
            LogEvent.print(module: "Articles.decodeArticlesDateV2", message: "Unexpected error: \(error)")
            return UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
        }

    }
    
    fileprivate static func updateArticlesDate(date: Date) -> Bool {
        ///
        LogEvent.print(module: "Articles.updateArticlesDate", message: "updating date for \(UserSettings.init().articlesLocation.description) articles")
        
        var myPath = ""
        var myData = Data()
        do {
            switch ArticleLocations(rawValue: UserSettings.init().articlesLocation.rawValue) {
            case .local:
                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.local, ofType: "json")!
                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
                return updateDecodeArticlesDate(myData)
            case .remote:
                let urlString = AppValues.articlesLocation.remote
                let url = URL(string: urlString)!
                myData = try Data(contentsOf: url, options: .alwaysMapped)
                return updateDecodeArticlesDate(myData)
            case .error:
                //TODO:  May need to just return zero date
                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.error, ofType: "json")!
                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
                return updateDecodeArticlesDate(myData)
            default:
                myPath = Bundle.main.path(forResource: AppValues.articlesLocation.local, ofType: "json")!
                myData = try Data(contentsOf: URL(fileURLWithPath: myPath), options: .alwaysMapped)
                return updateDecodeArticlesDate(myData)
            }
        } catch {
            LogEvent.print(module: "Articles.updateArticlesDate", message: "Error: \(error)")
            return false
        }
    }
    
    fileprivate static func updateDecodeArticlesDate(_ myData: Data) -> Bool {
        do {
            
            // Decode the json
            let decoded = try JSONDecoder().decode(ArticlesJSON.self, from: myData)
            
            let articlesDate = UserDefaults.standard.object(forKey: "articlesDate") as? Date ?? DateInfo.zeroDate
            
            if articlesDate < DateInfo.convertToDate(date: decoded.updated_at)
            {
                LogEvent.print(module: "Articles.updateArticlesDate", message: "Articles Status: \(articlesDate) -> \(decoded.updated_at) Date updated")
                UserDefaults.standard.set(DateInfo.convertToDate(date: decoded.updated_at), forKey: "articlesDate")
                return true
            } else {
                LogEvent.print(module: "Articles.updateArticlesDate", message: "Articles Status: \(decoded.updated_at) <= \(articlesDate) Date not updated")
                return false
            }
        } catch {
            LogEvent.print(module: "Articles.updateArticlesDate", message: "Unexpected error: \(error)")
            return false
        }
    }

}
