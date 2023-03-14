//
//  Camera.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/21/23.
//



import Foundation
import simd

class Camera {
    
    private(set) var projection = matrix_float4x4()
    
    var graphics: Graphics!
    var distance = Float(12.0)
    var rotationPrimary = Float(180.0)
    var rotationSecondary = Float(90.0)
    
    func load(graphics: Graphics) {
        self.graphics = graphics
    }
    
    func perspectiveMatrix() -> simd_float4x4 {
        let aspect = graphics.width / graphics.height
        var perspective = matrix_float4x4()
        perspective.perspective(fovy: Float.pi * 0.125, aspect: aspect, nearZ: 0.01, farZ: 255.0)
        return perspective
    }
    
    func unitEye() -> simd_float3 {
        var eye = simd_float3(0.0, 1.0, 0.0)
        eye = Math.rotateX(float3: eye, degrees: rotationSecondary)
        eye = Math.rotateY(float3: eye, degrees: rotationPrimary)
        return eye
    }

    func compute(perspective: simd_float4x4, unitEye: simd_float3) {
        let eye = unitEye * distance
        var lookAt = matrix_float4x4()
        lookAt.lookAt(eyeX: eye.x, eyeY: eye.y, eyeZ: eye.z,
                      centerX: 0.0, centerY: 0.0, centerZ: 0.0,
                      upX: 0.0, upY: 1.0, upZ: 0.0)
        projection = simd_mul(perspective, lookAt)
    }
    
    func compute() {
        let perspective = perspectiveMatrix()
        let unitEye = unitEye()
        compute(perspective: perspective, unitEye: unitEye)
    }
    
    func convert(float3: simd_float3) -> simd_float2 {
        let point = projection.process(point3: float3)
        let x = graphics.width * (point.x + 1.0) * 0.5
        let y = graphics.height * (1.0 - (point.y + 1.0) * 0.5)
        return simd_float2(x, y)
    }
    
}
