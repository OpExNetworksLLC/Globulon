//
//  UserSupportView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import MessageUI

struct UserSupportView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var userSettings: UserSettings
    
//    @State var mySettingsContent: String = DisplaySettings.user
    
    @State var showMailSheet = false
    @State var alertNoMail = false
    
    
    // where we can control some of the tables appearance but not much.
    //    init(){
    //        UITableView.appearance().backgroundColor = .clear
    //    }
    
    var body: some View {
        
        NavigationView {
            HStack {
                VStack() {
                    /* start stuff within our area */
                    Form {
                        VStack(alignment: .leading) {
                            Text("Support!")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                                .padding([.leading, .trailing], 16)
                                .padding(.bottom, 1)
                            Text("Support resources...")
                                .foregroundColor(.primary)
                                .font(.system(size: 14))
                                .padding([.leading, .trailing], 16)
                            Spacer()
                            
                        }
                        .frame(width: AppValues.screen.width - 36, height: 120, alignment: .leading)
                        //.padding(.bottom, 16)
                        
                        Section(header: Text("FAQs")) {

                            NavigationLink(destination: ArticlesSearchView()) {
                                HStack {
                                    Text("Helpful Articles")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        
                        
                        // Start Resources
                        Section(header: Text("Resources")) {
                            /* TODO: Add back in with alternative ways to get support when available
                            NavigationLink(destination: SystemInfoView()) {
                                HStack {
                                    Text("Contact Us")
                                        .foregroundColor(.primary)
                                }
                            }
                            */
                            Button(action: {
                                self.showMailSheet.toggle()
                            }) {
                                Text("Email Us")
                                    .foregroundColor(.blue)
                            }
                            .onTapGesture {
                                MFMailComposeViewController.canSendMail() ? self.showMailSheet.toggle() : self.alertNoMail.toggle()
                            }
                            
                            .sheet(isPresented: self.$showMailSheet) {
                                MailView(isShowing: self.$showMailSheet,
                                         resultHandler: {
                                    value in
                                    switch value {
                                    case .success(let result):
                                        switch result {
                                        case .cancelled:
                                            LogEvent.print(module: "UserSupportView.MailView", message: "Email send cancelled")
                                        case .failed:
                                            LogEvent.print(module: "UserSupportView.MailView", message: "Email send failed")
                                        case .saved:
                                            LogEvent.print(module: "UserSupportView.MailView", message: "Email saved")
                                        default:
                                            LogEvent.print(module: "UserSupportView.MailView", message: "Email sent")

                                        }
                                    case .failure(let error):
                                        LogEvent.print(module: "UserSupportView.MailView", message: "Unexpected failure error: \(error.localizedDescription)")
                                    }
                                },
                                         subject: "Support Request",
                                         toRecipients: [AppValues.supportEmail],
                                         ccRecipients: [""],
                                         bccRecipients: [""],
                                         messageBody: "I need support with... " + "\r\n\n",
                                         isHtml: false)
                                .safe()
                            }
                            
                            
                            .alert(isPresented: self.$alertNoMail) {
                                Alert(title: Text("NO MAIL SETUP"))
                            }
                        }
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        // end Resources
                        
                        // Start System Info
                        Section(header: Text("System")) {
                            NavigationLink(destination: SystemInfoView()) {
                                HStack {
                                    Text("System info")
                                        .foregroundColor(.primary)
                                }
                            }
//                            NavigationLink(
//                                destination: ReviewDocView(title: "Settings",
//                                                           subtitle: "Review Setttings",
//                                                           content: mySettingsContent,
//                                                           isReviewed: .constant(false)
//                                                          )) {
//                                                              HStack {
//                                                                  Text("Review Settings")
//                                                              }
//                                                          }
                            NavigationLink(
                                destination: SettingsInfoView()) {
                                    HStack {
                                        Text("Review Settings")
                                            .foregroundColor(.primary)
                                    }
                                }
                            
                        }
                        .foregroundColor(.secondary)
                        .offset(x: -8)
                        .padding(.trailing, -8)
                        // end System Info
                        
                    }
                    .padding(.top, -16)
                    .clipped()
                    // end form
                    
                    /* end stuff within our area */
                    Spacer()
                    Spacer().frame(height: 30)  // This gap puts some separate between the keyboard and the scrolled field
                }
                .background(Color(UIColor.systemGroupedBackground))
                .listStyle(GroupedListStyle())
                .navigationBarTitle("Help")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            ImageNavCancel()
                        }
                    }
                }
                )
                // end
            }
            .onAppear {
                /// load up when the view appears so that if you make a change and come back while still in the setting menu the values are current.
//                mySettingsContent = DisplaySettings.user
                
            }
        }
    }
}


struct UserSupportView_Previews: PreviewProvider {
    static var previews: some View {
        UserSupportView()
    }
}

