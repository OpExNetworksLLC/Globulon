//
//  UIViewRepresentable+GyroView.swift
//  Globulon
//
//  Created by David Holeman on 5/30/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import SceneKit
import CoreMotion
import SceneKit.ModelIO

struct GyroView: UIViewRepresentable {
    @Binding var deviceQuaternion: CMQuaternion
    var scale: CGFloat = 1.0

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var cameraRig: SCNNode?
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.backgroundColor = .black

        /// DEBUG:  Optional debug view
        //sceneView.debugOptions = [.showBoundingBoxes, .showWireframe]
        sceneView.debugOptions = [.showWireframe]
        
        let scene = SCNScene()
        sceneView.scene = scene

        // Load USDZ model
        guard let url = Bundle.main.url(forResource: "spinning_top", withExtension: "usdz") else {
            fatalError("Failed to find spinning_top.usdz in bundle.")
        }

        let asset = MDLAsset(url: url)
        asset.loadTextures()
        let topScene = SCNScene(mdlAsset: asset)

        // Anchor node for the top
        let topAnchorNode = SCNNode()
        let baseScale: Float = 0.0015
        topAnchorNode.scale = SCNVector3(baseScale * Float(scale), baseScale * Float(scale), baseScale * Float(scale))
        topAnchorNode.position = SCNVector3(0, -0.2, 0)
        scene.rootNode.addChildNode(topAnchorNode)

        for node in topScene.rootNode.childNodes {
            topAnchorNode.addChildNode(node)
        }

        // Create camera rig
        let cameraRig = SCNNode()
        context.coordinator.cameraRig = cameraRig
        scene.rootNode.addChildNode(cameraRig)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 6, 0)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        cameraRig.addChildNode(cameraNode)

        // Lighting
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.light?.intensity = 1000
        lightNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(lightNode)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 1000
        ambientLight.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLight)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let pitch = MotionManager.shared.attitudeData.pitch
        let roll = MotionManager.shared.attitudeData.roll
        let yaw = MotionManager.shared.attitudeData.yaw

        let yawQuat = simd_quatf(angle: Float(yaw), axis: simd_float3(0, 1, 0))
        let pitchQuat = simd_quatf(angle: Float(pitch), axis: simd_float3(1, 0, 0))
        let rollQuat = simd_quatf(angle: -Float(roll), axis: simd_float3(0, 0, 1))

        let combined = yawQuat * pitchQuat * rollQuat

        context.coordinator.cameraRig?.orientation = SCNQuaternion(
            combined.imag.x, combined.imag.y, combined.imag.z, combined.real
        )
    }
}
