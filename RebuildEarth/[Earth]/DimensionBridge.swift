//
//  DimensionBridge.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/22/23.
//

import Foundation
import simd
import Metal

class DimensionBridge {
    
    static let tileCountV = 16
    static let tileCountH = 16
    
    var camera: Camera!
    var graphics: Graphics!
    
    var _point: simd_float2 = simd_float2(256.0, 250.0)
    
    var selectedFaceH: Int?
    var selectedFaceV: Int?
    
    var _closestPoint1: simd_float2?
    var _closestPoint2: simd_float2?
    var _closestPoint3: simd_float2?
    var _closestPoint4: simd_float2?
    
    var _lerp1: simd_float3?
    var _lerp2: simd_float3?
    var _lerp3: simd_float3?
    var _lerp4: simd_float3?
    
    var _axis: simd_float3?
    
    private(set) var points2D = [[simd_float2]]()
    
    let sphere = UnitPointSphere()
    
    init() {
        
    }
    
    func load(graphics: Graphics, camera: Camera) {
        self.graphics = graphics
        self.camera = camera
        
        points2D = [[simd_float2]](repeating: [simd_float2](), count: Self.tileCountH)
        for x in 0..<Self.tileCountH {
            points2D[x].reserveCapacity(Self.tileCountV)
            for _ in 0..<Self.tileCountV {
                points2D[x].append(simd_float2(0.0, 0.0))
            }
        }
        sphere.load(tileCountH: Self.tileCountH - 1, tileCountV: Self.tileCountV - 1,
                    startRotationH: -(Float.pi * 0.5), endRotationH: Float.pi * 0.5,
                    startRotationV: Float.pi, endRotationV: Float.pi * 2.0)
        
        refresh()
    }
    
    func refresh() {
        var indexV = 0
        while indexV < Self.tileCountV {
            var indexH = 0
            while indexH < Self.tileCountH {
                let point = sphere.points[indexH][indexV]
                points2D[indexH][indexV] = camera.convert(float3: point)
                indexH += 1
            }
            indexV += 1
        }
    }
    
