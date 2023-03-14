//
//  GestureProcessor.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/22/23.
//

import Foundation
import simd
import Metal

class GestureProcessor {
    
    enum PanMode {
        case outside
        case inside
    }
    
    private static let outsideReferencePointFactor: Float = 1.5
    private static let radiusStartTransitionFactor: Float = 0.75
    private static let radiusEndTransitionFactor: Float = 0.90
    
    var earthCenter = simd_float2(255.0, 255.0)
    
    let earth: Earth
    let scene: EarthScene
    let dimensionBridge: DimensionBridge
    
    private(set) var radius: Float = 255.0
    private(set) var radiusStart: Float = 255.0
    private(set) var radiusEnd: Float = 255.0
    
    private var center = simd_float2(0.0, 0.0)
    private var targetCenter = simd_float2(0.0, 0.0)
    
    private var isPanning = false
    
    private var panMode = PanMode.inside
    
    private var outsideStartCenter = simd_float2(0.0, 0.0)
    private var outsideStartYaw: Float = 0.0
    private var outsideStartPitch: Float = 0.0
    private var outsideStartRoll: Float = 0.0
    
    private var insideStartAxis = simd_float3(0.0, -1.0, 0.0)
    private var insideStartCenter = simd_float2(0.0, 0.0)
    private var insideStartYaw: Float = 0.0
    private var insideStartPitch: Float = 0.0
    private var insideStartRoll: Float = 0.0
    
    private var isRotating = false
    private var rotationTarget = Float(0.0)
    private var rotation = Float(0.0)
    
    private var isPinching = false
    
    private var pinchStartZoom = Float(3.0)
    private var zoomTarget = Float(3.0)
    
    init(earth: Earth,
         scene: EarthScene,
         dimensionBridge: DimensionBridge) {
        self.earth = earth
        self.scene = scene
        self.dimensionBridge = dimensionBridge
    }
    
    func load(graphics: Graphics) {
        isPinching = false
        isPanning = false
        isRotating = false
        
        earthCenter = simd_float2(graphics.width * 0.5, graphics.height * 0.5)
        center = earthCenter
        targetCenter = earthCenter
        
        radius = scene.radius
        radiusStart = radius * Self.radiusStartTransitionFactor
        radiusEnd = radius * Self.radiusEndTransitionFactor
        
        
        pinchStartZoom = earth.zoom
        zoomTarget = earth.zoom
        
    }
    
    func update() {
        
        var anyChanges = false
        
        let diffX = targetCenter.x - center.x
        let diffY = targetCenter.y - center.y
        var centerTargetDist = diffX * diffX + diffY * diffY
        if centerTargetDist > Math.epsilon {
            centerTargetDist = sqrtf(centerTargetDist)
            let moveDist = centerTargetDist * 0.1 + 0.1
            if moveDist > centerTargetDist {
                center = targetCenter
            } else {
                center.x += (diffX / centerTargetDist) * moveDist
                center.y += (diffY / centerTargetDist) * moveDist
            }
            anyChanges = true
        }
        
        let angleDiff = Math.angleDistance(radians1: rotation, radians2: rotationTarget)
        if angleDiff > Math.epsilon {
            var moveAmount = angleDiff * 0.075 + 0.001
            if moveAmount > angleDiff {
                moveAmount = angleDiff
            }
            
            applyRotationChange(amount: moveAmount)
            rotation += moveAmount
            anyChanges = true
        } else if angleDiff < -Math.epsilon {
            
            var moveAmount = angleDiff * 0.075 - 0.001
            if moveAmount < angleDiff {
                moveAmount = angleDiff
            }
            
            applyRotationChange(amount: moveAmount)
            rotation += moveAmount
            anyChanges = true
        }
        
        if !isPinching {
            
            if zoomTarget < ZoomTable.minZoomSoft {
                let diff = (ZoomTable.minZoomSoft - zoomTarget)
                zoomTarget += diff * 0.25 + 0.0025
                if zoomTarget > ZoomTable.minZoomSoft {
                    zoomTarget = ZoomTable.minZoomSoft
                }
                
            }
            
            if zoomTarget > ZoomTable.maxZoomSoft {
                let diff = (zoomTarget - ZoomTable.maxZoomSoft)
                zoomTarget -= diff * 0.25 + 0.0025
                if zoomTarget < ZoomTable.maxZoomSoft {
                    zoomTarget = ZoomTable.maxZoomSoft
                }
            }
        }
        
        let pinchDiff = zoomTarget - earth.zoom
        if pinchDiff > Math.epsilon {
            
            var adjustAmount = pinchDiff * 0.15 + 0.01
            if adjustAmount > pinchDiff {
                adjustAmount = pinchDiff
            }
            applyZoomChange(amount: adjustAmount)
            anyChanges = true
            
        } else if pinchDiff < -Math.epsilon {
            var adjustAmount = pinchDiff * 0.15 - 0.01
            if adjustAmount < pinchDiff {
                adjustAmount = pinchDiff
            }
            applyZoomChange(amount: adjustAmount)
            anyChanges = true
        }
        
        if anyChanges {
            switch panMode {
            case .outside:
                updatePanOuter()
            case .inside:
                updatePanInner()
            }
        }
    }
    
