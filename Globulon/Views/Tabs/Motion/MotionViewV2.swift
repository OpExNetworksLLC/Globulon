//
//  MotionView.swift
//  Globulon
//
//  Created by David Holeman on 3/4/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//


import SwiftUI
import MapKit
import SceneKit
import Charts
import CoreMotion

struct MotionViewV2: View {
    @Binding var isShowSideMenu: Bool
    
    @StateObject var locationManager = LocationManager.shared
    //@StateObject var motionManager = MotionManager.shared
    @StateObject var activityManager = ActivityManager.shared
    @StateObject var networkManager = NetworkManager.shared
    
    @State var isShowHelp = false
    @State private var isRecording = false
    
    @State private var mapSpan: Double = 0.0001
    private let mapSpanMinimum: Double = 0.00005
    private let mapSpanIncrement: Double = 0.0001
    
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    ))
    
    @State private var deviceQuaternion: CMQuaternion = CMQuaternion(x: 0, y: 0, z: 0, w: 1)
    
    //@State private var gyroscopeRotation = SCNVector3Zero
    @ObservedObject var motionManager = MotionManager.shared
    
    var body: some View {
        // Top menu
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Lat/Lng:")
                        Spacer()
                        Text("\(locationManager.lastLocation.coordinate.latitude), \(locationManager.lastLocation.coordinate.longitude)")
                    }
                    HStack {
                        Text("Speed:")
                        Spacer()
                        Text("\(formatMPH(convertMPStoMPH(locationManager.lastSpeed), decimalPoints: 2)) mph")
                    }
                }
                .font(.system(size: 12, design: .monospaced))
                .padding()
                Divider()
                Spacer().frame(height: 8)
                
 
                /// MOTION DATA FEED
                ///
                VStack(alignment: .leading) {
                    HStack {
                        Text("Accelerometer XYZ:")
                        Spacer()
                        Text("\(motionManager.accelerometerData.x), \(motionManager.accelerometerData.y), \(motionManager.accelerometerData.z)")
                    }
                    .padding(.trailing, 2)
                    HStack {
                        Text("Gyroscope XYZ:")
                        Spacer()
                        Text("\(motionManager.gyroscopeData.x), \(motionManager.gyroscopeData.y), \(motionManager.gyroscopeData.z)")
                    }
                    .padding(.trailing, 2)
                    HStack {
                        Text("Attitude PYR:")
                        Spacer()
                        Text("\(motionManager.attitudeData.pitch), \(motionManager.attitudeData.yaw), \(motionManager.attitudeData.roll)")
                    }
                    .padding(.trailing, 2)
                }
                .font(.system(size: 10, design: .monospaced))
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.bottom, 2)
                Divider()
                Spacer().frame(height: 8)
     
                /// ATTITUDE
                ///
                VStack {
                    HStack {
                        SceneKitBoxView(quaternion: $deviceQuaternion)
                            .frame(width: 150, height: 150)
                            .onReceive(motionManager.$attitudeData) { attitude in
                                if let q = motionManager.deviceQuaternion {
                                    let qNoYaw = removeYaw(from: q, pitch: attitude.pitch, roll: attitude.roll)
                                    deviceQuaternion = qNoYaw
                                }
                            }
                        
                        /*
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 100)
                            .rotationEffect(Angle(radians: motionManager.attitudeData.roll), anchor: .center)
                            .rotation3DEffect(Angle(radians: motionManager.attitudeData.pitch), axis: (x: 1, y: 0, z: 0))
                            .rotation3DEffect(Angle(radians: motionManager.attitudeData.yaw), axis: (x: 0, y: 1, z: 0))
                        .padding()
                        */
                        Spacer().frame(width: 24)
                        GyroscopeTopFixedView(rotation: $motionManager.gyroscopeRotation)
                            .frame(width: 100, height: 150)

                    }
                }
                .padding(.bottom, 2)

                VStack {
                    PhoneOrientationAroundTopView(deviceQuaternion: $deviceQuaternion)
                        .frame(width: 150, height: 150)
                    
                    SpinningTopWithAttitudeBoxView(attitude: $motionManager.attitudeData, scale: 0.5)
                        .frame(width: 150, height: 150)
                }
                .padding(.bottom, 2)
                
                /// ACCELERATION
                ///
                VStack {
                    Chart {
                        ForEach(motionManager.accelerationHistory) { dataPoint in
                            LineMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("X", dataPoint.x)
                            )
                            .foregroundStyle(.red)
                            
                            LineMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Y", dataPoint.y)
                            )
                            .foregroundStyle(.green)
                            
                            LineMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Z", dataPoint.z)
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                    .chartYScale(domain: -3...3)
                    .chartYAxis {
                        //AxisMarks(values: .stride(by: 0.1))
                        AxisMarks(values: .stride(by: 1.0))
                    }
                    /*
                    .chartXAxis {
                        AxisMarks(format: .dateTime)
                    }
                    */
                    .chartXAxis(.hidden)
                    
                    .padding()
                }
                .frame(height: 250)
                
                ///  This is how/when one could ask for permission
                .onAppear {
                    CLLocationManager().requestWhenInUseAuthorization()
                }
                
                
                Spacer()
            }

        }
    }
    func updateCameraPosition() {
        let location = CLLocationCoordinate2D(latitude: locationManager.lastLocation.coordinate.latitude,
                                              longitude: locationManager.lastLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: mapSpan, longitudeDelta: mapSpan))
        cameraPosition = .region(region)
    }
}


