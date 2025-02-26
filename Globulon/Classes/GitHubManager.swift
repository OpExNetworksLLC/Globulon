//
//  GitHubManager.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation

class GitHubManager {
    /// Downloads all files from a GitHub repository directory and saves them to the app's Documents Directory.
    static func download(directory: String) async {
        LogEvent.print(module: "GitHubManager.download", message: "▶️ starting...")
        
        
        //        // Parse the URL dynamically based on the repo name
        //        guard let parsed = parsePageURL(urlString, repo: AppSettings.GitHub.repo, appName: AppSettings.GitHub.appName) else {
        //            print("❌ Unable to parse GitHub Page URL")
        //            return
        //        }
        //
        //        print("🌍 Host: \(parsed.host)")
        //        print("📂 Path Components: \(parsed.pathComponents)")
        //        print("📌 Last Component: \(parsed.lastComponent ?? "N/A")")
        //        print("🛤️ Relative Path: \(parsed.relativePath ?? "N/A")")
        //        print("📁 App Relative Path (after appName): \(parsed.appRelativePath ?? "N/A")")
        //
        //        // Construct the GitHub API URL dynamically
        //        guard let relativePath = parsed.relativePath else {
        //            print("❌ Could not extract relative path for API call")
        //            return
        //        }
        
        let githubAPI = "https://api.github.com/repos/\(AppSettings.GitHub.owner)/\(AppSettings.GitHub.repo)/contents/\(AppSettings.GitHub.appName)/\(directory)"
        
        guard let apiURL = URL(string: githubAPI) else {
            LogEvent.print(module: "GitHubManager", message: "❌ Invalid GitHub API URL")
            LogEvent.print(module: "GitHubManager.download", message: "⏹️ ...finished")
            return
        }
        
        do {
            // Fetch file metadata from GitHub API
            let files = try await fetchFilesList(from: apiURL)
            
            // Get the app's Documents Directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // Download files concurrently with structured error handling
            try await withThrowingTaskGroup(of: Void.self) { group in
                for file in files {
                    group.addTask {
                        let fileURL = URL(string: file.downloadURL)!
                        let destinationURL = documentsDirectory.appendingPathComponent(file.name)
                        
                        do {
                            try await downloadFiles(from: fileURL, to: destinationURL, appRelativePath: directory)
                            //print("✅ Downloaded: \(file.name) → \(destinationURL.path)")
                            LogEvent.print(module: "GitHubManager.download", message: "✅ Downloaded: \(file.name)")
                        } catch {
                            LogEvent.print(module: "GitHubManager.download", message: "❌ Failed to download \(file.name): \(error.localizedDescription)")
                        }
                    }
                }
                
                try await group.waitForAll() // Ensure all tasks complete
                LogEvent.print(module: "GitHubManager.download", message: "⏹️ ...finished")
                
            }
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    
    //    /// Downloads all files from a GitHub repository directory and saves them to the app's Documents Directory.
    //    static func downloadGitHubFiles(owner: String, repo: String, appName: String, urlString: String) async {
    //
    //        // Parse the URL dynamically based on the repo name
    //        guard let parsed = parseGitHubPageURL(urlString, repo: repo, appName: appName) else {
    //            print("❌ Unable to parse GitHub Page URL")
    //            return
    //        }
    //
    //        print("🌍 Host: \(parsed.host)")
    //        print("📂 Path Components: \(parsed.pathComponents)")
    //        print("📌 Last Component: \(parsed.lastComponent ?? "N/A")")
    //        print("🛤️ Relative Path: \(parsed.relativePath ?? "N/A")")
    //        print("📁 App Relative Path (after appName): \(parsed.appRelativePath ?? "N/A")")
    //
    //        // Construct the GitHub API URL dynamically
    //        guard let relativePath = parsed.relativePath else {
    //            print("❌ Could not extract relative path for API call")
    //            return
    //        }
    //
    //        let githubAPI = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(relativePath)"
    //
    //        guard let apiURL = URL(string: githubAPI) else {
    //            print("❌ Invalid GitHub API URL")
    //            return
    //        }
    //
    //        do {
    //            // Fetch file metadata from GitHub API
    //            let files = try await fetchGitHubFileList(from: apiURL)
    //
    //            // Get the app's Documents Directory
    //            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    //
    //            // Download files concurrently with structured error handling
    //            try await withThrowingTaskGroup(of: Void.self) { group in
    //                for file in files {
    //                    group.addTask {
    //                        let fileURL = URL(string: file.downloadURL)!
    //                        let destinationURL = documentsDirectory.appendingPathComponent(file.name)
    //
    //                        do {
    //                            try await downloadFile(from: fileURL, to: destinationURL, appRelativePath: parsed.appRelativePath)
    //                            print("✅ Downloaded: \(file.name) → \(destinationURL.path)")
    //                        } catch {
    //                            print("❌ Failed to download \(file.name): \(error.localizedDescription)")
    //                        }
    //                    }
    //                }
    //
    //                try await group.waitForAll() // Ensure all tasks complete
    //            }
    //
    //        } catch {
    //            print("❌ Error: \(error.localizedDescription)")
    //        }
    //    }
    
    /// Fetches the list of files from a GitHub repository directory using the API.
    private static func fetchFilesList(from url: URL) async throws -> [GitHubFile] {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let fileList = try decoder.decode([GitHubFile].self, from: data)
        
        return fileList.filter { $0.type == "file" } // Return only actual files
    }
    
    /// Downloads a file from the given URL and saves it to the destination subdirectory.
    private static func downloadFiles(from url: URL, to destination: URL, appRelativePath: String?) async throws {
        let fileManager = FileManager.default
        
        // Ensure the subdirectory exists
        if let subdirectory = appRelativePath {
            let subdirectoryURL = destination.deletingLastPathComponent().appendingPathComponent(subdirectory, isDirectory: true)
            
            if !fileManager.fileExists(atPath: subdirectoryURL.path) {
                try fileManager.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true)
            }
            
            // Adjust destination to include subdirectory
            let finalDestination = subdirectoryURL.appendingPathComponent(destination.lastPathComponent)
            
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            // Remove existing file if it exists
            if fileManager.fileExists(atPath: finalDestination.path) {
                try fileManager.removeItem(at: finalDestination)
            }
            
            try fileManager.moveItem(at: tempURL, to: finalDestination)
        } else {
            // Default behavior without subdirectory
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            
            try fileManager.moveItem(at: tempURL, to: destination)
        }
    }
    
    //    private static func parsePageURL(_ urlString: String, repo: String, appName: String) -> (host: String, pathComponents: [String], lastComponent: String?, relativePath: String?, appRelativePath: String?)? {
    //        guard let url = URL(string: urlString), let host = url.host else {
    //            print("❌ Invalid URL")
    //            return nil
    //        }
    //
    //        // Extract path components and remove unnecessary "/"
    //        let pathComponents = url.pathComponents.filter { $0 != "/" }
    //
    //        // Find index of the specified repo and build relative path after it
    //        let relativePath = pathComponents.firstIndex(of: repo).map { index in
    //            pathComponents[(index + 1)...].joined(separator: "/")
    //        }
    //
    //        // Find index of the appName and build a relative path after it
    //        let appRelativePath = pathComponents.firstIndex(of: appName).map { index in
    //            pathComponents[(index + 1)...].joined(separator: "/")
    //        }
    //
    //        return (host, pathComponents, pathComponents.last, relativePath, appRelativePath)
    //    }
}

/// Model for GitHub API file response.
struct GitHubFile: Codable {
    let name: String
    let type: String
    let downloadURL: String

    enum CodingKeys: String, CodingKey {
        case name, type
        case downloadURL = "download_url"
    }
}