    func draw2D(graphics: Graphics,
                recyclerShapeQuad2D: RecyclerShapeQuad2D,
                renderEncoder: MTLRenderCommandEncoder) {
        
    }
    
    
    private func handlePanBeganInner(center: simd_float2) {
        panMode = .inside
        isPanning = true
        
        insideStartAxis = axis(point: center)
        insideStartYaw = earth.yawBase
        insideStartPitch = earth.pitchBase
        insideStartRoll = earth.rollBase
    }
    
    private func handlePanBeganOuter(center: simd_float2) {
        panMode = .outside
        isPanning = true
        
        outsideStartCenter = center
        outsideStartYaw = earth.yawBase
        outsideStartPitch = earth.pitchBase
        outsideStartRoll = earth.rollBase
    }
    
    private func handleGestureBeganInner(center: simd_float2) {
        handlePanBeganInner(center: center)
    }
    
    private func handleGestureBeganOuter(center: simd_float2) {
        handlePanBeganOuter(center: center)
    }
    
    func anyGestureBegan(position: simd_float2) {
        combineBaseEulersWithModifyEulers()
        
        let distanceToCenter = Math.distance(point1: position, point2: earthCenter)
        
        if distanceToCenter < radiusEnd {
            
            center = position
            targetCenter = position
            handleGestureBeganInner(center: position)
        } else {
            
            center = position
            targetCenter = position
            handleGestureBeganOuter(center: position)
        }
    }
    
    func anyGestureUpdated(position: simd_float2) {
        if isPanning {
            targetCenter = position
        }
    }
    
    func rotateGestureBegan(position: simd_float2) {
        isRotating = true
        rotation = 0.0
        rotationTarget = 0.0
    }
    
    func rotateGestureUpdated(position: simd_float2, rotation: Float) {
        if isRotating {
            rotationTarget = fmodf(rotation, Float.pi * 2.0)
            if rotationTarget < 0.0 {
                rotationTarget += Float.pi * 2.0
            }
        }
    }
    
    func pinchGestureBegan(position: simd_float2) {
        isPinching = true
        
        pinchStartZoom = earth.zoom
        zoomTarget = earth.zoom
    }
    
    func pinchGestureUpdated(position: simd_float2, scale: Float) {
        if isPinching {
            
            var zoom = pinchStartZoom * scale
            if zoom < ZoomTable.minZoomSoft {
                zoom = Math.fallOffUndershoot(input: zoom,
                                          falloffStart: ZoomTable.minZoomSoft,
                                          resultMin: ZoomTable.minZoomHard,
                                          inputMin: ZoomTable.minZoomUndershoot)
            }
            if zoom > ZoomTable.maxZoomSoft {
                zoom = Math.fallOffOvershoot(input: zoom,
                                             falloffStart: ZoomTable.maxZoomSoft,
                                             resultMax: ZoomTable.maxZoomHard,
                                             inputMax: ZoomTable.maxZoomOvershoot)
            }
            
            zoomTarget = zoom
        }
    }
    
    func matrix(yaw: Float, pitch: Float, roll: Float) -> matrix_float4x4 {
        var quat = simd_quatf()
        quat.makeEulerRadians(yaw: yaw, pitch: pitch, roll: roll)
        return simd_float4x4(quat)
    }
    
    func quat(yaw: Float, pitch: Float, roll: Float) -> simd_quatf {
        var quat = simd_quatf()
        quat.makeEulerRadians(yaw: yaw, pitch: pitch, roll: roll)
        return quat
    }
    