    func convert(point: simd_float2) -> simd_float3? {
        
        _point = point
        
        selectedFaceH = nil
        selectedFaceV = nil
        
        _closestPoint1 = nil
        _closestPoint2 = nil
        _closestPoint3 = nil
        _closestPoint4 = nil
        
        var prevIndexV = 0
        var indexV = 1
        var selectedZ: Float = 2048.0

        while indexV < Self.tileCountV {
            var prevIndexH = 0
            var indexH = 1
            while indexH < Self.tileCountH {
                
                let quadX1 = points2D[prevIndexH][prevIndexV].x
                let quadY1 = points2D[prevIndexH][prevIndexV].y
                
                let quadX2 = points2D[indexH][prevIndexV].x
                let quadY2 = points2D[indexH][prevIndexV].y
                
                let quadX3 = points2D[indexH][indexV].x
                let quadY3 = points2D[indexH][indexV].y
                
                let quadX4 = points2D[prevIndexH][indexV].x
                let quadY4 = points2D[prevIndexH][indexV].y
                
                if Math.quadBoundingBoxContainsPoint2D(x: point.x, y: point.y,
                                                       quadX1: quadX1, quadY1: quadY1, quadX2: quadX2, quadY2: quadY2,
                                                       quadX3: quadX3, quadY3: quadY3, quadX4: quadX4, quadY4: quadY4) {
                
                    if Math.quadContainsPoint2D(x: point.x, y: point.y,
                                                quadX1: quadX1, quadY1: quadY1, quadX2: quadX2, quadY2: quadY2,
                                                quadX3: quadX3, quadY3: quadY3, quadX4: quadX4, quadY4: quadY4) {
                        
                        let z1 = sphere.points[prevIndexH][prevIndexV].z
                        let z2 = sphere.points[indexH][prevIndexV].z
                        let z3 = sphere.points[prevIndexH][indexV].z
                        let z4 = sphere.points[indexH][indexV].z
                        
                        var z = z1
                        if z2 < z { z = z2 }
                        if z3 < z { z = z3 }
                        if z4 < z { z = z4 }
                        
                        if z < selectedZ {
                            selectedZ = z
                            selectedFaceV = prevIndexV
                            selectedFaceH = prevIndexH
                        }
                    }
                }
                prevIndexH = indexH
                indexH += 1
            }
            prevIndexV = indexV
            indexV += 1
        }
     
        
        guard let selectedFaceH = selectedFaceH else { return nil }
        guard let selectedFaceV = selectedFaceV else { return nil }


        let quadX1 = points2D[selectedFaceH][selectedFaceV].x
        let quadY1 = points2D[selectedFaceH][selectedFaceV].y

        let quadX2 = points2D[selectedFaceH + 1][selectedFaceV].x
        let quadY2 = points2D[selectedFaceH + 1][selectedFaceV].y

        let quadX3 = points2D[selectedFaceH][selectedFaceV + 1].x
        let quadY3 = points2D[selectedFaceH][selectedFaceV + 1].y

        let quadX4 = points2D[selectedFaceH + 1][selectedFaceV + 1].x
        let quadY4 = points2D[selectedFaceH + 1][selectedFaceV + 1].y

        let closestPoint1 = Math.segmentClosestPoint(point: point,
                                                     lineStart: simd_float2(quadX1, quadY1),
                                                     lineEnd: simd_float2(quadX2, quadY2))
        let closestPoint2 = Math.segmentClosestPoint(point: point,
                                                     lineStart: simd_float2(quadX2, quadY2),
                                                     lineEnd: simd_float2(quadX4, quadY4))
        let closestPoint3 = Math.segmentClosestPoint(point: point,
                                                     lineStart: simd_float2(quadX4, quadY4),
                                                     lineEnd: simd_float2(quadX3, quadY3))
        let closestPoint4 = Math.segmentClosestPoint(point: point,
                                                     lineStart: simd_float2(quadX3, quadY3),
                                                     lineEnd: simd_float2(quadX1, quadY1))

        _closestPoint1 = closestPoint1
        _closestPoint2 = closestPoint2
        _closestPoint3 = closestPoint3
        _closestPoint4 = closestPoint4
        
        let selectedAxis1 = simd_float3(sphere.points[selectedFaceH][selectedFaceV].x,
                                        sphere.points[selectedFaceH][selectedFaceV].y,
                                        sphere.points[selectedFaceH][selectedFaceV].z)

        let selectedAxis2 = simd_float3(sphere.points[selectedFaceH + 1][selectedFaceV].x,
                                        sphere.points[selectedFaceH + 1][selectedFaceV].y,
                                        sphere.points[selectedFaceH + 1][selectedFaceV].z)

        let selectedAxis3 = simd_float3(sphere.points[selectedFaceH][selectedFaceV + 1].x,
                                        sphere.points[selectedFaceH][selectedFaceV + 1].y,
                                        sphere.points[selectedFaceH][selectedFaceV + 1].z)

        let selectedAxis4 = simd_float3(sphere.points[selectedFaceH + 1][selectedFaceV + 1].x,
                                        sphere.points[selectedFaceH + 1][selectedFaceV + 1].y,
                                        sphere.points[selectedFaceH + 1][selectedFaceV + 1].z)


        let distanceToClosestPoint1 = Math.distance(point1: point, point2: closestPoint1)
        let distanceToClosestPoint2 = Math.distance(point1: point, point2: closestPoint2)
        let distanceToClosestPoint3 = Math.distance(point1: point, point2: closestPoint3)
        let distanceToClosestPoint4 = Math.distance(point1: point, point2: closestPoint4)

        let totalDistance = distanceToClosestPoint1 + distanceToClosestPoint2 + distanceToClosestPoint3 + distanceToClosestPoint4
        if totalDistance < Math.epsilon { return nil }



        var lerp1 = selectedAxis1
        var lerp2 = selectedAxis2
        var lerp3 = selectedAxis4
        var lerp4 = selectedAxis3

        var distA: Float = 0.0
        var distB: Float = 0.0
        var distC: Float = 0.0

        distA = Math.distance(point1: closestPoint1, point2: simd_float2(quadX1, quadY1))
        distB = Math.distance(point1: closestPoint1, point2: simd_float2(quadX2, quadY2))
        distC = distA + distB
        if distC > Math.epsilon {
            let percent = distA / distC
            let percentInverse = (1.0 - percent)
            lerp1 = simd_float3(selectedAxis1.x * percentInverse + selectedAxis2.x * percent,
                                selectedAxis1.y * percentInverse + selectedAxis2.y * percent,
                                selectedAxis1.z * percentInverse + selectedAxis2.z * percent)
        }


        distA = Math.distance(point1: closestPoint2, point2: simd_float2(quadX2, quadY2))
        distB = Math.distance(point1: closestPoint2, point2: simd_float2(quadX4, quadY4))
        distC = distA + distB
        if distC > Math.epsilon {
            let percent = distA / distC
            let percentInverse = (1.0 - percent)
            lerp2 = simd_float3(selectedAxis2.x * percentInverse + selectedAxis4.x * percent,
                                selectedAxis2.y * percentInverse + selectedAxis4.y * percent,
                                selectedAxis2.z * percentInverse + selectedAxis4.z * percent)
        }

        distA = Math.distance(point1: closestPoint3, point2: simd_float2(quadX4, quadY4))
        distB = Math.distance(point1: closestPoint3, point2: simd_float2(quadX3, quadY3))
        distC = distA + distB
        if distC > Math.epsilon {
            let percent = distA / distC
            let percentInverse = (1.0 - percent)
            lerp3 = simd_float3(selectedAxis4.x * percentInverse + selectedAxis3.x * percent,
                                selectedAxis4.y * percentInverse + selectedAxis3.y * percent,
                                selectedAxis4.z * percentInverse + selectedAxis3.z * percent)
        }

        distA = Math.distance(point1: closestPoint4, point2: simd_float2(quadX3, quadY3))
        distB = Math.distance(point1: closestPoint4, point2: simd_float2(quadX1, quadY1))
        distC = distA + distB
        if distC > Math.epsilon {
            let percent = distA / distC
            let percentInverse = (1.0 - percent)
            lerp4 = simd_float3(selectedAxis3.x * percentInverse + selectedAxis1.x * percent,
                                selectedAxis3.y * percentInverse + selectedAxis1.y * percent,
                                selectedAxis3.z * percentInverse + selectedAxis1.z * percent)
        }

        _lerp1 = lerp1
        _lerp2 = lerp2
        _lerp3 = lerp3
        _lerp4 = lerp4
        
        let weight1 = (distanceToClosestPoint2 * distanceToClosestPoint3 * distanceToClosestPoint4) /
        (distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint3 +
         distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint4 +
         distanceToClosestPoint1 * distanceToClosestPoint3 * distanceToClosestPoint4 +
         distanceToClosestPoint2 * distanceToClosestPoint3 * distanceToClosestPoint4)
            
        let weight2 = (distanceToClosestPoint1 * distanceToClosestPoint3 * distanceToClosestPoint4) /
        (distanceToClosestPoint2 * distanceToClosestPoint1 * distanceToClosestPoint3 +
         distanceToClosestPoint2 * distanceToClosestPoint1 * distanceToClosestPoint4 +
         distanceToClosestPoint2 * distanceToClosestPoint3 * distanceToClosestPoint4 +
         distanceToClosestPoint1 * distanceToClosestPoint3 * distanceToClosestPoint4)
            
        let weight3 = (distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint4) /
        (distanceToClosestPoint3 * distanceToClosestPoint1 * distanceToClosestPoint2 +
         distanceToClosestPoint3 * distanceToClosestPoint1 * distanceToClosestPoint4 +
         distanceToClosestPoint3 * distanceToClosestPoint2 * distanceToClosestPoint4 +
         distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint4)
            
        let weight4 = (distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint3) /
        (distanceToClosestPoint4 * distanceToClosestPoint1 * distanceToClosestPoint2 +
         distanceToClosestPoint4 * distanceToClosestPoint1 * distanceToClosestPoint3 +
         distanceToClosestPoint4 * distanceToClosestPoint2 * distanceToClosestPoint3 +
         distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint3)

        var axisX = lerp1.x * weight1 + lerp2.x * weight2 + lerp3.x * weight3 + lerp4.x * weight4
        var axisY = lerp1.y * weight1 + lerp2.y * weight2 + lerp3.y * weight3 + lerp4.y * weight4
        var axisZ = lerp1.z * weight1 + lerp2.z * weight2 + lerp3.z * weight3 + lerp4.z * weight4

        var axisLength = axisX * axisX + axisY * axisY + axisZ * axisZ
        guard axisLength > Math.epsilon else { return nil }

        axisLength = sqrtf(axisLength)
        axisX /= axisLength
        axisY /= axisLength
        axisZ /= axisLength

        _axis = simd_float3(axisX, axisY, axisZ)

        return simd_float3(axisX, axisY, axisZ)
    }
    
