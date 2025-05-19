//
//  MainView.swift
//  Globulon
//
//  Created by David Holeman on 02/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var appVariables: AppStatus
    @EnvironmentObject var userSettings: UserSettings

    @StateObject var networkManager = NetworkManager.shared
    
    @StateObject var motionManager = MotionManager.shared
    @State private var isRecording = false
    
    @State private var showNetworkAlert = false
    
    @State var isShowView = false
    
    @State var avatar: UIImage = UserSettings.init().avatar
    @State var alias: String = UserSettings.init().alias
    @State var aliasDisplayed: String = AppDefaults.alias
    
    @State private var isShowProfileView = false
    @State private var isShowAccountView = false
    @State private var isShowSettingsView = false
    @State private var isShowSupportView = false
    @State private var isShowDeveloperView = false
    @State private var isShowSystemStatusView = false
    
    
    @State private var isShowHelp = false
    @State private var isShowVersionSheet = false
    
    @State var currentTab =  UserSettings.init().landingPage
    @State var lastTab =  UserSettings.init().landingPage.description
    
    /// Menu states
    @State private var isShowAnimatedSideMenu: Bool = false // State toggles based on if menu is showing or not
    @State private var rotateWhenExpands: Bool = true       // Does the main screen rotate to show the menu show flat
    @State private var disablesInteractions: Bool = false   // Disables menu option click action
    @State private var disableCorners: Bool = false         // Rounded or square corners on the main screen
    
    var body: some View {
        AnimatedSideBar(
            rotatesWhenExpands: rotateWhenExpands,
            disablesInteraction: disablesInteractions,
            sideMenuWidth: AppSettings.sideMenu.menuWidth,
            cornerRadius: disableCorners ? 0 : 25,
            showMenu: $isShowAnimatedSideMenu
        ) { safeArea in
            
            /// Start the NavigationStack
            ///
            NavigationStack {
                
                /// Identify your Tabs here
                ///
                TabView(selection: $currentTab) {
                    HomeView(isShowSideMenu: $appVariables.isShowSideMenu)
                        .tabItem {
                            Image("symHome")
                            Text("Home")
                        }
                        .tag(LandingPageEnum.home)
                    
                    /// Since the using the center logo with .principal forces a space this is what we do to work back around that
                    /// start ...
                        .safeAreaPadding(.top, 100)
                        .safeAreaPadding(.bottom, 83)
                        .ignoresSafeArea()
                    /// ... end
                    
                    TravelView(isShowSideMenu: $appVariables.isShowSideMenu)
                        .tabItem {
                            Image(systemName: "steeringwheel")
                            Text("Travel")
                        }
                        .tag(LandingPageEnum.travel)
                        .safeAreaPadding(.top, 100)
                        .safeAreaPadding(.bottom, 83)
                        .ignoresSafeArea()
                    
                    MotionView(isShowSideMenu: $appVariables.isShowSideMenu)
                        .tabItem {
                            Image(systemName: "circle.dotted.and.circle")
                            Text("Motion")
                        }
                        .tag(LandingPageEnum.motion)
                        .safeAreaPadding(.top, 100)
                        .safeAreaPadding(.bottom, 83)
                        .ignoresSafeArea()
                    
                    MoreView()
                        .tabItem {
                            Image(systemName: "ellipsis")
                            Text("More")
                        }
                        .tag(LandingPageEnum.more)
                        .safeAreaPadding(.top, 100)
                        .safeAreaPadding(.bottom, 83)
                        .ignoresSafeArea()
                    
                    /*
                    ActivityView(isShowSideMenu: $appVariables.isShowSideMenu)
                        .tabItem {
                            Image(systemName: "arrow.triangle.pull")
                            Text("Activity")
                        }
                        .tag(LandingPageEnum.activity)
                        .safeAreaPadding(.top, 100)
                        .safeAreaPadding(.bottom, 83)
                        .ignoresSafeArea()
                    
                    BluetoothView(isShowSideMenu: $appVariables.isShowSideMenu)
                        .tabItem {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Bluetooth")
                        }
                        .tag(LandingPageEnum.bluetooth)
                        .safeAreaPadding(.top, 100)
                        .safeAreaPadding(.bottom, 83)
                        .ignoresSafeArea()
                     
                    */
                    
                    
                }
                .onChange(of: currentTab) {
                    /// actively set these tabs  to rotate the view when showing the side menu if the default is set to true:
                    ///
                    ///`rotateWhenExpands = [.home, .status, .bluetooth].contains(currentTab)
                    ///
                    /// or since the default is true to rotate the side menu set to false for identified tabs
                    ///
                    //rotateWhenExpands = ![.travel].contains(currentTab)

                }
                .toolbar {
                    
                    /// Side Menu
                    ///
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { isShowAnimatedSideMenu.toggle() }) {
                            Image(systemName: isShowAnimatedSideMenu ? "xmark" : "square.leftthird.inset.filled")
                                .font(.system(size: 26, weight: .ultraLight))
                                .frame(width: 32, height:32)
                                .foregroundColor(AppSettings.pallet.primaryLight)
                                .contentTransition(.symbolEffect)
                        }
                    }
                    
                    /// App logo
                    ///
                    ToolbarItem(placement: .principal) {
                        Image("symLogo")
                            .resizable()
                            .renderingMode(.original)
                            .foregroundStyle(AppSettings.symLogo.primaryLight, AppSettings.symLogo.primary, AppSettings.symLogo.primaryDark)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)
                    }
                    
                    /// Show the network connectivity status only on the home tab
                    ///
                    if currentTab == .home {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            if networkManager.isConnected {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                    
                    if currentTab == .motion {
                        ToolbarItem(placement: .navigationBarLeading) {
                            if motionManager.isMotionMonitoringOn {
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                            } else {
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                isRecording.toggle()
                                if isRecording {
                                    motionManager.startMotionUpdates()
                                } else {
                                    motionManager.stopMotionUpdates()
                                }
                            }) {
                                if isRecording {
                                    Image(systemName: "record.circle")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(Color.red)
                                        .frame(width: 35, height: 35)
                                    Text("recording")
                                        .foregroundColor(Color.red)

                                } else {
                                    Image(systemName: "record.circle")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(AppSettings.pallet.primaryLight)
                                        .foregroundColor(Color.red)
                                        .frame(width: 35, height: 35)
                                    Text("record")
                                        .foregroundColor(AppSettings.pallet.primaryLight)
                                }
                            }
                        }
                    }
                    
                    /// Help
                    ///
                    /// Define the tabs where the help button should be hidden
                    let excludedTabs: [LandingPageEnum] = [.motion]

                    /// Conditionally include the ToolbarItem only if currentTab is NOT in excludedTabs
                    if !excludedTabs.contains(currentTab) {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                isShowHelp.toggle()
                            }) {
                                Image(systemName: "questionmark")
                                    .font(.system(size: 22, weight: .light))
                                    .foregroundColor(AppSettings.pallet.primaryLight)
                                    .frame(width: 35, height: 35)
                            }
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline) // Gets rid of other views adding a line after the toolbar
                .fullScreenCover(isPresented: $isShowHelp) {
                    NavigationView {
                        ArticlesSearchView()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: {
                                        isShowHelp.toggle()
                                    }) {
                                        ImageNavCancel()
                                    }
                                }
                                ToolbarItem(placement: .principal) {
                                    Text("search")
                                }
                            }
                    }
                }
            }
            /// end nav stack
            
        } menuView: { safeArea in
            SideBarMenuView(safeArea)

        } background: {
            Rectangle()
                .fill(Color("sideMenuBackgroundColor"))
        }
    }
    
    @ViewBuilder
    func SideBarMenuView(_ safeArea: UIEdgeInsets) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            
            
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
            }
            .frame(height: 125)
            
            Rectangle()
            //.fill(colorScheme == .dark ? .black : .white)
                .fill(.primary)
                .frame(height: 0.5)
                .edgesIgnoringSafeArea(.horizontal)
            
            /// Account
            ///
            Button(action: {
                withAnimation {
                    isShowAccountView.toggle()
                }
            }, label: {
                HStack(spacing: 12) {
                    Image(systemName: "creditcard")
                        .font(.title3)
                    
                    Text("Account")
                        .font(.callout)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
                .foregroundStyle(Color.primary)
            })
            .fullScreenCover(isPresented: $isShowAccountView) {
                UserAccountView()
            }
            
            /// Settings
            ///
            Button(action: {
                withAnimation {
                    isShowSettingsView.toggle()
                }
            }, label: {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                    
                    Text("Settings")
                        .font(.callout)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
                .foregroundStyle(Color.primary)
            })
            .fullScreenCover(isPresented: $isShowSettingsView) {
                UserSettingsView()
            }
            
            /// Support
            ///
            Button(action: {
                withAnimation {
                    isShowSupportView.toggle()
                }
            }, label: {
                HStack(spacing: 12) {
                    Image(systemName: "lifepreserver")
                        .font(.title3)
                    
                    Text("Support")
                        .font(.callout)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
                .foregroundStyle(Color.primary)
            })
            .fullScreenCover(isPresented: $isShowSupportView) {
                UserSupportView()
            }
            
            /// Developer
            ///
            Button(action: {
                withAnimation {
                    isShowDeveloperView.toggle()
                }
            }, label: {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                    
                    Text("Developer")
                        .font(.callout)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
                .foregroundStyle(Color.primary)
            })
            .fullScreenCover(isPresented: $isShowDeveloperView) {
                DeveloperSettingsView()
            }
            
            /// System Status
            ///
            Button(action: {
                withAnimation {
                    isShowSystemStatusView.toggle()
                }
            }, label: {
                HStack(spacing: 12) {
                    Image(systemName: "stethoscope")
                        .font(.title3)
                    
                    Text("Status")
                        .font(.callout)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
                .foregroundStyle(Color.primary)
            })
            .fullScreenCover(isPresented: $isShowSystemStatusView) {
                SystemStatusView()
            }
            
            /// Logout
            ///
            Button(action: {
                withAnimation {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        NotificationCenter.default.post(name: Notification.Name("isLoggedOut"), object: nil)
                    }
                    
                    self.presentationMode.wrappedValue.dismiss()
                }
            }, label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                        .font(.title3)
                    
                    Text("Logout")
                        .font(.callout)
                    
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
                .foregroundStyle(Color.primary)
            })
            .fullScreenCover(isPresented: $isShowView) {
                DeveloperSettingsView()
            }
            
            Spacer(minLength: 0)
            
            /// Version info
            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 0.5)
                    .edgesIgnoringSafeArea(.horizontal)
                    .padding(.bottom, 4)
                HStack() {
                    Button {
                        isShowVersionSheet.toggle()
                    } label: {
                        Text("version: \(VersionManager.releaseDesc)")
                            .font(.system(size: 12, weight: .regular, design: .default))
                    }
                    .sheet(isPresented: $isShowVersionSheet, content: {
                        VersionSheetView(isShowVersionSheet: $isShowVersionSheet)
                    })
                    Spacer()
                    
                }
                .foregroundColor(.primary)
            }
            
            //SideBarButton(.logout)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 20)
        .padding(.top, safeArea.top)
        .padding(.bottom, safeArea.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.colorScheme, .dark)
    }
    
}


#Preview {
    MainView()
        .environmentObject(AppStatus())
        .environmentObject(UserSettings())
        .environmentObject(AppEnvironment())
}
