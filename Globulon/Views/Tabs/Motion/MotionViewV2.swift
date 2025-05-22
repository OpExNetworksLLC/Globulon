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

    @State private var attitudeRotation = SCNVector3(x: 0, y: 0, z: 0)
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
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
                        Attitude3DBoxView(
                            rotation: $attitudeRotation,
                            faceColors: [
                                .red, .green, .blue,
                                .yellow, .orange, .purple
                            ]
                        )
                        .frame(width: 124, height: 124)
                        .onReceive(timer) { _ in
                            let att = motionManager.attitudeData
                            attitudeRotation = SCNVector3(att.pitch, att.yaw, att.roll)
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

import SwiftUI
import SceneKit

struct Attitude3DBoxView: UIViewRepresentable {
    @Binding var rotation: SCNVector3
    var faceColors: [UIColor]

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .white //TODO: toggle based on dark mode?

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 10)
        scene.rootNode.addChildNode(cameraNode)

        // Box with 6 labeled materials
        let box = SCNBox(width: 6, height: 9, length: 1, chamferRadius: 0)
        let labels = ["Front", "Right", "Back", "Left", "Top", "Bottom"]

        box.materials = zip(faceColors, labels).map { color, label in
            let mat = SCNMaterial()
            mat.diffuse.contents = labeledFaceImage(text: label, background: color)
            mat.isDoubleSided = true
            return mat
        }

        let boxNode = SCNNode(geometry: box)
        boxNode.name = "attitudeBox"
        boxNode.eulerAngles = rotation
        scene.rootNode.addChildNode(boxNode)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        if let node = uiView.scene?.rootNode.childNode(withName: "attitudeBox", recursively: false) {
            node.eulerAngles = rotation
        }
    }

    private func labeledFaceImage(text: String, background: UIColor) -> UIImage {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            background.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let style = NSMutableParagraphStyle()
            style.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.white,
                .paragraphStyle: style
            ]

            let textSize = text.size(withAttributes: attributes)
            let rect = CGRect(x: (size.width - textSize.width)/2,
                              y: (size.height - textSize.height)/2,
                              width: textSize.width,
                              height: textSize.height)

            text.draw(in: rect, withAttributes: attributes)
        }
    }
}
