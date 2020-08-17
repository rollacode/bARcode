//
//  Plane.swift
//  bARcode
//
//  Created by rollacode on 11.08.2020.
//  Copyright © 2020 test. All rights reserved.
//

import ARKit

// Convenience extension for colors defined in asset catalog.
extension UIColor {
    static let planeColor = UIColor(named: "barcodeColor")!
    static let planeColorRead = UIColor(named: "barcodeColorRead")!
}

struct CollisionCategory: OptionSet {
    let rawValue: Int

    static let bullets  = CollisionCategory(rawValue: 1 << 0)
    static let codes = CollisionCategory(rawValue: 1 << 1)
}

class BarCodePlane: SCNNode {
    
    var isRead = false
    var payload: String
    private var recentPositions: [SIMD3<Float>] = []
    private var recentRotations: [simd_quatf] = []
        
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    init(payload: String) {
        self.payload = payload
        super.init()
        let meshNode = SCNPlane(width: 0.05, height: 0.05)
        self.geometry = meshNode
        self.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.static, shape: SCNPhysicsShape.init(geometry: meshNode, options: [:]))
        self.physicsBody?.categoryBitMask = CollisionCategory.codes.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.bullets.rawValue
        self.unread()
    }
    
    func setPosition(with raycastResult: ARRaycastResult) {
        let position = raycastResult.worldTransform.translation
        recentPositions.append(position)
        updateTransform(for: raycastResult)
    }
    
    func updateOrientation(basedOn raycastResult: ARRaycastResult) {
        let orientation = raycastResult.worldTransform.orientation
        recentRotations.append(orientation)
        recentRotations = Array(recentRotations.suffix(10))
        
        var average = recentRotations[0]
        var weight = Float(0.0);
        for i in 1..<recentRotations.count {
            weight = 1.0 / Float(i+1)
            average = simd_slerp(average, recentRotations[i], weight)
        }
        
        self.simdWorldOrientation = average
        // add rotation by -90 deg by x, because of default pivot point of SCNPlane mesh
        // research another way to change default pivot rotation for SCNNode
        self.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: SIMD3(x: 1, y: 0, z: 0)))
    }

    private func updateTransform(for raycastResult: ARRaycastResult) {
        // Average using several most recent positions.
        recentPositions = Array(recentPositions.suffix(10))
        
        // Move to average of recent positions to avoid jitter.
        let average = recentPositions.reduce([0, 0, 0], { $0 + $1 }) / Float(recentPositions.count)
        self.simdPosition = average
    }
    
    ///Mark current barcode plane as read
    func read() {
       guard let material = self.geometry?.firstMaterial
            else { fatalError("ARSCNPlaneGeometry always has one material") }
        self.opacity = 0.4
        material.diffuse.contents = UIColor.planeColorRead
        self.isRead = true
    }
    
    ///Mark current barcode plane as unread
    func unread() {
        guard let material = self.geometry?.firstMaterial
            else { fatalError("ARSCNPlaneGeometry always has one material") }
        self.opacity = 0.6
        material.diffuse.contents = UIColor.planeColor
        self.isRead = false
    }
}

class ARBullet: SCNNode {
    
    override init() {
        super.init()

        let arKitBox = SCNSphere(radius: 0.0095)
        self.geometry = arKitBox
        let shape = SCNPhysicsShape(geometry: arKitBox, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody?.isAffectedByGravity = false
        // Bullets will affect only barcode planes
        self.physicsBody?.categoryBitMask = CollisionCategory.bullets.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.codes.rawValue
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
