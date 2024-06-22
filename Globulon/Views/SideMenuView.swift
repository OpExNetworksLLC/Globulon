//
//  SideMenuView.swift
//  ViDrive
//
//  Created by David Holeman on 2/21/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var appStatus: AppStatus
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var userSettings: UserSettings
    
    @State var isShowProfileView = false
    //@State var title: String
    @State var isVersionSheetDisplayed = false
    
//    @State var avatar: UIImage = UIImage(imageLiteralResourceName: "imgAvatarDefault")         //myUserProfile.avatar
    @State var avatar: UIImage = UserSettings.init().avatar
    @State var alias: String = UserSettings.init().alias                //"<alias>"            //myUserProfile.alias
    @State var aliasDisplayed: String = AppDefaults.alias
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                // Your action to hide the side menu
                                appStatus.isShowSideMenu = false
                            }) {
                                HStack {
                                    Spacer() // Pushes the image to the right
                                    Image(systemName: "arrow.backward")
                                        .symbolVariant(.none) // Default style, no fill
                                        .font(.system(size: 24, weight: .thin)) // Size and weight
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                .frame(width: 64, height: 32) // Set the desired button width and adjust height accordingly
                            }
                            .padding(.trailing, 0)
                        }
                        
                        /// Profile
                        ///
                        VStack() {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    isShowProfileView.toggle()
                                }) {
                                    VStack {
                                        Image(uiImage: avatar)
                                            .resizable()
                                            .scaledToFit()
                                            .clipShape(Circle())
                                            .frame(width: 64, height: 64, alignment: .center)
                                            .padding(.bottom, 0)
                                            
                                            .onAppear {
                                                avatar = UserSettings.init().avatar
                                            }
                                            

                                        Text(aliasDisplayed)
                                            .font(.system(size: 18, weight: .regular, design: .default))
                                            .onAppear {
                                                if alias == "" { aliasDisplayed = AppDefaults.alias } else {aliasDisplayed = alias}
                                            }
                                            .onChange(of: alias) { alias, value in
                                                if value == "" { aliasDisplayed = AppDefaults.alias } else {aliasDisplayed = value}
                                            }
                                    }
                                    .foregroundColor(.primary)
                                }
                                .fullScreenCover(isPresented: $isShowProfileView, content: {
                                    //destinationView.environment(\.managedObjectContext, self.viewContext)
                                    UserProfileView(avatar: $avatar, alias: $alias)
                                })

                                
                                Spacer()
                            }
                            //Spacer()
                        }
                        .frame(height: 125)
                        
                        Divider()
                        
//                        Button("Home") {
//                            // Your Home action here
//                            appStatus.isShowSideMenu = false
//                            appStatus.selectedTab = 0
//                        }
//                        .padding(.top, 20)
                        
                        /// Settings
                        ///
                        ScrollView(.vertical, showsIndicators: false) {

                            VStack(alignment: .leading, spacing: 45) {
                                SettingsRow(title: "Account", icon: "creditcard", destinationView: UserAccountView())
                                SettingsRow(title: "Settings", icon: "slider.horizontal.3", destinationView: UserSettingsView())
                                SettingsRow(title: "Support", icon: "lifepreserver", destinationView: UserSupportView())
                                if UserSettings.init().userMode == .development {SettingsRow(title: "Developer", icon: "slider.horizontal.3", destinationView: DeveloperSettingsView())}
                                SignOutRow(title: "Sign out", icon: "square.and.arrow.up")

                            }
                            //.padding()
                            .padding(.leading, 6)
                            .padding(.top, 16)
                        }
                        
                        Spacer()

                        /// Version info
                        VStack(spacing: 0) {
                            Divider()
                                .padding(.bottom, 4)
                            HStack() {
                                Button {
                                    isVersionSheetDisplayed.toggle()
                                } label: {
                                    Text("version: \(AppInfo.version) (\(AppInfo.build))")
                                        .font(.system(size: 12, weight: .regular, design: .default))
                                }
                                .sheet(isPresented: $isVersionSheetDisplayed, content: {
                                    // Content of the sheet
                                    VersionSheetView(isVersionSheetDisplayed: $isVersionSheetDisplayed)
                                })
                                Spacer()
                                
                            }
//                            .padding(.leading, 32)
//                            .padding(.top, 8)
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.leading, 24) // set the leading padding for the items
                    .padding(.trailing, 8) // set the trailing padding for the arrow
                    
                    Spacer()
                }
            }
            .frame(width: getRect().width - AppValues.sideMenu.settingsMenuOffset)
            //.frame(maxHeight: .infinity)
            .background(Color(UIColor.systemGray6))
            
            .foregroundColor(.white)
            .transition(.move(edge: .leading))
            
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        // Calculate the percentage of the drag
                        let dragWidth = value.translation.width
                        let frameWidth = UIScreen.main.bounds.width
                        let dragPercentage = dragWidth / frameWidth

                        // If the drag to the left is more than 10% of the width, toggle the menu
                        if dragPercentage < -0.1 {
                            appStatus.isShowSideMenu = false
                        }
                    })
            )
        Spacer()
        }
    }
}

#Preview {
    SideMenuView()
}


// MARK: SettingsRow
struct SettingsRow<Content: View>: View {
    @Environment(\.managedObjectContext) var viewContext
    @State var isShowView = false
    
    var title: String
    var icon: String
    var destinationView: Content

    init(title: String, icon: String, destinationView: Content) {
        self.destinationView = destinationView
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack {
            Button(action: {
                isShowView.toggle()
            }) {
                HStack() {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 22, height: 22)
                        
                        Text(title)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                //.padding(.leading, 20)
            }
            .fullScreenCover(isPresented: $isShowView, content: {
                destinationView.environment(\.managedObjectContext, self.viewContext)
            })
        }
    }
    
}

// MARK: Signout Row
struct SignOutRow: View {
    //@Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var globalVariables: AppStatus
    
    var title: String
    var icon: String

    init(title: String, icon: String) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack {
            Button(action: {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    NotificationCenter.default.post(name: Notification.Name("isLoggedOut"), object: nil)
                }
                
                self.presentationMode.wrappedValue.dismiss()
                
            }) {
                HStack() {
                    
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 22, height: 22)
                        
                        Text(title)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
            }
        }
    }
    
}