    func drawQuads2D(recyclerShapeQuad2D: RecyclerShapeQuad2D, renderEncoder: MTLRenderCommandEncoder) {
        graphics.set(pipelineState: .shape2DAlphaBlending, renderEncoder: renderEncoder)
        
        var projection = matrix_float4x4()
        projection.ortho(width: graphics.width,
                         height: graphics.height)
        
        let modelView = matrix_identity_float4x4
        
        var x_prev = 0
        var x = 1
        while x < Self.tileCountH {
            
            var y_prev = 0
            var y = 1
            while y < Self.tileCountV {
                
                
                let quadX1 = points2D[x_prev][y_prev].x
                let quadY1 = points2D[x_prev][y_prev].y
                
                let quadX2 = points2D[x][y_prev].x
                let quadY2 = points2D[x][y_prev].y
                
                let quadX3 = points2D[x_prev][y].x
                let quadY3 = points2D[x_prev][y].y
                
                let quadX4 = points2D[x][y].x
                let quadY4 = points2D[x][y].y
                
                if (x - 1) == selectedFaceH && (y - 1) == selectedFaceV {
                    recyclerShapeQuad2D.set(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.25)
                    
                } else {
                    recyclerShapeQuad2D.set(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.25)
                }
                
                recyclerShapeQuad2D.drawQuad(graphics: graphics, renderEncoder: renderEncoder,
                                             projection: projection, modelView: modelView,
                                             x1: quadX1, y1: quadY1,
                                             x2: quadX2, y2: quadY2,
                                             x3: quadX3, y3: quadY3,
                                             x4: quadX4, y4: quadY4)
                
                y_prev = y
                y += 1
            }
            
            x_prev = x
            x += 1
        }
    }
    
