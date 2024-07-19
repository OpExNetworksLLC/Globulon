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
                        Text("Moving")
                            .foregroundColor(self.locationHandler.isMoving ? .green : .red)
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
                .padding(.trailing, 32)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Accelerometer XYZ:")
                        Spacer()
                        Text("\(activityHandler.accelerometerData.x), \(activityHandler.accelerometerData.y), \(activityHandler.accelerometerData.z)")
                    }
                    .padding(.trailing, 2)
                    HStack {
                        Text("Gyroscope XYZ:")
                        Spacer()
                        Text("\(activityHandler.gyroscopeData.x), \(activityHandler.gyroscopeData.y), \(activityHandler.gyroscopeData.z)")
                    }
                    .padding(.trailing, 2)
                    HStack {
                        Text("Attitude PYR:")
                        Spacer()
                        Text("\(activityHandler.attitudeData.pitch), \(activityHandler.attitudeData.yaw), \(activityHandler.attitudeData.roll)")
                    }
                    .padding(.trailing, 2)
                }
                .font(.system(size: 10, design: .monospaced))
                .padding()
                
                VStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 100)
                        .rotationEffect(Angle(radians: activityHandler.attitudeData.roll), anchor: .center)
                        .rotation3DEffect(Angle(radians: activityHandler.attitudeData.pitch), axis: (x: 1, y: 0, z: 0))
                        .rotation3DEffect(Angle(radians: activityHandler.attitudeData.yaw), axis: (x: 0, y: 1, z: 0))
                        .padding()
                }
                /*
                Gyroscope3DView(rotation: $activityHandler.rotation)
                    .frame(height: 100)
                    .padding()
                */
                VStack {
                    Chart {
                        ForEach(activityHandler.accelerationHistory) { dataPoint in
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
                    .chartYScale(domain: -2...2)
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
                
                Spacer()

                /*
                VStack {
                    
                    Map(position: $cameraPosition, interactionModes: [.pan, .zoom]) {
                        Marker("You", systemImage: "circle.circle", coordinate: CLLocationCoordinate2D(latitude: (locationHandler.siftLocation.coordinate.latitude), longitude: (locationHandler.siftLocation.coordinate.longitude)))
                    }
                    .onAppear {
                        updateCameraPosition()
                    }
                    .onChange(of: locationHandler.lastLocation) {
                        updateCameraPosition()
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    
                    Spacer()
                    HStack() {
                        Button("Zoom Out") {
                            self.mapSpan += mapSpanIncrement
                            updateCameraPosition()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                        Button("Zoom in") {
                            /// Ensure mapSpan does not go lower than mapSpanIncrement
                            if mapSpan > mapSpanIncrement {
                                mapSpan -= mapSpanIncrement
                            } else {
                                mapSpan = mapSpanMinimum
                            }
                            updateCameraPosition()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
                */
                
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
                            .foregroundColor(AppValues.pallet.primaryLight)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if activityHandler.isActivityMonitoringOn {
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
                            activityHandler.startMotionUpdates()
                        } else {
                            activityHandler.stopMotionUpdates()
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
                                .foregroundColor(AppValues.pallet.primaryLight)
                                .foregroundColor(Color.red)
                                .frame(width: 35, height: 35)
                            Text("record")
                                .foregroundColor(AppValues.pallet.primaryLight)
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Image("appLogoTransparent")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                        .foregroundColor(AppValues.pallet.primaryLight)
                }
            }
            
            /*
            .navigationBarItems(leading: Button(action: {
                isShowSideMenu.toggle()
            }) {
                Image(systemName: "square.leftthird.inset.filled")
                    .font(.system(size: 26, weight: .ultraLight))
                    .frame(width: 35, height:35)
                    .foregroundColor(AppValues.pallet.primaryLight)
                
            }, trailing: Button(action: {
                // Do stuff
                isRecording.toggle()
                if isRecording {
                    locationHandler.startLocationUpdates()
                } else {
                    locationHandler.stopLocationUpdates()
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
                        .foregroundColor(AppValues.pallet.primaryLight)
                        .foregroundColor(Color.red)
                        .frame(width: 35, height: 35)
                    Text("record")
                        .foregroundColor(AppValues.pallet.primaryLight)
                }
            })
            //.fullScreenCover(isPresented: $isShowHelp, content: {
            .sheet(isPresented: $isShowHelp, content: {
                // Content of the sheet
                HelpSheetView(isShowHelp: $isShowHelp)
            })
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("appLogoTransparent")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 38, height: 38)
                    .foregroundColor(AppValues.pallet.primaryLight)
                }
            }
            */
            
        }
        .onAppear() {
            isRecording = locationHandler.updatesStarted
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