    func untransform(axis: simd_float3, yaw: Float, pitch: Float, roll: Float) -> simd_float3 {
        var quat = simd_quatf()
        quat.makeEulerRadians(yaw: yaw, pitch: pitch, roll: roll)
        var matrix = matrix_float4x4(quat)
        matrix.invert()
        return matrix.process(point3: axis)
    }
    
    func transform(axis: simd_float3, yaw: Float, pitch: Float, roll: Float) -> simd_float3 {
        var quat = simd_quatf()
        quat.makeEulerRadians(yaw: yaw, pitch: pitch, roll: roll)
        let matrix = matrix_float4x4(quat)
        return matrix.process(point3: axis)
    }
    
    func applyZoomChange(amount: Float) {
        
        
        //pinchStartZoom = earth.zoom
        //zoomTarget = earth.zoom
        
        earth.zoom += amount
        scene.earthCamera.distance = scene.zoomTable.distance(zoom: earth.zoom)
        scene.dimensionBridge.refresh()
        
        radius = scene.cameraCalibrationTool.estimateRadius(graphics: scene.graphics,
                                                            camera: earth.camera)
        radiusStart = radius * Self.radiusStartTransitionFactor
        radiusEnd = radius * Self.radiusEndTransitionFactor
        scene.radius = radius
        
    }
    
    func applyRotationChange(amount: Float) {
        
        if case .inside = panMode {
            
            var axisCurrent = axis(point: center)
            
            axisCurrent = untransform(axis: axisCurrent, yaw: earth.yawBase, pitch: earth.pitchBase, roll: earth.rollBase)
            axisCurrent = untransform(axis: axisCurrent, yaw: earth.yawModify, pitch: earth.pitchModify, roll: earth.rollModify)
            axisCurrent = untransform(axis: axisCurrent, yaw: earth.yawRotate, pitch: earth.pitchRotate, roll: earth.rollRotate)
            
            var rotateEulerQuat = quat(yaw: earth.yawRotate,
                                       pitch: earth.pitchRotate,
                                       roll: earth.rollRotate)
            var rotateEulerMatrix = matrix_float4x4(rotateEulerQuat)

            rotateEulerMatrix.rotate(radians: -amount, axisX: axisCurrent.x, axisY: axisCurrent.y, axisZ: axisCurrent.z)
            
            rotateEulerQuat = simd_quatf(rotateEulerMatrix)
            
            let eulers = rotateEulerQuat.eulersRadians()
            
            earth.yawRotate = eulers.x
            earth.pitchRotate = eulers.y
            earth.rollRotate = eulers.z
            
        } else {
            
            var dirX = center.x - earthCenter.x
            var dirY = center.y - earthCenter.y
            var length = dirX * dirX + dirY * dirY
            if length > Math.epsilon {
                length = sqrtf(length)
                dirX /= length
                dirY /= length
            }
            
            if length > radiusEnd {
                length = radiusEnd
            }
            
            let swivel = simd_float2(earthCenter.x + dirX * length,
                                     earthCenter.y + dirY * length)
            
            var axisCurrent = axis(point: swivel)
            
            var rotateEulerQuat = quat(yaw: earth.yawRotate,
                                       pitch: earth.pitchRotate,
                                       roll: earth.rollRotate)
            var rotateEulerMatrix = matrix_float4x4(rotateEulerQuat)
            
            axisCurrent = untransform(axis: axisCurrent, yaw: earth.yawBase, pitch: earth.pitchBase, roll: earth.rollBase)
            axisCurrent = untransform(axis: axisCurrent, yaw: earth.yawModify, pitch: earth.pitchModify, roll: earth.rollModify)
            axisCurrent = untransform(axis: axisCurrent, yaw: earth.yawRotate, pitch: earth.pitchRotate, roll: earth.rollRotate)
            
            rotateEulerMatrix.rotate(radians: -amount, axisX: axisCurrent.x, axisY: axisCurrent.y, axisZ: axisCurrent.z)
            
            rotateEulerQuat = simd_quatf(rotateEulerMatrix)
            let eulers = rotateEulerQuat.eulersRadians()
            
            earth.yawRotate = eulers.x
            earth.pitchRotate = eulers.y
            earth.rollRotate = eulers.z
        }
    }
    
