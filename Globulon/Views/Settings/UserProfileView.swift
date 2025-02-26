//
//  UserProfileView.swift
//  OpExShellV1
//
//  Created by David Holeman on 8/2/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var globalVariables: AppStatus
    @EnvironmentObject var userSettings: UserSettings
    
    @Binding var avatar: UIImage
    @Binding var alias: String

    @State var birthday: Date = Date()

    @State var isChanged: Bool = false
    
    var body: some View {
        
        NavigationView {
//            HStack {
                VStack() {
                    Form {
                        VStack(alignment: .leading) {
                            Text("Profile Settings!")
                                .font(.system(size: 24, weight: .bold))
                                .padding([.leading, .trailing], 16)
                                .padding(.bottom, 1)
                            Text("How you appear to others...")
                                .font(.system(size: 14))
                                .padding([.leading, .trailing], 16)
                            Spacer()
                        }
                        .frame(width: UIScreen.main.bounds.width - 36, height: 120, alignment: .leading)

                        /// Set the users AVATAR
                        ///
                        Section(header: Text("Avatar")) {
                            NavigationLink(destination: AvatarPickerView(title: "Avatar", subtitle: "Select an image then pinch and drag to size.  Press Accept to save.", avatar: $avatar)) {
                                HStack {
                                    Image(uiImage: avatar)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24, alignment: .center)
                                        .clipShape(Circle())
                                        .offset(x: -20)
                                        .onChange(of: avatar) { avatar, value in
                                            LogEvent.print(module: "UserProfileView", message: "Avatar changed")
                                        }
                                        .offset(x: 16)
                                    Text("Select image from photos")
                                }
                            }
                        }
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        // end section
                        
                        /// User entered ALIAS
                        ///
                        Section(header: Text("alias"), footer: Text("Your public name")) {
                            TextField("your online identifier", text: $alias)
                        }
                        .onChange(of: alias) {
                            if alias != userSettings.alias { isChanged = true }
                        }
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        // end section
                        
                        
                        /// User selected BIRTHDAY
                        ///
                        Section(header: Text("Birthday")) {
                            DatePicker(selection: $birthday, in: ...Date(), displayedComponents: .date, label: { Text("Birthday") })
                                .datePickerStyle(CompactDatePickerStyle())
                                .onAppear {
                                    // set the birthday to today if zero date value  TODO: reset zero if today
                                    if DateInfo.isZeroDate(date: userSettings.birthday) == true {birthday = Date()} else {birthday = userSettings.birthday}
                                }
                                .onChange(of: birthday) {
                                    if birthday != userSettings.birthday { isChanged = true }
                                }
                        }
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        // end section
                    }
                    .padding(.top, -16)
                    .clipped()
                    // end form

                    /* end stuff within our area */
                    Spacer()
                    Spacer().frame(height: 30)
                }
                .foregroundColor(.primary)
                .background(Color(UIColor.systemGroupedBackground))
                .listStyle(GroupedListStyle())
                .navigationBarTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            /// Reset since we are abandoning changes.  This makes sure that the old value is passed pack up in the alias binding to the MenuSettingsView()
                            saveSettings()
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            ImageNavCancel()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            saveSettings()
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(isChanged ? "Save" : "Done" )
                        }
                    }
            })

        }
        .onAppear {
            /// load up when the view appears so that if you make a change and come back while still in the setting menu the values are current.
            avatar = userSettings.avatar  //TODO: FIX avatar
            //avatar = UIImage(data: userSettings.avatar2)!
            alias = userSettings.alias
            birthday = userSettings.birthday
            isChanged = false
        }
    }
    
    private func saveSettings() {
        if alias != userSettings.alias {
            userSettings.alias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if birthday != userSettings.birthday { userSettings.birthday = birthday }
    }
}


#Preview {
    UserProfileView(avatar: .constant(UIImage(imageLiteralResourceName: "imgAvatarDefault")), alias: .constant("alias"))
        .environmentObject(UserSettings())
}
