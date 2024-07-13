//
//  convertImageToData.swift
//  ViDrive
//
//  Created by David Holeman on 7/9/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import UIKit

func convertImageToData(image: UIImage) -> Data? {
    return image.pngData()
    //return image.jpegData(compressionQuality: 1.0) // or image.pngData()
}
