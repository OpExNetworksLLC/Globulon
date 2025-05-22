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
    @StateObject var motionManager = MotionManager.shared
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

    //@State private var rotation = SCNVector3(0, 0, 0)
    
    @State private var deviceQuaternion: CMQuaternion = CMQuaternion(x: 0, y: 0, z: 0, w: 1)
    
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
                Spacer().frame(height: 16)
                
 
                /// MOTION
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
     
                /// ATTITUDE
                ///
                VStack {
                    HStack {
                        SceneKitBoxView(quaternion: $deviceQuaternion)
                            .frame(width: 200, height: 200)
                            .onReceive(motionManager.$attitudeData) { _ in
                                if let q = motionManager.deviceQuaternion {
                                    deviceQuaternion = q
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
                        Spacer().frame(width: 50)
                        SceneView(
                            scene: motionManager.scene,
                            options: [.allowsCameraControl]
                        )
                        .frame(width: 100, height: 100)
                    }
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

struct Gyroscope3DView: UIViewRepresentable {
    @Binding var rotation: SCNVector3

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true

        let box = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "gyroscopeBox"
        sceneView.scene?.rootNode.addChildNode(boxNode)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if let boxNode = uiView.scene?.rootNode.childNode(withName: "gyroscopeBox", recursively: false) {
            boxNode.eulerAngles = rotation
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
