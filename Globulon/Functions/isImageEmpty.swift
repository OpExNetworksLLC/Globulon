//
//  isImageEmpty.swift
//  ViDrive
//
//  Created by David Holeman on 2/20/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

// MARK: Check to see that while an image may exist does it have anything inside
// Used with the AvatarPickerView() to see if an actual image for the avatar has been selected
func isImageEmpty(_ image: UIImage) -> Bool {
    guard let cgImage = image.cgImage,
          let dataProvider = cgImage.dataProvider else
    {
        return true
    }

    let pixelData = dataProvider.data
    let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
    let imageWidth = Int(image.size.width)
    let imageHeight = Int(image.size.height)
    for x in 0..<imageWidth {
        for y in 0..<imageHeight {
            let pixelIndex = ((imageWidth * y) + x) * 4
            let r = data[pixelIndex]
            let g = data[pixelIndex + 1]
            let b = data[pixelIndex + 2]
            let a = data[pixelIndex + 3]
            if a != 0 {
                if r != 0 || g != 0 || b != 0 {
                    return false
                }
            }
        }
    }

    return true
}
