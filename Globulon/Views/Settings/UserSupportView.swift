//
//  UserSupportView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

/**
 - Version: 1.0.1
 - Date: 2025.01.08
 - Note:
    - Version:  1.0.1 (2025.01.08)
        - added sub views and support for an email with a log attachment
 */

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
                        HeaderView()
                        FAQsView()
                        ResourcesView()
                        ReviewSettingsView()
                    }
                    .padding(.top, -16)
                    .clipped()

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
    
    //MARK: Sub Views
    struct HeaderView: View {
        var body: some View {
            VStack(alignment: .leading) {
                Text("User Support!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding([.leading, .trailing], 16)
                    .padding(.bottom, 1)
                
                Text("Support resources...")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .padding([.leading, .trailing], 16)
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width - 36, height: 120, alignment: .leading)
        }
    }
    struct FAQsView: View {
        var body: some View {
            Section(header: Text("FAQs")
                .foregroundColor(.secondary)
            ) {
                
                NavigationLink(destination: ArticlesSearchView()) {
                    HStack {
                        Text("Helpful Articles")
                            .foregroundColor(.primary)
                    }
                }
            }
            .offset(x: -8)
            .padding(.trailing, -8)
        }
    }
    struct ResourcesView: View {
        @State var showMailSheet = false
        @State var showMailAttachmentSheet = false
        @State var alertNoMail = false
        
        var body: some View {
            Section(header: Text("Resources")) {

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
                                LogManager.event(module: "UserSupportView.MailView", message: "Email send cancelled")
                            case .failed:
                                LogManager.event(module: "UserSupportView.MailView", message: "Email send failed")
                            case .saved:
                                LogManager.event(module: "UserSupportView.MailView", message: "Email saved")
                            default:
                                LogManager.event(module: "UserSupportView.MailView", message: "Email sent")
                                
                            }
                        case .failure(let error):
                            LogManager.event(module: "UserSupportView.MailView", message: "Unexpected failure error: \(error.localizedDescription)")
                        }
                    },
                             subject: "Support Request",
                             toRecipients: [AppSettings.supportEmail],
                             ccRecipients: [""],
                             bccRecipients: [""],
                             messageBody: "I need support with... " + "\r\n\n",
                             isHtml: false)
                    .safe()
                }
//                .alert(isPresented: self.$alertNoMail) {
//                    Alert(title: Text("NO MAIL SETUP"))
//                }
                
                Button(action: {
                    self.showMailAttachmentSheet.toggle()
                }) {
                    Text("Send us your log file")
                        .foregroundColor(.blue)
                }
                .onTapGesture {
                    MFMailComposeViewController.canSendMail() ? self.showMailAttachmentSheet.toggle() : self.alertNoMail.toggle()
                }
                .sheet(isPresented: self.$showMailAttachmentSheet) {
                    MailView(isShowing: self.$showMailAttachmentSheet,
                             resultHandler: {
                        value in
                        switch value {
                        case .success(let result):
                            switch result {
                            case .cancelled:
                                LogManager.event(module: "UserSupportView.MailView", message: "Email send cancelled")
                            case .failed:
                                LogManager.event(module: "UserSupportView.MailView", message: "Email send failed")
                            case .saved:
                                LogManager.event(module: "UserSupportView.MailView", message: "Email saved")
                            default:
                                LogManager.event(module: "UserSupportView.MailView", message: "Email sent")
                                
                            }
                        case .failure(let error):
                            LogManager.event(module: "UserSupportView.MailView", message: "Unexpected failure error: \(error.localizedDescription)")
                        }
                    },
                             subject: "Support Request",
                             toRecipients: [AppSettings.supportEmail],
                             ccRecipients: [""],
                             bccRecipients: [""],
                             messageBody: "I need support with... " + "\r\n\n",
                             isHtml: false,
                             attachments: getAttachment().map { [$0] } ?? [])
                    .safe()
                }
//                .alert(isPresented: self.$alertNoMail) {
//                    Alert(title: Text("NO MAIL SETUP"))
//                }
                
            }
            .offset(x: -8)
            .padding(.trailing, -8)
            /// shared alert(s)
            .alert(isPresented: self.$alertNoMail) {
                Alert(title: Text("NO MAIL SETUP"))
            }
            
            
        }
        func getAttachment() -> AttachmentData? {
            let fileManager = FileManager.default
            let logsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let logFileURL = logsDirectory.appendingPathComponent(AppSettings.log.filename)
            
            // Ensure the log file exists
            guard fileManager.fileExists(atPath: logFileURL.path) else {
                print("Log file does not exist at: \(logFileURL.path)")
                return nil
            }
            
            do {
                let fileData = try Data(contentsOf: logFileURL)
                let mimeType = "text/plain"
                let fileName = AppSettings.log.filename
                return (fileData, mimeType, fileName)
            } catch {
                print("Failed to read log file data: \(error.localizedDescription)")
                return nil
            }
        }
    }
    struct ReviewSettingsView: View {
        var body: some View {
            Section(header: Text("System")) {
                NavigationLink(destination: SystemInfoView()) {
                    HStack {
                        Text("System info")
                            .foregroundColor(.primary)
                    }
                }
                
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
        }
    }
}


struct UserSupportView_Previews: PreviewProvider {
    static var previews: some View {
        UserSupportView()
    }
}
