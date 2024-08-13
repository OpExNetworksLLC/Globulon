//
//  MotionView.swift
//  Globulon
//
//  Created by David Holeman on 6/28/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import SwiftUI
import MapKit
import SceneKit
import Charts

struct MotionView: View {
    
    @Binding var isShowSideMenu: Bool
    
    @ObservedObject var locationHandler = LocationHandler.shared
    @ObservedObject var activityHandler = ActivityHandler.shared
    @ObservedObject var motionHandler = MotionHandler.shared
    
    @State private var isShowHelp = false
    @State private var isRecording = false
    
    @State private var mapSpan: Double = 0.0001
    private let mapSpanMinimum: Double = 0.00005
    private let mapSpanIncrement: Double = 0.0005
    
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
    ))

    var body: some View {
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
                .padding()
                Divider()
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Activity/State:")
                        Spacer()
                        Text("\(activityHandler.isActivity) / \(activityHandler.activityState)")
                    }
                    HStack {
                        Text("State:")
                        Spacer()
                        if self.locationHandler.isMoving {
                            Text("Moving")
                                .foregroundColor(.green)
                        } else {
                            Text("Static")
                                .foregroundColor(.red)
                        }
                    }
                    HStack {
                        Text("Mode:")
                        Spacer()
                        Text(self.locationHandler.isWalking ? "Walking" : "")
                            .foregroundColor(self.locationHandler.isWalking ? .green : .red)
                        Text(self.locationHandler.isDriving ? "Driving" : "")
                            .foregroundColor(self.locationHandler.isDriving ? .green : .red)
                    }
                    HStack {
                        Text("Trip:")
                        Spacer()
                        Text(self.locationHandler.isTripActive ? "Active Trip" : "")
                            .foregroundColor(self.locationHandler.isTripActive ? .green : .red)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 16)
                
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
                .padding()
                
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
                .padding()
                /*
                Gyroscope3DView(rotation: $activityHandler.rotation)
                    .frame(height: 100)
                    .padding()
                */
                
                
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
                
                
                Spacer().frame(height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                /*
                VStack{
                    List {
                        ForEach(activityHandler.motionDataBuffer, id: \.self) { detail in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(formatDateStampMSSS(detail.timestamp))")
                                    Spacer()
                                    Text("\(formatMPH(convertMPStoMPH(detail.speed), decimalPoints: 2)) mph")
                                }
                                HStack {
                                    Text("Accelerometer X:")
                                    Spacer()
                                    Text("\(detail.accelerometerX)")
                                }
                                HStack {
                                    Text("Accelerometer Y:")
                                    Spacer()
                                    Text("\(detail.accelerometerY)")
                                }
                                HStack {
                                    Text("Accelerometer Z:")
                                    Spacer()
                                    Text("\(detail.accelerometerZ)")
                                }
                                .padding(.bottom, 2)
                                HStack {
                                    Text("Gyroscope X:")
                                    Spacer()
                                    Text("\(detail.gyroscopeX)")
                                }
                                HStack {
                                    Text("Gyroscope Y:")
                                    Spacer()
                                    Text("\(detail.gyroscopeY)")
                                }
                                HStack {
                                    Text("Gyroscope Z:")
                                    Spacer()
                                    Text("\(detail.gyroscopeZ)")
                                }
                                .padding(.bottom, 2)

                                HStack {
                                    Text("Attitude Pitch:")
                                    Spacer()
                                    Text("\(detail.attitudePitch)")
                                }
                                HStack {
                                    Text("Attitude Yaw:")
                                    Spacer()
                                    Text("\(detail.attitudeYaw)")
                                }
                                HStack {
                                    Text("Attitude Roll:")
                                    Spacer()
                                    Text("\(detail.attitudeRoll)")
                                }
                                .padding(.bottom, 2)
                            }
                            .font(.system(size: 10, design: .monospaced))
                        }
                    }
                    .listStyle(.plain)
                }
                */
                Spacer()
            }
            .navigationBarTitle("", displayMode: .inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isShowSideMenu.toggle()
                    }) {
                        Image(systemName: "square.leftthird.inset.filled")
                            .font(.system(size: 26, weight: .ultraLight))
                            .frame(width: 35, height: 35)
                            .foregroundColor(AppSettings.pallet.primaryLight)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if motionHandler.isMotionMonitoringOn {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                    } else {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isRecording.toggle()
                        if isRecording {
                            motionHandler.startMotionUpdates()
                        } else {
                            motionHandler.stopMotionUpdates()
                        }
                    }) {
                        if isRecording {
                            Image(systemName: "record.circle")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(Color.red)
                                .frame(width: 35, height: 35)
                            Text("recording")
                                .foregroundColor(Color.red)

                        } else {
                            Image(systemName: "record.circle")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(AppSettings.pallet.primaryLight)
                                .foregroundColor(Color.red)
                                .frame(width: 35, height: 35)
                            Text("record")
                                .foregroundColor(AppSettings.pallet.primaryLight)
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Image("appLogoTransparent")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                        .foregroundColor(AppSettings.pallet.primaryLight)
                }
            }
        }
        .onAppear() {
            // TODO: I've turned this off as I don't want it automatically running when I open the view
            //
            //isRecording = locationHandler.updatesStarted
        }
        .onChange(of: locationHandler.updatesStarted) {
            isRecording = locationHandler.updatesStarted
        }
    }
    
    func updateCameraPosition() {
        let location = CLLocationCoordinate2D(latitude: locationHandler.siftLocation.coordinate.latitude,
                                              longitude: locationHandler.siftLocation.coordinate.longitude)
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
    static func cubeWithColoredSides(sideLength: CGFloat) -> SCNGeometry {
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
        
        let sources = box.sources
        let elements = box.elements
        
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