    func updatePanInner() {
        
        let insideQuat = insideQuat()
        
        let distanceToCenter = Math.distance(point1: center, point2: earthCenter)
        
        if distanceToCenter > radiusEnd {
            
            combineBaseEulersWithModifyEulers()
            handleGestureBeganOuter(center: center)
            
        } else {
            
            if distanceToCenter > radiusStart {
                
                let percent = (distanceToCenter - radiusStart) / (radiusEnd - radiusStart)
                
                var dirX = center.x - earthCenter.x
                var dirY = center.y - earthCenter.y
                var length = dirX * dirX + dirY * dirY
                if length > Math.epsilon {
                    length = sqrtf(length)
                    dirX /= length
                    dirY /= length
                } else {
                    dirX = 0.0
                    dirY = -1.0
                }
                
                outsideStartCenter = simd_float2(earthCenter.x + dirX * radiusStart,
                                               earthCenter.y + dirY * radiusStart)
                
                let outsideStartQuat = self.insideQuat(center: outsideStartCenter)
                
                let outsideStartEulers = outsideStartQuat.eulersRadians()
                
                outsideStartYaw = outsideStartEulers.x
                outsideStartPitch = outsideStartEulers.y
                outsideStartRoll = outsideStartEulers.z
                
                let outsideQuat = outsideStartQuat * outsideQuat()
                
                let quat = simd_slerp(outsideQuat, insideQuat, percent)
                
                let eulers = quat.eulersRadians()
                
                earth.yawModify = eulers.x
                earth.pitchModify = eulers.y
                earth.rollModify = eulers.z
                
            } else {
                
                let eulers = insideQuat.eulersRadians()
                
                earth.yawModify = eulers.x
                earth.pitchModify = eulers.y
                earth.rollModify = eulers.z
                
                combineBaseEulersWithModifyEulers()
                handleGestureBeganInner(center: center)
            }
        }
    }
    
    func updatePanOuter() {
        
        let outsideQuat = outsideQuat()
        
        let distanceToCenter = Math.distance(point1: center, point2: earthCenter)
        
        if distanceToCenter < radiusStart {
            
            combineBaseEulersWithModifyEulers()
            handleGestureBeganInner(center: center)
            
        } else {
            
            if distanceToCenter < radiusEnd {
                
                let percent = 1.0 - ((distanceToCenter - radiusStart) / (radiusEnd - radiusStart))
                
                
                var dirX = center.x - earthCenter.x
                var dirY = center.y - earthCenter.y
                var length = dirX * dirX + dirY * dirY
                if length > Math.epsilon {
                    length = sqrtf(length)
                    dirX /= length
                    dirY /= length
                } else {
                    dirX = 0.0
                    dirY = -1.0
                }
                
                let insideStartCenter = simd_float2(earthCenter.x + dirX * radiusStart,
                                                   earthCenter.y + dirY * radiusStart)
                
                let insideEndCenter = simd_float2(earthCenter.x + dirX * radiusEnd,
                                                 earthCenter.y + dirY * radiusEnd)
                let insideEndAxis = axis(point: insideEndCenter)
                
                
                let insideEndQuat = self.outsideQuat(center: insideEndCenter)
                let insideEndEulers = insideEndQuat.eulersRadians()
                
                let _axis = axis(point: center)
                
                insideStartYaw = insideEndEulers.x
                insideStartPitch = insideEndEulers.y
                insideStartRoll = insideEndEulers.z
                
                insideStartAxis = axis(point: insideStartCenter)
                
                let outsideEulersBase = outsideQuat.eulersRadians()
                
                let outsideEulers = combine(yaw1: outsideStartYaw,
                                       pitch1: outsideStartPitch,
                                       roll1: outsideStartRoll,
                                       yaw2: outsideEulersBase.x,
                                       pitch2: outsideEulersBase.y,
                                       roll2: outsideEulersBase.z)
                
                var xformQu = insideQuat(insideStartYaw: outsideEulers.x,
                                         insideStartPitch: outsideEulers.y,
                                         insideStartRoll: outsideEulers.z,
                                         insideStartAxis: _axis,
                                         axis: insideEndAxis)
                
                xformQu = simd_conjugate(xformQu)
                //xformQu = simd_negate(xformQu)
                
                let quatto = insideEndQuat * xformQu
                
                
                let quat = simd_slerp(outsideQuat, quatto, percent)
                let eulers = quat.eulersRadians()
                
                earth.yawModify = eulers.x
                earth.pitchModify = eulers.y
                earth.rollModify = eulers.z
                
            } else {
                
                let eulers = outsideQuat.eulersRadians()
                
                earth.yawModify = eulers.x
                earth.pitchModify = eulers.y
                earth.rollModify = eulers.z
                
                combineBaseEulersWithModifyEulers()
                handleGestureBeganOuter(center: center)
            }
        }
    }
    
