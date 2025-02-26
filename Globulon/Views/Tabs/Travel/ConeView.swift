//
//  ConeView.swift
//  Globulon
//
//  Created by David Holeman on 2/25/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI

// Cone Shape
struct ConeView: Shape {
    var heading: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = rect.width / 2

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(heading - 30),
            endAngle: .degrees(heading + 30),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

