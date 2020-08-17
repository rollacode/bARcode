//
//  Math+Extentions.swift
//  bARcode
//
//  Created by rollacode on 11.08.2020.
//  Copyright © 2020 test. All rights reserved.
//

import Foundation
import SceneKit

public extension simd_float4x4
{
    func matrix() -> SCNMatrix4 {
        return SCNMatrix4.init(self)
    }
}

public extension SCNMatrix4
{
    var forwardVector: SCNVector3 { SCNVector3(m31, m32, m33).normalized() }
    var backVector: SCNVector3 { forwardVector.negate() }
    var position: SCNVector3 { SCNVector3(m41, m42, m43) }
}

public extension SCNVector3
{
    /**
    * Negates the vector described by SCNVector3 and returns
    * the result as a new SCNVector3.
    */
    func negate() -> SCNVector3 {
        return self * -1
    }

    /**
    * Returns the length (magnitude) of the vector described by the SCNVector3
    */
    func magnitude() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }

    /**
    * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
    * the result as a new SCNVector3.
    */
    func normalized() -> SCNVector3 {
        return self / magnitude()
    }

    /**
    * Calculates the distance between two SCNVector3. Pythagoras!
    */
    func distance(_ vector: SCNVector3) -> Float {
        return (self - vector).magnitude()
    }

    /**
    * Calculates the dot product between two SCNVector3.
    */
    func dot(_ vector: SCNVector3) -> Float {
        
        return x * vector.x + y * vector.y + z * vector.z
    }

    /**
    * Calculates the cross product between two SCNVector3.
    */
    func cross(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }
    
    /**
    * Calculates the angle between 2 vectors in rad. Cos(tetta)
    */
    func angle(_ vector: SCNVector3) -> Float {
        return cos(dot(vector) / (vector.magnitude() * magnitude()))
    }

}

/**
* Adds two SCNVector3 vectors and returns the result as a new SCNVector3.
*/
public func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

/**
* Increments a SCNVector3 with the value of another.
*/
public func += ( left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

/**
* Subtracts two SCNVector3 vectors and returns the result as a new SCNVector3.
*/
public func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

/**
* Decrements a SCNVector3 with the value of another.
*/
public func -= ( left: inout SCNVector3, right: SCNVector3) {
    left = left - right
}

/**
* Multiplies two SCNVector3 vectors and returns the result as a new SCNVector3.
*/
public func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
}

/**
* Multiplies a SCNVector3 with another.
*/
public func *= ( left: inout SCNVector3, right: SCNVector3) {
    left = left * right
}

/**
* Multiplies the x, y and z fields of a SCNVector3 with the same scalar value and
* returns the result as a new SCNVector3.
*/
public func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}

/**
* Multiplies the x and y fields of a SCNVector3 with the same scalar value.
*/
public func *= ( vector: inout SCNVector3, scalar: Float) {
    vector = vector * scalar
}

/**
* Divides two SCNVector3 vectors abd returns the result as a new SCNVector3
*/
public func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
}

/**
* Divides a SCNVector3 by another.
*/
public func /= ( left: inout SCNVector3, right: SCNVector3) {
    left = left / right
}

/**
* Divides the x, y and z fields of a SCNVector3 by the same scalar value and
* returns the result as a new SCNVector3.
*/
public func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
}

/**
* Divides the x, y and z of a SCNVector3 by the same scalar value.
*/
public func /= ( vector: inout SCNVector3, scalar: Float) {
    vector = vector / scalar
}

/**
* Negate a vector
*/
public func SCNVector3Negate(vector: SCNVector3) -> SCNVector3 {
    return vector * -1
}

/**
* Returns the length (magnitude) of the vector described by the SCNVector3
*/
public func SCNVector3Length(vector: SCNVector3) -> Float
{
    return sqrtf(vector.x*vector.x + vector.y*vector.y + vector.z*vector.z)
}

/**
* Returns the distance between two SCNVector3 vectors
*/
public func SCNVector3Distance(vectorStart: SCNVector3, vectorEnd: SCNVector3) -> Float {
    return SCNVector3Length(vector: vectorEnd - vectorStart)
}

/**
* Returns the distance between two SCNVector3 vectors
*/
public func SCNVector3Normalize(vector: SCNVector3) -> SCNVector3 {
    return vector / SCNVector3Length(vector: vector)
}

/**
* Calculates the dot product between two SCNVector3 vectors
*/
public func SCNVector3DotProduct(left: SCNVector3, right: SCNVector3) -> Float {
    return left.x * right.x + left.y * right.y + left.z * right.z
}

/**
* Calculates the cross product between two SCNVector3 vectors
*/
public func SCNVector3CrossProduct(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.y * right.z - left.z * right.y, left.z * right.x - left.x * right.z, left.x * right.y - left.y * right.x)
}

/**
* Calculates the SCNVector from lerping between two SCNVector3 vectors
*/
public func SCNVector3Lerp(vectorStart: SCNVector3, vectorEnd: SCNVector3, t: Float) -> SCNVector3 {
    return SCNVector3Make(vectorStart.x + ((vectorEnd.x - vectorStart.x) * t), vectorStart.y + ((vectorEnd.y - vectorStart.y) * t), vectorStart.z + ((vectorEnd.z - vectorStart.z) * t))
}

/**
* Project the vector, vectorToProject, onto the vector, projectionVector.
*/
public func SCNVector3Project(vectorToProject: SCNVector3, projectionVector: SCNVector3) -> SCNVector3 {
    let scale: Float = SCNVector3DotProduct(left: projectionVector, right: vectorToProject) / SCNVector3DotProduct(left: projectionVector, right: projectionVector)
    let v: SCNVector3 = projectionVector * scale
    return v
}

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
    */
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return [translation.x, translation.y, translation.z]
        }
        set(newValue) {
            columns.3 = [newValue.x, newValue.y, newValue.z, columns.3.w]
        }
    }
    
    /**
     Factors out the orientation component of the transform.
    */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }
    
    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}
