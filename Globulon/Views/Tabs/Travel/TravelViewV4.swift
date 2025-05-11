//
//  TravelViewV4.swift
//  Globulon
//
//  Created by David Holeman on 5/10/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

/// - note: This version attempts to have the cone fixed opening to the top of the screen and have the map orient \n
/// with the map changin in the direction of travel

import SwiftUI
import MapKit
import CoreLocation

struct TravelViewV4: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isShowSideMenu: Bool

    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var motionManager = MotionManager.shared

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraSpan: Double = 500
    private let cameraSpanMinimum: Double = 250
    private let cameraSpanIncrement: Double = 100
    
    @State var cameraPitch: Double = 0
    private let cameraPitch2D: Double = 0
    private let cameraPitch3D: Double = 60

    //TODO: Build_84
    @State private var lastYaw: Double = 0.0
    
    var body: some View {
        VStack {
            // Location Information Display
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
                HStack {
                    Text("Heading:")
                    Spacer()
                    Text("\(locationManager.userHeading ?? 0.0)°")
                }
                .padding(.bottom, -16)
            }
            .padding()

            Divider()

            ZStack {
                // Map View
                Map(position: $cameraPosition, interactionModes: [.all]) {
                    Annotation("You", coordinate: locationManager.lastLocation.coordinate) {
                        ZStack {
                            ConeView(heading: 0) // Always points to the top
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.3), .clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90)) // Align to top of the screen
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                }
                .onChange(of: locationManager.userLocation) {
                    updateCameraPosition()
                }
                .onChange(of: motionManager.attitudeData) {
                    let currentYaw = motionManager.yawDegrees
                    if abs(currentYaw - lastYaw) > 2 {
                        lastYaw = currentYaw
                        updateCameraPosition()
                    }
                }
                .onAppear {
                    updateCameraPosition()
                }

                // 2D/3D Control
                VStack {
                    HStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                cameraPitch = (cameraPitch == cameraPitch2D) ? cameraPitch3D : cameraPitch2D
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    updateCameraPosition()
                                }
                            }) {
                                Image(systemName: cameraPitch == cameraPitch2D ? "view.2d" : "view.3d")
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(colorScheme == .dark ? Color(UIColor.systemGray5) : Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                    }
                    .padding(.top, 64)
                    .padding(.trailing, 6)
                    
                    Spacer()
                }
                
                // Zoom Controls
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: {
                                self.cameraSpan = max(self.cameraSpan - cameraSpanIncrement, cameraSpanMinimum)
                                updateCameraPosition()
                            }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            Button(action: {
                                self.cameraSpan += cameraSpanIncrement
                                updateCameraPosition()
                            }) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .onAppear {
            // Request location permissions
            //CLLocationManager().requestWhenInUseAuthorization()
            locationManager.requestWhenInUseAuthorization()
            motionManager.startMotionUpdates()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            motionManager.stopMotionUpdates()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func updateCameraPosition() {
        guard let location = locationManager.userLocation else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: cameraSpan,
                    //heading: motionManager.yawDegrees, // Use smoothed yaw from CoreMotion
                    //TODO: Build_84
                    heading: locationManager.compassHeading,
                    pitch: cameraPitch
                )
            )
        }
    }
    
//    private func updateCameraPosition() {
//        guard let location = locationManager.userLocation else { return }
//        cameraPosition = .camera(
//            MapCamera(
//                centerCoordinate: location.coordinate,
//                distance: cameraSpan,
//                heading: locationManager.userHeading ?? 0.0, // Rotate map to match heading
//                pitch: cameraPitch
//            )
//        )
//    }

    private func formatMPH(_ speed: Double, decimalPoints: Int) -> String {
        String(format: "%.\(decimalPoints)f", speed)
    }

    private func convertMPStoMPH(_ speed: Double) -> Double {
        speed * 2.23694 // Convert m/s to mph
    }
}

#Preview {
    TravelViewV4(isShowSideMenu: .constant(false))
}
