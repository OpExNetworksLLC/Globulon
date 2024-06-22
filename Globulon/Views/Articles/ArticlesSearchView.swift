//
//  ArticlesSearchView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftData
import SwiftUI

/// This is the Articel Search View  that presents the user input of a search string then it's passed to another view that presents the filtered list.
///
struct ArticlesSearchView: View {
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var isSearching = false
    @State private var searchInput: String = ""
        
    var body: some View {
        VStack {
            HStack {
                VStack {
                    // start search bar
                    ZStack {
                        // Background Color
                        Color(.systemGray6).cornerRadius(5.0)
                        // Custom Search Bar (Search Bar + 'Cancel' Button)
                        HStack {
                            // Search Bar
                            HStack {
                                // Magnifying Glass Icon
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color(.gray))
                                // Search Area TextField
                                TextField("", text: $searchInput)
                                    .onChange(of: searchInput) {
                                        isSearching = true
                                        self.searchInput = searchInput.lowercased()  // force lower case
                                    }
                                    .accentColor(Color("colorBlackWhite"))
                                    .foregroundColor(Color("colorBlackWhite"))
                            }
                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                            .background(Color("searchBarTextBackgroundColor").cornerRadius(5.0))
                            
                            // 'Cancel' Button
                            Button(action: {
                                isSearching = false
                                searchInput = ""
                                
                                // Hide Keyboard
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }, label: {
                                Text("Cancel")
                            })
                            .accentColor(Color.blue)
                            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 0))
                        }
                        .padding(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    }
                    .frame(height: 56)
                    // end ZStack Search bar

                    // TODO:  Switch here between V1 and V2.  V1 is ideal but for now V2 works.
                    FilteredListV2(searchString: searchInput, isExpanded: UserSettings.init().isFaqExpanded)
                    
                    //FilteredListV1(searchString: searchInput, isExpanded: UserSettings.init().isFaqExpanded)
                    
                    // Hiding the background makes the list background transparent
                    .scrollContentBackground(.hidden)
                    
                    // end List
                }
            }
            .navigationBarTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Save the setting so it's remembered
                        userSettings.isFaqExpanded.toggle()// = isExpanded

                    }) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
            }
            )
            .onAppear {
                // We could load the FAQs here but may take too long so for now doing it in MainView() and when the pinned symbol changes in UserSettingsView()
            }
        .foregroundColor(.primary)
        }
    }
    
}

/// This version works but I had to abandon the search predicate in the Init() and go to a local filter on SectionsSD to filter out the unused sections.  The List view does a filter to remove the articles in the section since you cannot do a complex query in the predicate or search to also then filter those unmatched articles out.  I expect this to morph in terms of trying to get back to using the original predicate structure in the prior version.
///
struct FilteredListV2: View {
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.modelContext) private var context
    @Query var sectionsSD: [SectionsSD]
        
    private var isExpanded: Bool
    private var searchString: String
    
    var filteredSections: [SectionsSD] {
        sectionsSD.filter {
            $0.toArticles.flatMap {
                $0.contains { $0.search.contains(searchString) }
            } == true
        }
    }
    
    var body: some View {
        
        List(filteredSections) { result in
            Section(replaceString(string: result.section, old: AppValues.pinnedTag, new: AppValues.pinnedUnicode)) {
                ForEach(result.toArticles!) { article in
                    if article.search.contains(searchString) == true {
                        NavigationLink(destination: ArticleView(title: article.title, summary: article.summary, content: article.body)) {
                            VStack(alignment: .leading) {
                                Text(article.title)
                                    .font(.custom("Helvetica", size: 16))
                                if isExpanded {
                                    Text(article.summary)
                                        .font(.custom("Helvetica", size: 12))
                                        .foregroundColor(Color(UIColor.systemGray))
                                }
                            }
                        }
                    /// Hide the row separator
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
    }
    
    init(searchString: String, isExpanded: Bool) {
        if searchString.count >= 3 {
            self.searchString = searchString
        } else {
            self.searchString = " "
        }
        self.isExpanded = isExpanded
    }
    
}

/// This is the ideally structured way using a search predicate with the SectionsSD entity in SwiftData via init and passing it to the rest of the view.  Looks like there is a bonified known bug in Xcode 15 that is responsible.  Keep an eye on it's progress to see if it's resolved and try this example again.
///
/// From Apple's release notes under SwiftData Known Issues:
/// SwiftData queries don't support some #Predicate flatmap and nil coalescing behaviors. (109723704)
///
struct FilteredListV1: View {
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.modelContext) private var context
    @Query() var sectionsSD: [SectionsSD]
        
    private var isExpanded: Bool
    
    var body: some View {
        
        List(sectionsSD) { result in
            Section(result.section) {
                ForEach(result.toArticles!) { article in
                    NavigationLink(destination: ArticleView(title: article.title, summary: article.summary, content: article.body)) {
                        VStack(alignment: .leading) {
                            Text(article.title)
                                .font(.custom("Helvetica", size: 16))
                            if isExpanded {
                                Text(article.summary)
                                    .font(.custom("Helvetica", size: 12))
                                    .foregroundColor(Color(UIColor.systemGray))
                                Text(article.search)
                            }
                        }
                    }
                    // Hide the row separator
                    .listRowSeparator(.hidden)
                }
            }
        }
    }
    
    init(searchString: String, isExpanded: Bool) {
        if searchString.count >= 3 {
            let searchPredicate = #Predicate<SectionsSD> {
                $0.toArticles.flatMap {
                    $0.contains { $0.search.contains(searchString) }
                } == true
            }
            _sectionsSD = Query(filter: searchPredicate)
        }
        self.isExpanded = isExpanded
    }
    
}

#Preview {
    ArticlesSearchView()
}