    func drawLines2D(recyclerShapeQuad2D: RecyclerShapeQuad2D, renderEncoder: MTLRenderCommandEncoder) {
        
        graphics.set(pipelineState: .shape2DAlphaBlending, renderEncoder: renderEncoder)
        
        var projection = matrix_float4x4()
        projection.ortho(width: graphics.width,
                         height: graphics.height)
        
        let modelView = matrix_identity_float4x4
        
        var x_prev = 0
        var x = 1
        while x < Self.tileCountH {
            
            var y_prev = 0
            var y = 1
            while y < Self.tileCountV {
                
                
                let quadX1 = points2D[x_prev][y_prev].x
                let quadY1 = points2D[x_prev][y_prev].y
                
                let quadX2 = points2D[x][y_prev].x
                let quadY2 = points2D[x][y_prev].y
                
                let quadX3 = points2D[x_prev][y].x
                let quadY3 = points2D[x_prev][y].y
                
                let quadX4 = points2D[x][y].x
                let quadY4 = points2D[x][y].y
                
                recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                             projection: projection, modelView: modelView,
                                             x1: quadX1, y1: quadY1, x2: quadX2, y2: quadY2, thickness: 1.0)
                
                recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                             projection: projection, modelView: modelView,
                                             x1: quadX2, y1: quadY2, x2: quadX4, y2: quadY4, thickness: 1.0)
                
                recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                             projection: projection, modelView: modelView,
                                             x1: quadX1, y1: quadY1, x2: quadX3, y2: quadY3, thickness: 1.0)
                
                recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                             projection: projection, modelView: modelView,
                                             x1: quadX3, y1: quadY3, x2: quadX4, y2: quadY4, thickness: 1.0)
                
                y_prev = y
                y += 1
            }
            
            x_prev = x
            x += 1
        }
    }
    
    func drawHits2D(recyclerShapeQuad2D: RecyclerShapeQuad2D, renderEncoder: MTLRenderCommandEncoder) {
        
        guard let closestPoint1 = _closestPoint1 else { return }
        guard let closestPoint2 = _closestPoint2 else { return }
        guard let closestPoint3 = _closestPoint3 else { return }
        guard let closestPoint4 = _closestPoint4 else { return }
        
        var projection = matrix_float4x4()
        projection.ortho(width: graphics.width,
                         height: graphics.height)
        
        let modelView = matrix_identity_float4x4
        
        recyclerShapeQuad2D.set(red: 0.75, green: 0.0, blue: 0.0)
        recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                     projection: projection, modelView: modelView,
                                     x1: _point.x, y1: _point.y, x2: closestPoint1.x, y2: closestPoint1.y, thickness: 1.5)
        
        recyclerShapeQuad2D.set(red: 0.0, green: 0.75, blue: 0.0)
        recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                     projection: projection, modelView: modelView,
                                     x1: _point.x, y1: _point.y, x2: closestPoint2.x, y2: closestPoint2.y, thickness: 1.5)
        
        recyclerShapeQuad2D.set(red: 0.0, green: 0.0, blue: 0.75)
        recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                     projection: projection, modelView: modelView,
                                     x1: _point.x, y1: _point.y, x2: closestPoint3.x, y2: closestPoint3.y, thickness: 1.5)
        
        recyclerShapeQuad2D.set(red: 0.75, green: 0.75, blue: 0.75)
        recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                     projection: projection, modelView: modelView,
                                     x1: _point.x, y1: _point.y, x2: closestPoint4.x, y2: closestPoint4.y, thickness: 1.5)
        
    }
    
    func drawLerps3D(recyclerShapeQuad3D: RecyclerShapeQuad3D, renderEncoder: MTLRenderCommandEncoder) {
        
        guard let lerp1 = _lerp1 else { return }
        guard let lerp2 = _lerp2 else { return }
        guard let lerp3 = _lerp3 else { return }
        guard let lerp4 = _lerp4 else { return }
        
        
        let identity = matrix_identity_float4x4
        
        graphics.set(depthState: .lessThan, renderEncoder: renderEncoder)
        graphics.set(pipelineState: .shape3DAlphaBlending, renderEncoder: renderEncoder)
        
        recyclerShapeQuad3D.set(red: 1.0, green: 0.0, blue: 0.0)
        recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                           projection: camera.projection,
                                           modelView: identity,
                                           x1: 0.0, y1: 0.0, z1: 0.0,
                                           x2: lerp1.x * 1.15, y2: lerp1.y * 1.15, z2: lerp1.z * 1.15, size: 0.005)
        
        
        recyclerShapeQuad3D.set(red: 0.0, green: 1.0, blue: 0.0)
        recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                           projection: camera.projection,
                                           modelView: identity,
                                           x1: 0.0, y1: 0.0, z1: 0.0,
                                           x2: lerp2.x * 1.15, y2: lerp2.y * 1.15, z2: lerp2.z * 1.15, size: 0.005)
        
        recyclerShapeQuad3D.set(red: 0.0, green: 0.0, blue: 1.0)
        recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                           projection: camera.projection,
                                           modelView: identity,
                                           x1: 0.0, y1: 0.0, z1: 0.0,
                                           x2: lerp3.x * 1.15, y2: lerp3.y * 1.15, z2: lerp3.z * 1.15, size: 0.005)
        
        recyclerShapeQuad3D.set(red: 1.0, green: 1.0, blue: 1.0)
        recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                           projection: camera.projection,
                                           modelView: identity,
                                           x1: 0.0, y1: 0.0, z1: 0.0,
                                           x2: lerp4.x * 1.15, y2: lerp4.y * 1.15, z2: lerp4.z * 1.15, size: 0.005)
        
        guard let axis = _axis else { return }

        recyclerShapeQuad3D.set(red: 0.75, green: 0.75, blue: 0.75)
        recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                           projection: camera.projection,
                                           modelView: identity,
                                           x1: 0.0, y1: 0.0, z1: 0.0,
                                           x2: axis.x * 1.35, y2: axis.y * 1.35, z2: axis.z * 1.35, size: 0.01)
        
    }
    
}


