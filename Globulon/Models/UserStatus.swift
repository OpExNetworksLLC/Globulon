//
//  UserStatus.swift
//  ViDrive
//
//  Created by David Holeman on 2/21/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import Foundation
import SwiftUI

/// Various global user states
///
class UserStatus: ObservableObject {
    @Published var isLoggedIn: Bool = false
}
