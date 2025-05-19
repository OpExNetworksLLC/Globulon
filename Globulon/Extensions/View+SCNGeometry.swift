//
//  View+SCNGeometry.swift
//  Globulon
//
//  Created by David Holeman on 5/19/25.
//  Copyright © 2025 OpEx Networks, LLC. All rights reserved.
//

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
