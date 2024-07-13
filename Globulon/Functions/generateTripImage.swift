//
//  generateTripImage.swift
//  ViDrive
//
//  Created by David Holeman on 7/11/24.
//  Copyright © 2024 OpEx Networks, LLC. All rights reserved.
//

import UIKit
import MapKit

/// Generate a map image of the trip
/// - Parameters:
///   - region: bounds of the trip north and south based on min and max latitudes and min and max longitudes
///   - trip: Data structure holding the trip data
///   - size: Size of the image to generate
/// - Returns: The map image or nil
///
///

import UIKit
import MapKit

/// Generate a map image of the trip
/// - Parameters:
///   - region: bounds of the trip north and south based on min and max latitudes and min and max longitudes
///   - trip: Data structure holding the trip data
///   - size: Size of the image to generate
/// - Returns: The map image or nil
///
///

func generateTripImage(region: MKCoordinateRegion, trip: TripSummariesSD, size: CGSize) -> UIImage? {
    let options = MKMapSnapshotter.Options()
    options.region = region
    options.size = size
    options.scale = UIScreen.main.scale

    // Force light mode for the snapshotter
    if #available(iOS 12.0, *) {
        options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
    }

    let snapshotter = MKMapSnapshotter(options: options)
    var finalImage: UIImage?
    let semaphore = DispatchSemaphore(value: 0)

    snapshotter.start { snapshot, error in
        defer {
            semaphore.signal()
        }
        guard let snapshot = snapshot, error == nil else {
            print("Snapshot error: \(String(describing: error))")
            return
        }

        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        snapshot.image.draw(at: .zero)

        guard let context = UIGraphicsGetCurrentContext() else {
            print("Failed to get graphics context")
            return
        }

        // Draw start marker
        let startPoint = snapshot.point(for: CLLocationCoordinate2D(latitude: trip.originationLatitude, longitude: trip.originationLongitude))
        let startMarker = UIImage(systemName: "circle.fill")?.withTintColor(.green, renderingMode: .alwaysOriginal)
        startMarker?.draw(at: CGPoint(x: startPoint.x - (startMarker?.size.width ?? 0) / 2, y: startPoint.y - (startMarker?.size.height ?? 0) / 2))

        // Draw start label
        let startLabel = "start"
        let startLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),  // Smaller font size
            .foregroundColor: UIColor.black
        ]
        let startLabelSize = startLabel.size(withAttributes: startLabelAttributes)
        startLabel.draw(at: CGPoint(x: startPoint.x - startLabelSize.width / 2, y: startPoint.y + 10), withAttributes: startLabelAttributes)

        // Draw end marker
        let endPoint = snapshot.point(for: CLLocationCoordinate2D(latitude: trip.destinationLatitude, longitude: trip.destinationLongitude))
        let endMarker = UIImage(systemName: "star.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        endMarker?.draw(at: CGPoint(x: endPoint.x - (endMarker?.size.width ?? 0) / 2, y: endPoint.y - (endMarker?.size.height ?? 0) / 2))

        // Draw end label
        let endLabel = "end"
        let endLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),  // Smaller font size
            .foregroundColor: UIColor.black
        ]
        let endLabelSize = endLabel.size(withAttributes: endLabelAttributes)
        endLabel.draw(at: CGPoint(x: endPoint.x - endLabelSize.width / 2, y: endPoint.y + 10), withAttributes: endLabelAttributes)

        // Draw polyline
        let path = UIBezierPath()
        let points = trip.sortedCoordinates.map { snapshot.point(for: $0) }

        if let firstPoint = points.first {
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }

        // Set the line width and color for the context
        context.setLineWidth(5.0)
        context.setStrokeColor(UIColor.blue.cgColor)

        // Stroke the path in the context
        context.addPath(path.cgPath)
        context.strokePath()

        finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    semaphore.wait()
    return finalImage
}

