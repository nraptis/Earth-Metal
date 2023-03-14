//
//  CameraCalibrationTool.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/22/23.
//

import Foundation
import simd
import UIKit

struct CameraCalibrationTool {
    
    private static let epsilon = Float(0.01)
    
    private static let tileCountV = 24
    private static let tileCountH = 24
    
    static func earthRestingRadius(graphics: Graphics) -> Float {
        let dimension = min(graphics.width, graphics.height)
        let ratio: Float = (dimension < 340.0) ? 0.95 : 0.78
        let maxRadius: Float = 425.0
        var result = dimension * 0.5 * ratio
        if result > maxRadius {
            result = maxRadius
        }
        return result
    }
    
    static func starsRestingRadius(graphics: Graphics) -> Float {
        let diffX = graphics.width * 0.6
        let diffY = graphics.height * 0.6
        var length = diffX * diffX + diffY * diffY
        if length > Math.epsilon {
            length = sqrtf(length)
        }
        return length
    }
    
    static let screenMinDimensionRatio: Float = (min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) < 340.0) ? 0.95 : 0.78
    static let screenMinDimensionMaxSize: Float = 425.0
    
    let sphere = UnitPointSphere()
    
    init() {
        sphere.load(tileCountH: Self.tileCountH, tileCountV: Self.tileCountV)
    }
    
    func calibrate(graphics: Graphics, camera: Camera, radius: Float) -> Float {
        
        let center = simd_float2(graphics.width * 0.5, graphics.height * 0.5)
        let perspective = camera.perspectiveMatrix()
        let unitEye = camera.unitEye()
        
        var minDist: Float = 1.25
        var minRadius: Float = self.estimateRadius(graphics: graphics,
                                                   camera: camera,
                                                   sphere: sphere,
                                                   center: center,
                                                   perspective: perspective,
                                                   unitEye: unitEye,
                                                   distance: minDist)
        
        var maxDist: Float = minDist
        var maxRadius: Float = minRadius
        
        // Keep doubling until the radius produced from the maxDist
        // exceeds the targetRadius
        var fudge = 0
        repeat {
            fudge += 1
            minDist = maxDist
            minRadius = maxRadius
            maxDist *= 2.0
            maxRadius = estimateRadius(graphics: graphics,
                                       camera: camera,
                                       sphere: sphere,
                                       center: center,
                                       perspective: perspective,
                                       unitEye: unitEye,
                                       distance: maxDist)
        } while (fudge < 100) && (maxRadius > radius)
        
        // Use binary search to pinch min and max dist towards
        // such that their radius is close enough to targetRadius
        fudge = 0
        repeat {
            fudge += 1
            let midDist = (minDist + maxDist) * 0.5
            let midRadius = estimateRadius(graphics: graphics,
                                           camera: camera,
                                           sphere: sphere,
                                           center: center,
                                           perspective: perspective,
                                           unitEye: unitEye,
                                           distance: midDist)
            if midRadius < radius {
                maxRadius = midRadius
                maxDist = midDist
            } else {
                minRadius = midRadius
                minDist = midDist
            }
        } while (fudge < 100) && (abs(maxRadius - radius) > Self.epsilon)
        
        return maxDist
    }
    
    func estimateRadius(graphics: Graphics, camera: Camera) -> Float {
        let center = simd_float2(graphics.width * 0.5, graphics.height * 0.5)
        let perspective = camera.perspectiveMatrix()
        let unitEye = camera.unitEye()
        let radius = estimateRadius(graphics: graphics,
                                    camera: camera,
                                    sphere: sphere,
                                    center: center,
                                    perspective: perspective,
                                    unitEye: unitEye,
                                    distance: camera.distance)
        return radius
    }
    
    private func estimateRadius(graphics: Graphics,
                                camera: Camera,
                                sphere: UnitPointSphere,
                                center: simd_float2,
                                perspective: matrix_float4x4,
                                unitEye: simd_float3,
                                distance: Float) -> Float {
        
        let holdDistance = camera.distance
        
        camera.distance = distance
        camera.compute(perspective: perspective, unitEye: unitEye)
        
        var result: Float = 0.0
        var indexV = 0
        while indexV < Self.tileCountV {
            var indexH = 0
            while indexH < Self.tileCountH {
                let point3D = sphere.points[indexH][indexV]
                let point2D = camera.convert(float3: point3D)
                let diffX = point2D.x - center.x
                let diffY = point2D.y - center.y
                let length = diffX * diffX + diffY * diffY
                if length > result {
                    result = length
                }
                indexH += 1
            }
            indexV += 1
        }
        if result > Math.epsilon {
            result = sqrtf(result)
        }
        
        camera.distance = holdDistance
        
        return result
    }
}
