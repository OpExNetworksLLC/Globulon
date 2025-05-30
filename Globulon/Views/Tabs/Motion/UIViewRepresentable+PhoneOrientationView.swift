//
//  UIViewRepresentable+PhoneOrientationView.swift
//  Globulon
//
//  Created by David Holeman on 5/30/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SceneKit
import CoreMotion

struct PhoneOrientationView: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var quaternion: CMQuaternion
    var scale: CGFloat = 1.0

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = (colorScheme == .dark) ? .black : .white

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 15)
        scene.rootNode.addChildNode(cameraNode)

        // Axes
        addAxis(to: scene, axis: .x)
        addAxis(to: scene, axis: .y)
        addAxis(to: scene, axis: .z)
        
        let baseWidth: CGFloat = 6
        let baseHeight: CGFloat = 10
        let baseLength: CGFloat = 1.5

        let box = SCNBox(
            width: baseWidth * scale,
            height: baseHeight * scale,
            length: baseLength * scale,
            chamferRadius: 0
        )
        let faceLabels = ["Front", "Right", "Back", "Left", "Top", "Bottom"]
        let faceColors: [UIColor] = [.blue, .green, .red, .yellow, .orange, .purple]

        box.materials = zip(faceColors, faceLabels).map { color, label in
            let material = SCNMaterial()
            material.diffuse.contents = labeledFaceImage(text: label, background: color)
            material.isDoubleSided = true
            return material
        }

        let boxNode = SCNNode(geometry: box)
        boxNode.name = "attitudeBox"
        scene.rootNode.addChildNode(boxNode)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if let boxNode = uiView.scene?.rootNode.childNode(withName: "attitudeBox", recursively: false) {
            boxNode.orientation = SCNQuaternion(
                x: Float(quaternion.x),
                y: Float(quaternion.y),
                z: Float(quaternion.z),
                w: Float(quaternion.w)
            )
        }
    }

    private func labeledFaceImage(text: String, background: UIColor) -> UIImage {
        let size = CGSize(width: 128, height: 128)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(background.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)

        return UIGraphicsGetImageFromCurrentImageContext()!
    }

    private enum Axis {
        case x, y, z
    }

    private func addAxis(to scene: SCNScene, axis: Axis) {
        let axisNode = SCNNode()
        let cylinder = SCNCylinder(radius: 0.1, height: 20 * scale)
        let material = SCNMaterial()
        switch axis {
        case .x:
            material.diffuse.contents = UIColor.red
            axisNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        case .y:
            material.diffuse.contents = UIColor.green
        case .z:
            material.diffuse.contents = UIColor.blue
            axisNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        }
        cylinder.materials = [material]
        axisNode.geometry = cylinder
        scene.rootNode.addChildNode(axisNode)
    }
}