/*
func convert(point: simd_float2) -> simd_float3? {
    
 func refresh(camera: Camera) {
     self.camera = camera
     var indexV = 0
     
     /*
     while indexV < Self.tileCountV {
         var indexH = 0
         while indexH < Self.tileCountH {
             let point = sphere.points[indexH][indexV]
             points2D[indexH][indexV] = camera.convert(float3: point)
             indexH += 1
         }
         indexV += 1
     }
     */
 }
 
    _point = point
    
    selectedFaceH = nil
    selectedFaceV = nil
    
    _closestPoint1 = nil
    _closestPoint2 = nil
    _closestPoint3 = nil
    _closestPoint4 = nil
    
    _lerp1 = nil
    _lerp2 = nil
    _lerp3 = nil
    _lerp4 = nil
    
    var prevIndexV = 0
    var indexV = 1
    var selectedZ: Float = 2048.0
    
    while indexV < Self.tileCountV {
        var prevIndexH = 0
        var indexH = 1
        while indexH < Self.tileCountH {
            
            let quadX1 = points2D[prevIndexH][prevIndexV].x
            let quadY1 = points2D[prevIndexH][prevIndexV].y
            
            let quadX2 = points2D[indexH][prevIndexV].x
            let quadY2 = points2D[indexH][prevIndexV].y
            
            let quadX3 = points2D[indexH][indexV].x
            let quadY3 = points2D[indexH][indexV].y
            
            let quadX4 = points2D[prevIndexH][indexV].x
            let quadY4 = points2D[prevIndexH][indexV].y
            
            if Math.quadBoundingBoxContainsPoint2D(x: point.x, y: point.y,
                                                   quadX1: quadX1, quadY1: quadY1, quadX2: quadX2, quadY2: quadY2,
                                                   quadX3: quadX3, quadY3: quadY3, quadX4: quadX4, quadY4: quadY4) {
            
                if Math.quadContainsPoint2D(x: point.x, y: point.y,
                                            quadX1: quadX1, quadY1: quadY1, quadX2: quadX2, quadY2: quadY2,
                                            quadX3: quadX3, quadY3: quadY3, quadX4: quadX4, quadY4: quadY4) {
                    
                    let z1 = sphere.points[prevIndexH][prevIndexV].z
                    let z2 = sphere.points[indexH][prevIndexV].z
                    let z3 = sphere.points[prevIndexH][indexV].z
                    let z4 = sphere.points[indexH][indexV].z
                    
                    var z = z1
                    if z2 < z { z = z2 }
                    if z3 < z { z = z3 }
                    if z4 < z { z = z4 }
                    
                    if z < selectedZ {
                        selectedZ = z
                        selectedFaceV = prevIndexV
                        selectedFaceH = prevIndexH
                    }
                }
            }
            prevIndexH = indexH
            indexH += 1
        }
        prevIndexV = indexV
        indexV += 1
    }

    guard let selectedFaceH = selectedFaceH else { return nil }
    guard let selectedFaceV = selectedFaceV else { return nil }
    
    
    let quadX1 = points2D[selectedFaceH][selectedFaceV].x
    let quadY1 = points2D[selectedFaceH][selectedFaceV].y
    
    let quadX2 = points2D[selectedFaceH + 1][selectedFaceV].x
    let quadY2 = points2D[selectedFaceH + 1][selectedFaceV].y
    
    let quadX3 = points2D[selectedFaceH][selectedFaceV + 1].x
    let quadY3 = points2D[selectedFaceH][selectedFaceV + 1].y
    
    let quadX4 = points2D[selectedFaceH + 1][selectedFaceV + 1].x
    let quadY4 = points2D[selectedFaceH + 1][selectedFaceV + 1].y
    
    let closestPoint1 = Math.segmentClosestPoint(point: point,
                                                 lineStart: simd_float2(quadX1, quadY1),
                                                 lineEnd: simd_float2(quadX2, quadY2))
    let closestPoint2 = Math.segmentClosestPoint(point: point,
                                                 lineStart: simd_float2(quadX2, quadY2),
                                                 lineEnd: simd_float2(quadX4, quadY4))
    let closestPoint3 = Math.segmentClosestPoint(point: point,
                                                 lineStart: simd_float2(quadX4, quadY4),
                                                 lineEnd: simd_float2(quadX3, quadY3))
    let closestPoint4 = Math.segmentClosestPoint(point: point,
                                                 lineStart: simd_float2(quadX3, quadY3),
                                                 lineEnd: simd_float2(quadX1, quadY1))
    
    _closestPoint1 = closestPoint1
    _closestPoint2 = closestPoint2
    _closestPoint3 = closestPoint3
    _closestPoint4 = closestPoint4
    
    
    let selectedAxis1 = simd_float3(sphere.points[selectedFaceH][selectedFaceV].x,
                                    sphere.points[selectedFaceH][selectedFaceV].y,
                                    sphere.points[selectedFaceH][selectedFaceV].z)
    
    let selectedAxis2 = simd_float3(sphere.points[selectedFaceH + 1][selectedFaceV].x,
                                    sphere.points[selectedFaceH + 1][selectedFaceV].y,
                                    sphere.points[selectedFaceH + 1][selectedFaceV].z)
    
    let selectedAxis3 = simd_float3(sphere.points[selectedFaceH][selectedFaceV + 1].x,
                                    sphere.points[selectedFaceH][selectedFaceV + 1].y,
                                    sphere.points[selectedFaceH][selectedFaceV + 1].z)
    
    let selectedAxis4 = simd_float3(sphere.points[selectedFaceH + 1][selectedFaceV + 1].x,
                                    sphere.points[selectedFaceH + 1][selectedFaceV + 1].y,
                                    sphere.points[selectedFaceH + 1][selectedFaceV + 1].z)
    
    
    let distanceToClosestPoint1 = Math.distance(point1: point, point2: closestPoint1)
    let distanceToClosestPoint2 = Math.distance(point1: point, point2: closestPoint2)
    let distanceToClosestPoint3 = Math.distance(point1: point, point2: closestPoint3)
    let distanceToClosestPoint4 = Math.distance(point1: point, point2: closestPoint4)
    
    let totalDistance = distanceToClosestPoint1 + distanceToClosestPoint2 + distanceToClosestPoint3 + distanceToClosestPoint4
    if totalDistance < Math.epsilon { return nil }
    
    
    
    var lerp1 = selectedAxis1
    var lerp2 = selectedAxis2
    var lerp3 = selectedAxis4
    var lerp4 = selectedAxis3
    
    var distA: Float = 0.0
    var distB: Float = 0.0
    var distC: Float = 0.0
    
    distA = Math.distance(point1: closestPoint1, point2: simd_float2(quadX1, quadY1))
    distB = Math.distance(point1: closestPoint1, point2: simd_float2(quadX2, quadY2))
    distC = distA + distB
    if distC > Math.epsilon {
        let percent = distA / distC
        let percentInverse = (1.0 - percent)
        lerp1 = simd_float3(selectedAxis1.x * percentInverse + selectedAxis2.x * percent,
                            selectedAxis1.y * percentInverse + selectedAxis2.y * percent,
                            selectedAxis1.z * percentInverse + selectedAxis2.z * percent)
    }
    
    
    distA = Math.distance(point1: closestPoint2, point2: simd_float2(quadX2, quadY2))
    distB = Math.distance(point1: closestPoint2, point2: simd_float2(quadX4, quadY4))
    distC = distA + distB
    if distC > Math.epsilon {
        let percent = distA / distC
        let percentInverse = (1.0 - percent)
        lerp2 = simd_float3(selectedAxis2.x * percentInverse + selectedAxis4.x * percent,
                            selectedAxis2.y * percentInverse + selectedAxis4.y * percent,
                            selectedAxis2.z * percentInverse + selectedAxis4.z * percent)
    }
    
    distA = Math.distance(point1: closestPoint3, point2: simd_float2(quadX4, quadY4))
    distB = Math.distance(point1: closestPoint3, point2: simd_float2(quadX3, quadY3))
    distC = distA + distB
    if distC > Math.epsilon {
        let percent = distA / distC
        let percentInverse = (1.0 - percent)
        lerp3 = simd_float3(selectedAxis4.x * percentInverse + selectedAxis3.x * percent,
                            selectedAxis4.y * percentInverse + selectedAxis3.y * percent,
                            selectedAxis4.z * percentInverse + selectedAxis3.z * percent)
    }
    
    distA = Math.distance(point1: closestPoint4, point2: simd_float2(quadX3, quadY3))
    distB = Math.distance(point1: closestPoint4, point2: simd_float2(quadX1, quadY1))
    distC = distA + distB
    if distC > Math.epsilon {
        let percent = distA / distC
        let percentInverse = (1.0 - percent)
        lerp4 = simd_float3(selectedAxis3.x * percentInverse + selectedAxis1.x * percent,
                            selectedAxis3.y * percentInverse + selectedAxis1.y * percent,
                            selectedAxis3.z * percentInverse + selectedAxis1.z * percent)
    }
    
    _lerp1 = lerp1
    _lerp2 = lerp2
    _lerp3 = lerp3
    _lerp4 = lerp4
    
    
    let weight1 = (distanceToClosestPoint2 * distanceToClosestPoint3 * distanceToClosestPoint4) /
    (distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint3 +
     distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint4 +
     distanceToClosestPoint1 * distanceToClosestPoint3 * distanceToClosestPoint4 +
     distanceToClosestPoint2 * distanceToClosestPoint3 * distanceToClosestPoint4)
        
    let weight2 = (distanceToClosestPoint1 * distanceToClosestPoint3 * distanceToClosestPoint4) /
    (distanceToClosestPoint2 * distanceToClosestPoint1 * distanceToClosestPoint3 +
     distanceToClosestPoint2 * distanceToClosestPoint1 * distanceToClosestPoint4 +
     distanceToClosestPoint2 * distanceToClosestPoint3 * distanceToClosestPoint4 +
     distanceToClosestPoint1 * distanceToClosestPoint3 * distanceToClosestPoint4)
        
    let weight3 = (distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint4) /
    (distanceToClosestPoint3 * distanceToClosestPoint1 * distanceToClosestPoint2 +
     distanceToClosestPoint3 * distanceToClosestPoint1 * distanceToClosestPoint4 +
     distanceToClosestPoint3 * distanceToClosestPoint2 * distanceToClosestPoint4 +
     distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint4)
        
    let weight4 = (distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint3) /
    (distanceToClosestPoint4 * distanceToClosestPoint1 * distanceToClosestPoint2 +
     distanceToClosestPoint4 * distanceToClosestPoint1 * distanceToClosestPoint3 +
     distanceToClosestPoint4 * distanceToClosestPoint2 * distanceToClosestPoint3 +
     distanceToClosestPoint1 * distanceToClosestPoint2 * distanceToClosestPoint3)
    
    var axisX = lerp1.x * weight1 + lerp2.x * weight2 + lerp3.x * weight3 + lerp4.x * weight4
    var axisY = lerp1.y * weight1 + lerp2.y * weight2 + lerp3.y * weight3 + lerp4.y * weight4
    var axisZ = lerp1.z * weight1 + lerp2.z * weight2 + lerp3.z * weight3 + lerp4.z * weight4
    
    var axisLength = axisX * axisX + axisY * axisY + axisZ * axisZ
    guard axisLength > Math.epsilon else { return nil }
    
    axisLength = sqrtf(axisLength)
    axisX /= axisLength
    axisY /= axisLength
    axisZ /= axisLength
    
    _axis = simd_float3(axisX, axisY, axisZ)
    
    return simd_float3(axisX, axisY, axisZ)
}