func generateTripImageV2(region: MKCoordinateRegion, trip: TripSummariesSD, size: CGSize) -> UIImage? {
    let options = MKMapSnapshotter.Options()
    options.region = region
    options.size = size
    options.scale = UIScreen.main.scale

    let snapshotter = MKMapSnapshotter(options: options)
    var finalImage: UIImage?
    let semaphore = DispatchSemaphore(value: 0)

    snapshotter.start { snapshot, error in
        defer {
            semaphore.signal()
        }
        guard let snapshot = snapshot, error == nil else {
            print("Snapshot error: \(String(describing: error))")
            return
        }

        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        snapshot.image.draw(at: .zero)

        guard let context = UIGraphicsGetCurrentContext() else {
            print("Failed to get graphics context")
            return
        }

        // Draw start marker
        let startPoint = snapshot.point(for: CLLocationCoordinate2D(latitude: trip.originationLatitude, longitude: trip.originationLongitude))
        let startMarker = UIImage(systemName: "circle.fill")?.withTintColor(.green, renderingMode: .alwaysOriginal)
        startMarker?.draw(at: CGPoint(x: startPoint.x - (startMarker?.size.width ?? 0) / 2, y: startPoint.y - (startMarker?.size.height ?? 0) / 2))

        // Draw start label
        let startLabel = "start"
        let startLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),  // Smaller font size
            .foregroundColor: UIColor.black
        ]
        let startLabelSize = startLabel.size(withAttributes: startLabelAttributes)
        startLabel.draw(at: CGPoint(x: startPoint.x - startLabelSize.width / 2, y: startPoint.y + 10), withAttributes: startLabelAttributes)

        // Draw end marker
        let endPoint = snapshot.point(for: CLLocationCoordinate2D(latitude: trip.destinationLatitude, longitude: trip.destinationLongitude))
        let endMarker = UIImage(systemName: "star.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        endMarker?.draw(at: CGPoint(x: endPoint.x - (endMarker?.size.width ?? 0) / 2, y: endPoint.y - (endMarker?.size.height ?? 0) / 2))

        // Draw end label
        let endLabel = "end"
        let endLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),  // Smaller font size
            .foregroundColor: UIColor.black
        ]
        let endLabelSize = endLabel.size(withAttributes: endLabelAttributes)
        endLabel.draw(at: CGPoint(x: endPoint.x - endLabelSize.width / 2, y: endPoint.y + 10), withAttributes: endLabelAttributes)

        // Draw polyline
        let path = UIBezierPath()
        let points = trip.sortedCoordinates.map { snapshot.point(for: $0) }

        if let firstPoint = points.first {
            path.move(to: firstPoint)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }

        // Set the line width and color for the context
        context.setLineWidth(3.0)
        context.setStrokeColor(UIColor.blue.cgColor)

        // Stroke the path in the context
        context.addPath(path.cgPath)
        context.strokePath()

        finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    semaphore.wait()
    return finalImage
}


func generateTripImageV1(region: MKCoordinateRegion, trip: TripSummariesSD, size: CGSize) -> UIImage? {
    let options = MKMapSnapshotter.Options()
    options.region = region
    options.size = size
    options.scale = UIScreen.main.scale

    let snapshotter = MKMapSnapshotter(options: options)
    var finalImage: UIImage?
    let semaphore = DispatchSemaphore(value: 0)

    snapshotter.start { snapshot, error in
        defer {
            semaphore.signal()
        }
        guard let snapshot = snapshot, error == nil else {
            print("Snapshot error: \(String(describing: error))")
            return
        }

        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        snapshot.image.draw(at: .zero)
        
        let context = UIGraphicsGetCurrentContext()
        
        // Draw start marker
        let startPoint = snapshot.point(for: CLLocationCoordinate2D(latitude: trip.originationLatitude, longitude: trip.originationLongitude))
        let startMarker = UIImage(systemName: "circle.fill")?.withTintColor(.green, renderingMode: .alwaysOriginal)
        startMarker?.draw(at: CGPoint(x: startPoint.x - (startMarker?.size.width ?? 0) / 2, y: startPoint.y - (startMarker?.size.height ?? 0) / 2))
        
        // Draw start label
        let startLabel = "start"
        let startLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),  // Smaller font size
            .foregroundColor: UIColor.black
        ]
        let startLabelSize = startLabel.size(withAttributes: startLabelAttributes)
        startLabel.draw(at: CGPoint(x: startPoint.x - startLabelSize.width / 2, y: startPoint.y + 10), withAttributes: startLabelAttributes)

        // Draw end marker
        let endPoint = snapshot.point(for: CLLocationCoordinate2D(latitude: trip.destinationLatitude, longitude: trip.destinationLongitude))
        let endMarker = UIImage(systemName: "star.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        endMarker?.draw(at: CGPoint(x: endPoint.x - (endMarker?.size.width ?? 0) / 2, y: endPoint.y - (endMarker?.size.height ?? 0) / 2))
        
        // Draw end label
        let endLabel = "end"
        let endLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),  // Smaller font size
            .foregroundColor: UIColor.black
        ]
        let endLabelSize = endLabel.size(withAttributes: endLabelAttributes)
        endLabel.draw(at: CGPoint(x: endPoint.x - endLabelSize.width / 2, y: endPoint.y + 10), withAttributes: endLabelAttributes)
        
        // Draw polyline
        let path = UIBezierPath()
        var points = trip.sortedCoordinates.map { snapshot.point(for: $0) }
        guard let firstPoint = points.first else {
            UIGraphicsEndImageContext()
            return
        }
        path.move(to: firstPoint)
        points.removeFirst()
        points.forEach { path.addLine(to: $0) }
        
        context?.setStrokeColor(UIColor.blue.cgColor)
        context?.setLineWidth(5.0)
        path.stroke()

        finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    semaphore.wait()
    return finalImage
}
