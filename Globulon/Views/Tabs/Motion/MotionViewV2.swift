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
    @Environment(\.colorScheme) var colorScheme
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
            ScrollView {
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
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                    Spacer().frame(height: 16)
                    
                    
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
                    .padding(.bottom, 16)
                    
                    Divider()
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    
                    /// ATTITUDE
                    ///
                    VStack {
                        HStack {
                            PhoneOrientationView(quaternion: $deviceQuaternion, scale: 1.0)
                                .frame(width: 150, height: 150)
                                .border(Color.gray, width: 1)
                                .onReceive(motionManager.$attitudeData) { attitude in
                                    if let q = motionManager.deviceQuaternion {
                                        let qNoYaw = removeYaw(from: q, pitch: attitude.pitch, roll: attitude.roll)
                                        deviceQuaternion = qNoYaw
                                    }
                                }
                            Spacer().frame(width: 24)
                            GyroView(deviceQuaternion: $deviceQuaternion, scale: 1)
                                .frame(width: 150, height: 150)
                                .border(Color.gray, width: 1)
//                            GyroFixedView(rotation: $motionManager.gyroscopeRotation)
//                                .frame(width: 150, height: 150)
                            
                        }
                    }
                    .padding(.bottom, 16)
                    
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
    }
    
    func updateCameraPosition() {
        let location = CLLocationCoordinate2D(latitude: locationManager.lastLocation.coordinate.latitude,
                                              longitude: locationManager.lastLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: mapSpan, longitudeDelta: mapSpan))
        cameraPosition = .region(region)
    }
    
    private func removeYaw(from q: CMQuaternion, pitch: Double, roll: Double) -> CMQuaternion {
        let qPitch = simd_quatf(angle: Float(pitch), axis: simd_float3(1, 0, 0))
        let qRoll = simd_quatf(angle: Float(roll), axis: simd_float3(0, 1, 0))
        let combined = qPitch * qRoll
        return CMQuaternion(
            x: Double(combined.imag.x),
            y: Double(combined.imag.y),
            z: Double(combined.imag.z),
            w: Double(combined.real)
        )
    }
}


#Preview {
    MotionViewV2(isShowSideMenu: .constant(false))
}