func drawRays3D(recyclerShapeQuad3D: RecyclerShapeQuad3D, renderEncoder: MTLRenderCommandEncoder) {
    
    var identity = matrix_float4x4()
    identity.reset()
    
    graphics.set(depthState: .lessThan, renderEncoder: renderEncoder)
    graphics.set(pipelineState: .shape3DAlphaBlending, renderEncoder: renderEncoder)
    
    for x in 0..<EarthProjection2D.tileCountH {
        for y in 0..<EarthProjection2D.tileCountV {
            let ray = sphere.points[x][y]
            
            let red = Float(x) / Float(EarthProjection2D.tileCountH)
            let green = Float(y) / Float(EarthProjection2D.tileCountV)
            
            recyclerShapeQuad3D.setColor(red: red, green: 1.0, blue: green)
            
            recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                               projection: camera.projection,
                                               modelView: identity,
                                               x1: 0.0, y1: 0.0, z1: 0.0,
                                               x2: ray.x * 1.05, y2: ray.y * 1.05, z2: ray.z * 1.05, size: 0.0025)
            
        }
    }
}

func drawLerps3D(recyclerShapeQuad3D: RecyclerShapeQuad3D, renderEncoder: MTLRenderCommandEncoder) {
    
    guard let lerp1 = _lerp1 else { return }
    guard let lerp2 = _lerp2 else { return }
    guard let lerp3 = _lerp3 else { return }
    guard let lerp4 = _lerp4 else { return }
    
    
    var identity = matrix_float4x4()
    identity.reset()
    
    graphics.set(depthState: .lessThan, renderEncoder: renderEncoder)
    graphics.set(pipelineState: .shape3DAlphaBlending, renderEncoder: renderEncoder)
    
    recyclerShapeQuad3D.setColor(red: 1.0, green: 0.0, blue: 0.0)
    recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                       projection: camera.projection,
                                       modelView: identity,
                                       x1: 0.0, y1: 0.0, z1: 0.0,
                                       x2: lerp1.x * 1.15, y2: lerp1.y * 1.15, z2: lerp1.z * 1.15, size: 0.005)
    
    
    recyclerShapeQuad3D.setColor(red: 0.0, green: 1.0, blue: 0.0)
    recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                       projection: camera.projection,
                                       modelView: identity,
                                       x1: 0.0, y1: 0.0, z1: 0.0,
                                       x2: lerp2.x * 1.15, y2: lerp2.y * 1.15, z2: lerp2.z * 1.15, size: 0.005)
    
    recyclerShapeQuad3D.setColor(red: 0.0, green: 0.0, blue: 1.0)
    recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                       projection: camera.projection,
                                       modelView: identity,
                                       x1: 0.0, y1: 0.0, z1: 0.0,
                                       x2: lerp3.x * 1.15, y2: lerp3.y * 1.15, z2: lerp3.z * 1.15, size: 0.005)
    
    recyclerShapeQuad3D.setColor(red: 1.0, green: 1.0, blue: 1.0)
    recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                       projection: camera.projection,
                                       modelView: identity,
                                       x1: 0.0, y1: 0.0, z1: 0.0,
                                       x2: lerp4.x * 1.15, y2: lerp4.y * 1.15, z2: lerp4.z * 1.15, size: 0.005)
    
    guard let axis = _axis else { return }
    
    recyclerShapeQuad3D.setColor(red: 0.75,
                                 green: 0.75,
                                 blue: 0.75)
    recyclerShapeQuad3D.drawLineCuboid(graphics: graphics, renderEncoder: renderEncoder,
                                       projection: camera.projection,
                                       modelView: identity,
                                       x1: 0.0, y1: 0.0, z1: 0.0,
                                       x2: axis.x * 1.35, y2: axis.y * 1.35, z2: axis.z * 1.35, size: 0.01)
    
}