    private func applyQuaternion(yaw: Float, pitch: Float, roll: Float,
                                 quat: simd_quatf) -> simd_float3 {
        var quatLHS = simd_quatf()
        quatLHS.makeEulerRadians(yaw: yaw, pitch: pitch, roll: roll)
        let quat = quatLHS * quat
        return quat.eulersRadians()
    }
    
    private func combine(yaw1: Float, pitch1: Float, roll1: Float,
                         yaw2: Float, pitch2: Float, roll2: Float) -> simd_float3 {
        
        var quatLHS = simd_quatf()
        quatLHS.makeEulerRadians(yaw: yaw1, pitch: pitch1, roll: roll1)
        
        var quatRHS = simd_quatf()
        quatRHS.makeEulerRadians(yaw: yaw2, pitch: pitch2, roll: roll2)
        
        let quat = quatLHS * quatRHS
        
        return quat.eulersRadians()
    }
    
    private func combine(yaw1: Float, pitch1: Float, roll1: Float,
                         yaw2: Float, pitch2: Float, roll2: Float,
                         yaw3: Float, pitch3: Float, roll3: Float) -> simd_float3 {
        
        var quatLHS = simd_quatf()
        quatLHS.makeEulerRadians(yaw: yaw1, pitch: pitch1, roll: roll1)
        
        var quatMHS = simd_quatf()
        quatMHS.makeEulerRadians(yaw: yaw2, pitch: pitch2, roll: roll2)
        
        var quatRHS = simd_quatf()
        quatRHS.makeEulerRadians(yaw: yaw3, pitch: pitch3, roll: roll3)
        
        let quat = quatLHS * quatMHS * quatRHS
        
        return quat.eulersRadians()
    }
    
    private func insideQuat() -> simd_quatf {
        insideQuat(center: center)
    }
    
    private func insideQuat(center: simd_float2) -> simd_quatf {
        insideQuat(insideStartYaw: insideStartYaw,
                   insideStartPitch: insideStartPitch,
                   insideStartRoll: insideStartRoll,
                   insideStartAxis: insideStartAxis,
                   axis: axis(point: center))
    }
    
    private func insideQuat(insideStartYaw: Float,
                            insideStartPitch: Float,
                            insideStartRoll: Float,
                            insideStartAxis: simd_float3,
                            axis: simd_float3) -> simd_quatf {
        let axisCurrent = transformAxis(yaw: insideStartYaw,
                                        pitch: insideStartPitch,
                                        roll: insideStartRoll,
                                        axis: axis)
        let axisStart = transformAxis(yaw: insideStartYaw,
                                      pitch: insideStartPitch,
                                      roll: insideStartRoll,
                                      axis: insideStartAxis)
        return simd_quatf(from: axisStart, to: axisCurrent)
    }
    
    private func outsideQuat() -> simd_quatf {
        outsideQuat(center: center)
    }
    
