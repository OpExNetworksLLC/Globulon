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

struct MotionView: View {
    @Binding var isShowSideMenu: Bool
    
    @StateObject var locationHandler = LocationHandler.shared
    @StateObject var motionHandler = MotionHandler.shared
    @StateObject var activityHandler = ActivityHandler.shared
    @StateObject var networkHandler = NetworkHandler.shared
    
    @State var isShowHelp = false
    @State private var isRecording = false

//    @State private var mapSpan: Double = 0.0025
//    private let mapSpanMinimum: Double = 0.002
//    private let mapSpanIncrement: Double = 0.004
    
    @State private var mapSpan: Double = 0.0001
    private let mapSpanMinimum: Double = 0.00005
    private let mapSpanIncrement: Double = 0.0001
    
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    ))

    var body: some View {
        // Top menu
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Lat/Lng:")
                        Spacer()
                        Text("\(locationHandler.lastLocation.coordinate.latitude), \(locationHandler.lastLocation.coordinate.longitude)")
                    }
                    HStack {
                        Text("Speed:")
                        Spacer()
                        Text("\(formatMPH(convertMPStoMPH(locationHandler.lastSpeed), decimalPoints: 2)) mph")
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
                        Text("\(motionHandler.accelerometerData.x), \(motionHandler.accelerometerData.y), \(motionHandler.accelerometerData.z)")
                    }
                    .padding(.trailing, 2)
                    HStack {
                        Text("Gyroscope XYZ:")
                        Spacer()
                        Text("\(motionHandler.gyroscopeData.x), \(motionHandler.gyroscopeData.y), \(motionHandler.gyroscopeData.z)")
                    }
                    .padding(.trailing, 2)
                    HStack {
                        Text("Attitude PYR:")
                        Spacer()
                        Text("\(motionHandler.attitudeData.pitch), \(motionHandler.attitudeData.yaw), \(motionHandler.attitudeData.roll)")
                    }
                    .padding(.trailing, 2)
                }
                .font(.system(size: 10, design: .monospaced))
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.bottom, 2)
     
    
                VStack {
                    HStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 100)
                            .rotationEffect(Angle(radians: motionHandler.attitudeData.roll), anchor: .center)
                            .rotation3DEffect(Angle(radians: motionHandler.attitudeData.pitch), axis: (x: 1, y: 0, z: 0))
                            .rotation3DEffect(Angle(radians: motionHandler.attitudeData.yaw), axis: (x: 0, y: 1, z: 0))
                        .padding()
                        Spacer().frame(width: 50)
                        SceneView(
                            scene: motionHandler.scene,
                            options: [.allowsCameraControl]
                        )
                        .frame(width: 100, height: 100)
                    }
                }
                .padding(.bottom, 2)
                
                VStack {
                    Chart {
                        ForEach(motionHandler.accelerationHistory) { dataPoint in
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
        let location = CLLocationCoordinate2D(latitude: locationHandler.lastLocation.coordinate.latitude,
                                              longitude: locationHandler.lastLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: mapSpan, longitudeDelta: mapSpan))
        cameraPosition = .region(region)
    }
}


#Preview {
    MotionView(isShowSideMenu: .constant(false))
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


import SceneKit

extension SCNGeometry {
    @MainActor static func cubeWithColoredSides(sideLength: CGFloat) -> SCNGeometry {
        let box = SCNBox(width: sideLength, height: sideLength, length: sideLength, chamferRadius: 0.0)

        // Assign different colors to each face of the cube
        let materials = [
            UIColor.red,    // front
            UIColor.green,  // right
            UIColor.blue,   // back
            UIColor.yellow, // left
            UIColor.cyan,   // top
            UIColor.magenta // bottom
        ].map { color -> SCNMaterial in
            let material = SCNMaterial()
            material.diffuse.contents = color
            return material
        }
        
        box.materials = materials
        
        // Edges setup
        let indices: [Int32] = [
            0, 1, 1, 2, 2, 3, 3, 0,
            4, 5, 5, 6, 6, 7, 7, 4,
            0, 4, 1, 5, 2, 6, 3, 7
        ]
        
        /// Not used right now
        //let sources = box.sources
        //let elements = box.elements
        
        let edgeGeometrySource = SCNGeometrySource(
            vertices: [
                SCNVector3(-0.5, -0.5, -0.5), SCNVector3(0.5, -0.5, -0.5),
                SCNVector3(0.5, 0.5, -0.5), SCNVector3(-0.5, 0.5, -0.5),
                SCNVector3(-0.5, -0.5, 0.5), SCNVector3(0.5, -0.5, 0.5),
                SCNVector3(0.5, 0.5, 0.5), SCNVector3(-0.5, 0.5, 0.5)
            ]
        )
        
        let edgeGeometryElement = SCNGeometryElement(
            indices: indices,
            primitiveType: .line
        )
        
        let edgeGeometry = SCNGeometry(sources: [edgeGeometrySource], elements: [edgeGeometryElement])
        edgeGeometry.firstMaterial?.diffuse.contents = UIColor.black
        
        let node = SCNNode(geometry: box)
        let edgeNode = SCNNode(geometry: edgeGeometry)
        node.addChildNode(edgeNode)
        
        //let geometry = SCNGeometry(sources: sources, elements: elements)
        let finalNode = SCNNode()
        finalNode.addChildNode(node)
        
        return box
    }
}
