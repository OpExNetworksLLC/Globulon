//
//  AvatarPickerView.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

struct AvatarPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var globalVariables = AppStatus()
    @EnvironmentObject var userSettings: UserSettings
    
    var title: String
    var subtitle: String
    
    @State var isAccepted: Bool = false
    
    @State var isShowingImagePicker = false
    @State var isShowingActionPicker = false
    
    @Binding var avatar: UIImage
    
    @State var sourceType:UIImagePickerController.SourceType = .camera
    @State var image:UIImage?
    
    @State private var rect: CGRect = .zero
    @State private var uiimage: UIImage? = nil  // resized image
    
    var body: some View {
        HStack {
            Color("viewBackgroundColor").frame(width: 8)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 32))
                    .padding(.top, 0)
                    .padding(.bottom, 24)
                Text(subtitle)
                    //.font(.system(size: 16))
                Spacer().frame(height: 48)
                HStack {
                    Spacer()
                    VStack {
                        if image != nil {
                            ZoomScrollView {
                              Image(uiImage: image!)
                                .resizable()
                                .scaledToFit()
                            }
                            .frame(width: 300, height: 300, alignment: .center)
                            .clipShape(Circle())
                            .background(RectGetter(rect: $rect))  // Get the image coordinates and thus the image
                            
                        } else {
                            Image(uiImage: userSettings.avatar)  //TODO: FIX avatar
                            //Image(uiImage: UIImage(data: userSettings.avatar2)!)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300, alignment: .center)
                                .clipShape(Circle())
                                //.background(RectGetter(rect: $rect))  // Get the image coordinates and thus the image
                        }
                    }
                    Spacer()
                }
                Spacer()
                
                HStack {
                    Button(action: {
                        self.isShowingActionPicker = true
                    }, label: {
                        Text("Select Image")
                            .foregroundColor(.blue)
                    })
                    .frame(width: 130)
                    .buttonStyle(RoundedCorners())
                    .actionSheet(isPresented: $isShowingActionPicker, content: {
                        ActionSheet(title: Text("Select a profile avatar picture"), message: nil, buttons: [
                            .default(Text("Camera"), action: {
                                self.isShowingImagePicker = true
                                self.sourceType = .camera
                            }),
                            .default(Text("Photo Library"), action: {
                                self.isShowingImagePicker = true
                                self.sourceType = .photoLibrary
                            }),
                            .cancel()
                        ])
                    })
                    .sheet(isPresented: $isShowingImagePicker) {
                        imagePicker(image: $image, isShowingImagePicker: $isShowingImagePicker ,sourceType: self.sourceType)
                    }
                    
                    Spacer()
                    
                    /// Accepted button
                    Button(action: {
                        
                        //FIX self.uiimage = UIApplication.shared.windows[0].self.asImage(rect: self.rect)
                        
                        self.uiimage = UIApplication.shared.connectedScenes
                            .filter({$0.activationState == .foregroundActive})
                            .compactMap({$0 as? UIWindowScene})
                            .first?.windows[0].self.asImage(rect: self.rect)
                        
                        /// Save the image here if an image has been selected.  We have to look and see if the image size is zero and if not then we know a good image has been selected and we can go forward.  Setting these values update the user settings and updating the avatar updates the bound state so the avatar updates in both the UserProfileView() and the MenuSettingsView()
                        
                        if isImageEmpty(self.uiimage!) == false {
                            userSettings.avatar = self.uiimage!
                            avatar = self.uiimage!
                            
                            //userSettings.avatar2 = self.uiimage?.pngData() ?? AppValue.avatar.pngData()!
                        }
                        
                        /// exit when done
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    ) {
                        HStack {
                            Text("Accept").foregroundColor(.blue)
                        }
                    }
                    .frame(width: 102)
                    .padding(.top)
                    .padding(.bottom)
                    .buttonStyle(RoundedCorners())
                    .disabled(isAccepted)  // Disable if if already isAccepted is true
                }
            }
            Spacer()
            Color("viewBackgroundColor").frame(width: 8)
        }
        // FIX .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
        
        .background(Color("viewBackgroundColor"))
        //.background(Color(UIColor.clear))
    }
}

#Preview {
    AvatarPickerView(title: "Avatar", subtitle: "Select an image and then drag and pinch to size.  Press Accept to save.", avatar: .constant(UIImage(imageLiteralResourceName: "person.circle")) )
}
