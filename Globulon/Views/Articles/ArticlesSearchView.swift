//
//  ArticlesSearchView.swift
//  Globulon
//
//  Created by David Holeman on 02/26/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftData
import SwiftUI

/// This is the Article Search View that presents the user input of a search string then it's passed to another view that presents the filtered list.
///
struct ArticlesSearchView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var searchInput: String = ""
    
    var body: some View {
        VStack {
            
            /// Search Bar
            ///
            HStack {
                SearchBar(searchInput: $searchInput)
            }
            .padding(.horizontal, 16)
            
            /// Filtered List
            ///
            FilteredList(searchString: searchInput, isExpanded: userSettings.isFaqExpanded)
                .scrollContentBackground(.hidden)
        }
        .navigationBarTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    userSettings.isFaqExpanded.toggle()
                }) {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
        }
    }
}

/// Custom Search Bar View
///
struct SearchBar: View {
    @Binding var searchInput: String
    @State private var isSearching = false
    
    var body: some View {
        ZStack {
            Color(.systemGray6).cornerRadius(5.0)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.gray))
                TextField("Search...", text: $searchInput)
                    .onChange(of: searchInput) {
                        isSearching = true
                        searchInput = searchInput.lowercased()
                    }
                    .accentColor(Color("colorBlackWhite"))
                    .foregroundColor(Color("colorBlackWhite"))
                if isSearching {
                    Button("Cancel") {
                        isSearching = false
                        searchInput = ""
                        hideKeyboard()
                    }
                    .accentColor(.blue)
                }
            }
            .padding(5)
            .background(Color("searchBarTextBackgroundColor").cornerRadius(5.0))
        }
        .frame(height: 56)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// Filtered List View
struct FilteredList: View {
    @EnvironmentObject var userSettings: UserSettings
    @Query private var helpSection: [HelpSection]
    
    let searchString: String
    let isExpanded: Bool
    
    var filteredSections: [HelpSection] {
        helpSection.filter { section in
            section.toArticles?.contains { $0.search.contains(searchString) } == true
        }
        //.sorted { $0.rank < $1.rank }
        .sorted { $0.rank.localizedStandardCompare($1.rank) == .orderedAscending }
    }
    
    var body: some View {
        List {
            ForEach(filteredSections) { section in
                Section(header: Text(section.section.replacingOccurrences(of: AppSettings.pinnedTag, with: AppSettings.pinnedUnicode))) {
                    if let articles = section.toArticles {
                        ForEach(articles.filter { $0.search.contains(searchString) }) { article in
                            NavigationLink(destination: ArticleView(title: article.title, summary: article.summary, content: article.body)) {
                                VStack(alignment: .leading) {
                                    Text(article.title)
                                        .font(.custom("Helvetica", size: 16))
                                    if isExpanded {
                                        Text(article.summary)
                                            .font(.custom("Helvetica", size: 12))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
            }
        }
    }
    
    init(searchString: String, isExpanded: Bool) {
        self.searchString = searchString.count >= 3 ? searchString : " "
        self.isExpanded = isExpanded
    }
}

#Preview {
    ArticlesSearchView()
}