#Preview {
    MotionViewV2(isShowSideMenu: .constant(false))
}

import SwiftUI
import SceneKit
import SceneKit.ModelIO
import CoreMotion

struct SpinningTopWithAttitudeBoxView: UIViewRepresentable {
    @Binding var attitude: MotionManager.AttitudeData
    var scale: CGFloat = 1.0

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var anchorNode: SCNNode?
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .black
        sceneView.debugOptions = [.showBoundingBoxes, .showWireframe]

        let scene = SCNScene()
        sceneView.scene = scene

        // Create anchor node that will rotate
        let anchorNode = SCNNode()
        context.coordinator.anchorNode = anchorNode
        scene.rootNode.addChildNode(anchorNode)

        // Load spinning top model
        guard let url = Bundle.main.url(forResource: "spinning_top", withExtension: "usdz") else {
            fatalError("spinning_top.usdz not found.")
        }

        let asset = MDLAsset(url: url)
        asset.loadTextures()
        let topScene = SCNScene(mdlAsset: asset)

        let topNode = SCNNode()
        for child in topScene.rootNode.childNodes {
            topNode.addChildNode(child)
        }
        topNode.scale = SCNVector3(0.001 * scale, 0.001 * scale, 0.001 * scale)
        topNode.position = SCNVector3(0, -0.2, 0)
        anchorNode.addChildNode(topNode)

        // Create box geometry with visible wireframe
        let boxGeometry = SCNBox(
            width: 0.15 * scale,
            height: 0.25 * scale,
            length: 0.15 * scale,
            chamferRadius: 0.01 * scale
        )
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0.1)
        material.transparency = 1.0
        material.lightingModel = .constant
        material.isDoubleSided = true
        boxGeometry.materials = [material]

        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.position = SCNVector3(0, -0.2, 0)
        anchorNode.addChildNode(boxNode)

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 3)
        scene.rootNode.addChildNode(cameraNode)

        // Light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(0, 5, 5)
        scene.rootNode.addChildNode(lightNode)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let pitch = Float(attitude.pitch)
        let yaw = Float(attitude.yaw)
        let roll = Float(attitude.roll)

        context.coordinator.anchorNode?.eulerAngles = SCNVector3(pitch, yaw, roll)
    }
}

struct PhoneOrientationAroundTopView: UIViewRepresentable {
    @Binding var deviceQuaternion: CMQuaternion

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
        topAnchorNode.scale = SCNVector3(0.0015, 0.0015, 0.0015)
        topAnchorNode.position = SCNVector3(0, -0.2, 0)
        scene.rootNode.addChildNode(topAnchorNode)