    private func outsideQuat(center: simd_float2) -> simd_quatf {
        
        var baseUntransformMatrix = matrix_identity_float4x4
        baseUntransformMatrix.rotateX(radians: -earth.yawBase)
        baseUntransformMatrix.rotateY(radians: -earth.pitchBase)
        baseUntransformMatrix.rotateZ(radians: -earth.rollBase)
        
        let angleStart = Math.radiansFacing(origin: earthCenter, target: outsideStartCenter)
        let angleCurrent = Math.radiansFacing(origin: earthCenter, target: center)
        let angleDiff = Math.angleDistance(radians1: angleStart, radians2: angleCurrent)
        
        let distStart = Math.distance(point1: earthCenter, point2: outsideStartCenter)
        let distCurrent = Math.distance(point1: earthCenter, point2: center)
        
        let angleSpin = (distCurrent - distStart) * Self.outsideReferencePointFactor / radius
        
        let dirStart = Math.vector2D(radians: angleStart)
        let normalStart = simd_float2(-dirStart.y, dirStart.x)
        
        // Step 1.) We "pivot" around the center of the screen. This is
        // essentially a rotation around the z-axis. However, we must first
        // "correct" the axis to take into account the current orientation.
        
        var pivotAxis = simd_float3(0.0, 0.0, 1.0)
        pivotAxis = baseUntransformMatrix.process(point3: pivotAxis)
        
        var pivotMatrix = matrix_float4x4()
        pivotMatrix.rotation(radians: angleDiff,
                             axisX: pivotAxis.x,
                             axisY: pivotAxis.y,
                             axisZ: pivotAxis.z)
        let pivotQuat = simd_quatf(pivotMatrix)
        
        
        // Step 2.) We "spin" around an axis perpendicular to the direction
        // our finger started moving. Think of this as a rolling pin, we
        // spin the earth as if we're impaled by the rolling pin. However, we must
        // first "correct" the axis to take into account the current orientation.
        
        var spinAxis = simd_float3(normalStart.x, normalStart.y, 0.0)
        spinAxis = baseUntransformMatrix.process(point3: spinAxis)
        
        var spinMatrix = matrix_float4x4()
        spinMatrix.rotation(radians: angleSpin,
                                   axisX: spinAxis.x,
                                   axisY: spinAxis.y,
                                   axisZ: spinAxis.z)
        let spinQuat = simd_quatf(spinMatrix)
        
        return simd_mul(pivotQuat, spinQuat)
        
    }
    
    private func axis(point: simd_float2) -> simd_float3 {
        if let axis = dimensionBridge.convert(point: point) {
            return axis
        } else {
            print("DANGER!!! No axis found for \(point), expected axis...")
            return simd_float3(0.0, 0.0, -1.0)
        }
    }
    
    private func transformAxis(yaw: Float, pitch: Float, roll: Float,
                               axis: simd_float3) -> simd_float3 {
        var quat = simd_quatf()
        quat.makeEulerRadians(yaw: yaw, pitch: pitch, roll: roll)
        
        var matrix = simd_float4x4(quat)
        matrix.invert()
        return matrix.process(point3: axis)
    }
    
    func combineBaseEulersWithModifyEulers() {
        
        if earth.yawModify == 0.0 && earth.pitchModify == 0.0 && earth.rollModify == 0.0 {
            return
        }
        
        var quatLHS = simd_quatf()
        quatLHS.makeEulerRadians(yaw: earth.yawBase, pitch: earth.pitchBase, roll: earth.rollBase)
        
        var quatMHS = simd_quatf()
        quatMHS.makeEulerRadians(yaw: earth.yawModify, pitch: earth.pitchModify, roll: earth.rollModify)
        
        var quatRHS = simd_quatf()
        quatRHS.makeEulerRadians(yaw: earth.yawRotate, pitch: earth.pitchRotate, roll: earth.rollRotate)
        
        let quat = quatLHS * quatMHS * quatRHS
        let eulers = quat.eulersRadians()
        
        earth.yawBase = eulers.x
        earth.pitchBase = eulers.y
        earth.rollBase = eulers.z
        
        earth.yawModify = 0.0
        earth.pitchModify = 0.0
        earth.rollModify = 0.0
        
        earth.yawRotate = 0.0
        earth.pitchRotate = 0.0
        earth.rollRotate = 0.0
    }
}

extension GestureProcessor: GestureViewDelegate {
    
    func panBegan(position: simd_float2) {
        anyGestureBegan(position: position)
    }
    
    func panUpdated(position: simd_float2) {
        anyGestureUpdated(position: position)
    }
    
    func panEnded(position: simd_float2) {
        isPanning = false
    }
    
    func pinchBegan(position: simd_float2) {
        pinchGestureBegan(position: position)
        anyGestureBegan(position: position)
    }
    
    func pinchUpdated(position: simd_float2, scale: Float) {
        pinchGestureUpdated(position: position, scale: scale)
        anyGestureUpdated(position: position)
    }
    
    func pinchEnded(position: simd_float2, scale: Float) {
        isPinching = false
    }
    
    func rotateBegan(position: simd_float2) {
        rotateGestureBegan(position: position)
        anyGestureBegan(position: position)
    }
    
    func rotateUpdated(position: simd_float2, rotation: Float) {
        rotateGestureUpdated(position: position, rotation: rotation)
        anyGestureUpdated(position: position)
    }
    
    func rotateEnded(position: simd_float2, rotation: Float) {
        isRotating = false
    }
}
