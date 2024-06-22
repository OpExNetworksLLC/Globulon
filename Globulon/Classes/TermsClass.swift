//
//  TermsClass.swift
//  ViDrive
//
//  Created by David Holeman on 2/19/24.
//  Copyright © 2023 OpEx Networks, LLC. All rights reserved.
//

import Foundation

struct TermsJSON : Codable {
    var date: Date?
    var title: String?
    var content: String?
}
var termsJSON = TermsJSON()
let termsData = TermsData()

class TermsData
{
    
    // properties
    var date: (Date) {
        get { return getTermsDate(key: "date") }
    }
    
    var title: (String) {
        get { return getTermsString(key: "title") }
    }
    
    var content: (String) {
        get { return getTermsString(key: "content") }
    }
    
    var json: (String) {
        get {
            loadStruc(structure: &termsJSON)
            return encodeJSON(structure: termsJSON, formatted: true)
        }
    }
    
    // public class functions
    func loadStruc(structure: inout TermsJSON) {
        structure.date = date
        structure.title = title
        structure.content = content
    }
    
    // private class functions
    private func getTermsString(key: String) -> String {
        
        let myPath = Bundle.main.path(forResource: "Terms", ofType: "json")
        
        let decoder = JSONDecoder()
        
        // date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            
            let myData = try Data(contentsOf: URL(fileURLWithPath: myPath!), options: .alwaysMapped)
            let decoded = try! decoder.decode(TermsJSON.self, from: myData)
            
            switch key {
            case "title":
                return decoded.title ?? ""
            case "content":
                return decoded.content ?? ""
            default:
                return ""
            }
            
        } catch let error as NSError {
            LogEvent.print(module: "TermsData.getTermsString", message: "Failed to fetch.  Error:\(error)")
            return "fail-" + key
        }
    }
    
    private func getTermsDate(key: String) -> Date {
        let myPath = Bundle.main.path(forResource: "Terms", ofType: "json")
        
        let decoder = JSONDecoder()
        
        // date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            
            let myData = try Data(contentsOf: URL(fileURLWithPath: myPath!), options: .alwaysMapped)
            let decoded = try! decoder.decode(TermsJSON.self, from: myData)
            
            switch key {
            case "date":
                return decoded.date!
            default:
                return decoded.date!
            }
            
        } catch let error as NSError {
            LogEvent.print(module: "TermsData.getTermsDate", message: "Failed to fetch.  Error:\(error)")

            
            // TODO:  Better job needed of what to return here if date error
            let date = Date()
            return date
        }
    }
}