func drawHits2D(recyclerShapeQuad2D: RecyclerShapeQuad2D, renderEncoder: MTLRenderCommandEncoder) {
    
    guard let closestPoint1 = _closestPoint1 else { return }
    guard let closestPoint2 = _closestPoint2 else { return }
    guard let closestPoint3 = _closestPoint3 else { return }
    guard let closestPoint4 = _closestPoint4 else { return }
    
    var projection = matrix_float4x4()
    projection.ortho(width: graphics.width,
                     height: graphics.height)
    
    var modelView = matrix_float4x4()
    modelView.reset()
    
    quadRecycler.set(red: 0.75, green: 0.0, blue: 0.0)
    recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                 projection: projection, modelView: modelView,
                                 x1: _point.x, y1: _point.y, x2: closestPoint1.x, y2: closestPoint1.y, thickness: 1.5)
    
    quadRecycler.set(red: 0.0, green: 0.75, blue: 0.0)
    recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                 projection: projection, modelView: modelView,
                                 x1: _point.x, y1: _point.y, x2: closestPoint2.x, y2: closestPoint2.y, thickness: 1.5)
    
    quadRecycler.set(red: 0.0, green: 0.0, blue: 0.75)
    recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                 projection: projection, modelView: modelView,
                                 x1: _point.x, y1: _point.y, x2: closestPoint3.x, y2: closestPoint3.y, thickness: 1.5)
    
    quadRecycler.set(red: 0.75, green: 0.75, blue: 0.75)
    recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                 projection: projection, modelView: modelView,
                                 x1: _point.x, y1: _point.y, x2: closestPoint4.x, y2: closestPoint4.y, thickness: 1.5)
    
    
    
}



*/