        for node in topScene.rootNode.childNodes {
            topAnchorNode.addChildNode(node)
        }

        // Create camera rig (this node rotates with device orientation)
        let cameraRig = SCNNode()
        context.coordinator.cameraRig = cameraRig
        scene.rootNode.addChildNode(cameraRig)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // side view
        //cameraNode.position = SCNVector3(0, 0, 6)
        
        // top view
        cameraNode.position = SCNVector3(0, 6, 0) // Camera is above the top
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0) // Look straight down
        
        cameraRig.addChildNode(cameraNode)

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
        ambientLight.light?.intensity = 800
        ambientLight.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLight)

        return sceneView
    }
    func updateUIView(_ uiView: SCNView, context: Context) {
        let pitch = MotionManager.shared.attitudeData.pitch
        let roll = MotionManager.shared.attitudeData.roll
        let yaw = MotionManager.shared.attitudeData.yaw

        // Compose quaternions: yaw * pitch * roll
        // Reverse the roll so the world appears stable while the camera tilts
        let yawQuat = simd_quatf(angle: Float(yaw), axis: simd_float3(0, 1, 0))
        let pitchQuat = simd_quatf(angle: Float(pitch), axis: simd_float3(1, 0, 0))
        let rollQuat = simd_quatf(angle: -Float(roll), axis: simd_float3(0, 0, 1))  // Note the NEGATIVE roll

        // Combine in the correct order: yaw → pitch → inverse roll
        let combined = yawQuat * pitchQuat * rollQuat

        context.coordinator.cameraRig?.orientation = SCNQuaternion(
            combined.imag.x, combined.imag.y, combined.imag.z, combined.real
        )
    }
}


struct GyroscopeTopFixedView: UIViewRepresentable {
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

struct Gyroscope3DView: UIViewRepresentable {
    @Binding var rotation: SCNVector3

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.backgroundColor = .black

        // Create a stylized spinning top shape using a cone
        let topGeometry = SCNCone(topRadius: 0.0, bottomRadius: 0.5, height: 1.2)
        topGeometry.materials.first?.diffuse.contents = UIColor.systemPink

        let topNode = SCNNode(geometry: topGeometry)
        topNode.name = "gyroscopeTop"
        topNode.scale = SCNVector3(0.5, 0.5, 0.5)
        scene.rootNode.addChildNode(topNode)

        // Add a fixed camera to simulate a stable frame of reference
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)

        // Add directional light for depth
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(lightNode)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if let topNode = uiView.scene?.rootNode.childNode(withName: "gyroscopeTop", recursively: false) {
            topNode.eulerAngles = rotation
        }
    }
}

struct SceneKitBoxView: UIViewRepresentable {
    @Binding var quaternion: CMQuaternion

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .gray

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 15)
        scene.rootNode.addChildNode(cameraNode)

        // Axes
        addAxis(to: scene, axis: .x)
        addAxis(to: scene, axis: .y)
        addAxis(to: scene, axis: .z)

        // Box with labeled faces
        let box = SCNBox(width: 5, height: 9, length: 1, chamferRadius: 0)
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
        let cylinder = SCNCylinder(radius: 0.1, height: 20)
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

func removeYaw(from q: CMQuaternion, pitch: Double, roll: Double) -> CMQuaternion {
    // Pitch (forward/back) = X axis
    // Roll (left/right tilt) = Y axis — corrected from previous Z

    let qPitch = simd_quatf(angle: Float(pitch), axis: simd_float3(1, 0, 0)) // SceneKit X
    let qRoll = simd_quatf(angle: Float(roll), axis: simd_float3(0, 1, 0))  // SceneKit Y

    // Correct rotation order: first roll, then pitch
    let combined = qPitch * qRoll

    return CMQuaternion(
        x: Double(combined.imag.x),
        y: Double(combined.imag.y),
        z: Double(combined.imag.z),
        w: Double(combined.real)
    )
}
