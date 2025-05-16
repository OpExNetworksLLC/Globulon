//
//  LogManager.swift
//  Globulon
//
//  Created by David Holeman on 5/16/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import UIKit

class LogManager {
    
    enum LogTypeEnum {
        case all
        case debugOnly
        case printOnly
        case writeOnly
    }
    
    class func event(output: LogTypeEnum = .all, indent: Int = 0, module: String, message: Any) {
        
        switch output {
        case .all:
            printOnly(module: module, message: message, indent: indent)
            writeOnly(module: module, message: message, indent: indent)
        case .debugOnly:
            debugOnly(module: module, message: message, indent: indent)
        case .printOnly:
            printOnly(module: module, message: message, indent: indent)
        case .writeOnly:
            writeOnly(module: module, message: message, indent: indent)
        }
    }
    
    //MARK: - Output
    
    class func debugOnly(module: String, message: Any, indent: Int = 0) {
        let indentation = String(repeating: " ", count: indent)
        Swift.print("[\(AppSettings.appName)] 🔎 \(module): \(indentation)\(message)")
    }
    
    class func printOnly(module: String, message: Any, indent: Int = 0) {
        let indentation = String(repeating: " ", count: indent)
        Swift.print("[\(AppSettings.appName)] 🖨️ \(module): \(indentation)\(message)")
    }
    
    class func writeOnly(module: String, message: Any, indent: Int = 0) {
        
        let indentation = String(repeating: " ", count: indent)
        let logMessage = "[\(AppSettings.appName)] \(formatDateStamp(Date())), \(module): \(indentation)\(message)\n"
        
        let fileManager = FileManager.default
        let logsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFileURL = logsDirectory.appendingPathComponent(AppSettings.log.filename)
        
        if !fileManager.fileExists(atPath: logFileURL.path) {
            fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            if let data = logMessage.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            Swift.print("Failed to write to log file.")
        }
    }
    
    
    //MARK: - Manage log file(s)
    
    /// Copies the log file to a user-selected directory using the Files app
    ///
    @MainActor
    class func copyTo(from viewController: UIViewController) {
        let logFileURL = getLogFileURL()
        
        // Ensure the file exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: logFileURL.path) else {
            LogManager.event(module: "LogEvent.copyTo", message: "Log file does not exist at: \(logFileURL.path)")
            return
        }
        
        // Present a document picker to allow the user to save the file
        let documentPicker = UIDocumentPickerViewController(forExporting: [logFileURL])
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        viewController.present(documentPicker, animated: true, completion: nil)
    }
    
    /// Copies direclty to the users on device document directory
    class func copyToDeviceDirectory() {
        let fileManager = FileManager.default
        let sourceURL = getLogFileURL()
        
        // Ensure the file exists at the source location
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            LogManager.event(module: "LogEvent.copytoDeviceDirectory", message: "Log file does not exist at: \(sourceURL.path)")
            return
        }
        
        // Get the directory accessible via the Files app ("On My iPhone")
        guard let sharedDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            LogManager.event(module: "LogEvent.copytoDeviceDirectory", message: "Failed to locate the document directory.")
            return
        }
        
        let destinationURL = sharedDirectory.appendingPathComponent(AppSettings.log.filename)
        
        do {
            // Remove the existing file if it exists at the destination
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy the file to the visible directory
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            LogManager.event(module: "LogEvent.copytoDeviceDirectory", message: "Log file successfully copied to: \(destinationURL.path)")
        } catch {
            LogManager.event(module: "copyToDeviceDirectory", message: "Failed to copy log file: \(error.localizedDescription)")
        }
    }
    
    class func deleteLogFile() {
        let fileManager = FileManager.default
        let logFileURL = getLogFileURL()
        
        if fileManager.fileExists(atPath: logFileURL.path) {
            do {
                try fileManager.removeItem(at: logFileURL)
                LogManager.event(module: "LogEvent()", message: "Log file deleted successfully: \(logFileURL.path)")
            } catch {
                LogManager.event(module: "LogEvent()", message: "Failed to delete log file: \(error.localizedDescription)")
            }
        } else {
            LogManager.event(module: "LogEvent()", message: "Log file does not exist at path: \(logFileURL.path)")
        }
    }
    
    class func getLogFileURL() -> URL {
        let logsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFileURL = logsDirectory.appendingPathComponent(AppSettings.log.filename)
        
        // Print the directory path for debugging
        Swift.print("Log file is located at: \(logFileURL.path)")
        
        return logFileURL
    }
    
    @MainActor
    class func ArchiveLogFile() {
        let fileManager = FileManager.default
        let logsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let originalFileURL = logsDirectory.appendingPathComponent(AppSettings.log.filename)
        let newFileName = "prior" + AppSettings.log.filename
        let newFileURL = logsDirectory.appendingPathComponent(newFileName)
        
        // Check if the original file exists
        guard fileManager.fileExists(atPath: originalFileURL.path) else {
            LogManager.event(module: "LogEvent.ArchiveLogFile", message: "Original log file does not exist at: \(originalFileURL.path)")
            return
        }
        
        do {
            // Remove the destination file if it exists
            if fileManager.fileExists(atPath: newFileURL.path) {
                try fileManager.removeItem(at: newFileURL)
            }
            
            // Copy the original file to the new file
            try fileManager.copyItem(at: originalFileURL, to: newFileURL)
            
            // Delete the original file after copying
            try fileManager.removeItem(at: originalFileURL)
            LogManager.event(module: "LogEvent.ArchiveLogFile", message: "Log file copied to \"\\Documents\" and original file deleted.")
            LogManager.event(output: .debugOnly, module: "LogEvent.ArchiveLogFile", message: "Log file copied to \(newFileURL.path) and original file deleted.")
            
            
            
            // Rename the original file to the new name (overwrite if needed)
            //try fileManager.moveItem(at: newFileURL, to: originalFileURL)
            //LogManager.event(module: "LogEvent.ArchiveLogFile", message: "Log file successfully renamed and copied to: \(newFileURL.path)")
        } catch {
            LogManager.event(module: "LogEvent.ArchiveLogFile", message: "Failed to rename and copy log file: \(error.localizedDescription)")
        }
    }
    
    
    //MARK: - Formatting
    
    private class func formatDateStamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
