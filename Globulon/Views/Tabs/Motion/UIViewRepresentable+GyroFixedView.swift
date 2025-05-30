//
//  UIViewRepresentable+GyroFixedView.swift
//  Globulon
//
//  Created by David Holeman on 5/30/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SceneKit

struct GyroFixedView: UIViewRepresentable {
    @Binding var rotation: SCNVector3

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var anchorNode: SCNNode?
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.backgroundColor = .black

        // Enable visual debugging (optional)
        sceneView.debugOptions = [.showBoundingBoxes, .showWireframe]

        // Load USDZ model from bundle
        guard let url = Bundle.main.url(forResource: "spinning_top", withExtension: "usdz") else {
            fatalError("Failed to find spinning_top.usdz in bundle.")
        }

        let asset = MDLAsset(url: url)
        asset.loadTextures()
        let scene = SCNScene(mdlAsset: asset)
        sceneView.scene = scene

        // Create anchor node to rotate
        let anchorNode = SCNNode()
        context.coordinator.anchorNode = anchorNode
        scene.rootNode.addChildNode(anchorNode)

        // Move all root children into anchorNode
        for node in scene.rootNode.childNodes where node !== anchorNode {
            anchorNode.addChildNode(node)
        }

        // Scale & position to ensure visibility
        anchorNode.scale = SCNVector3(0.0009, 0.0009, 0.0009)
        anchorNode.position = SCNVector3(0, -0.2, 0)

        // Fixed camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)

        // Directional light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.light?.intensity = 1000
        lightNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(lightNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        ambientLight.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLight)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Lock pitch & roll, rotate only around Y (yaw)
        context.coordinator.anchorNode?.eulerAngles = SCNVector3(0, rotation.y, 0)
    }
}
