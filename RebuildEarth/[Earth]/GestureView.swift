//
//  GestureView.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/22/23.
//

import UIKit
import simd

protocol GestureViewDelegate: AnyObject {
    func panBegan(position: simd_float2)
    func panUpdated(position: simd_float2)
    func panEnded(position: simd_float2)
    
    func pinchBegan(position: simd_float2)
    func pinchUpdated(position: simd_float2, scale: Float)
    func pinchEnded(position: simd_float2, scale: Float)
    
    func rotateBegan(position: simd_float2)
    func rotateUpdated(position: simd_float2, rotation: Float)
    func rotateEnded(position: simd_float2, rotation: Float)
}

class GestureView: UIView {
    
    private(set) var point = simd_float2(0.0, 0.0)
    private(set) var scale = Float(1.0)
    private(set) var rotation = Float(0.0)

    private(set) var startRotation = Float(0.0)
    private(set) var startScale = Float(1.0)
    
    private(set) var gestureCancelTimer = 0
    
    weak var delegate: GestureViewDelegate?
    
    var recognizerPanTouchCount = 0
    var recognizerPinchTouchCount = 0
    var recognizerRotationTouchCount = 0
    
    var recognizerPanActive = false
    var recognizerPinchActive = false
    var recognizerRotationActive = false
    
    private(set) lazy var recognizerPan: UIPanGestureRecognizer = {
        let result = UIPanGestureRecognizer(target: self, action: #selector(Self.pan(_:)))
        result.delegate = self
        return result
    }()

    private(set) lazy var recognizerPinch: UIPinchGestureRecognizer = {
        let result = UIPinchGestureRecognizer(target: self, action: #selector(Self.pinch(_:)))
        result.delegate = self
        return result
    }()

    private(set) lazy var recognizerRotation: UIRotationGestureRecognizer = {
        let result = UIRotationGestureRecognizer(target: self, action: #selector(Self.rotate(_:)))
        result.delegate = self
        return result
    }()
    
    func update() {
        if gestureCancelTimer > 0 {
            gestureCancelTimer -= 1
            if gestureCancelTimer == 0 {
                recognizerPan.isEnabled = true
                recognizerPinch.isEnabled = true
                recognizerRotation.isEnabled = true
            }
        }
    }
    
    func load(graphics: Graphics) {
        addGestureRecognizer(recognizerPan)
        addGestureRecognizer(recognizerPinch)
        addGestureRecognizer(recognizerRotation)
        
        point = simd_float2(graphics.width * 0.5, graphics.height * 0.5)
    }
    
    @objc func pan(_ panGestureRecognizer: UIPanGestureRecognizer) -> Void {
        let locationCG = panGestureRecognizer.location(in: self)
        let location = simd_float2(Float(locationCG.x), Float(locationCG.y))
        
        switch recognizerPan.state {
        case .began:
            recognizerPanActive = true
            gestureBegan(center: location)
            recognizerPanTouchCount = recognizerPan.numberOfTouches
            delegate?.panBegan(position: location)
            break
        case .changed:
            if recognizerPanTouchCount != recognizerPan.numberOfTouches {
                recognizerPanActive = true
                if recognizerPan.numberOfTouches > recognizerPanTouchCount {
                    recognizerPanTouchCount = recognizerPan.numberOfTouches
                    gestureBegan(center: location)
                    delegate?.panBegan(position: location)
                }
                else {
                    //If the user lifted a finger, cancel everything to prevent dramatic hops.
                    delegate?.rotateEnded(position: location, rotation: rotation)
                    delegate?.pinchEnded(position: location, scale: scale)
                    delegate?.panEnded(position: location)
                    cancelAllGestureRecognizers()
                }
            }
            break
        default:
            // If the gesture finished, cancel everything to prevent dramatic hops.
            delegate?.rotateEnded(position: location, rotation: rotation)
            delegate?.pinchEnded(position: location, scale: scale)
            delegate?.panEnded(position: location)
            cancelAllGestureRecognizers()
            break
        }
        if allowUpdateTransform() {
            gestureUpdate(center: location)
            delegate?.panUpdated(position: location)
        }
    }
    
    @objc func pinch(_ pinchGestureRecognizer: UIPinchGestureRecognizer) -> Void {
        let locationCG = pinchGestureRecognizer.location(in: self)
        let location = simd_float2(Float(locationCG.x), Float(locationCG.y))
        
        switch recognizerPinch.state {
        case .began:
            if allowUpdateTransform() {
                recognizerPinchActive = true
                gestureBegan(center: location)
                startScale = scale
                recognizerPinchTouchCount = recognizerPinch.numberOfTouches
                delegate?.pinchBegan(position: location)
            }
            break
        case .changed:
            recognizerPinchActive = true
            if recognizerPinchTouchCount != recognizerPinch.numberOfTouches {
                if recognizerPinch.numberOfTouches > recognizerPinchTouchCount {
                    recognizerPinchTouchCount = recognizerPinch.numberOfTouches
                    gestureBegan(center: location)
                    delegate?.pinchBegan(position: location)
                }
                else {
                    // If the user lifted a finger, cancel everything to prevent dramatic hops.
                    delegate?.rotateEnded(position: location, rotation: rotation)
                    delegate?.pinchEnded(position: location, scale: scale)
                    delegate?.panEnded(position: location)
                    cancelAllGestureRecognizers()
                }
            }
            break
        default:
            // If the gesture finished, cancel everything to prevent dramatic hops.
            delegate?.rotateEnded(position: location, rotation: rotation)
            delegate?.pinchEnded(position: location, scale: scale)
            delegate?.panEnded(position: location)
            cancelAllGestureRecognizers()
            break
        }
        if allowUpdateTransform() {
            scale = startScale * Float(recognizerPinch.scale)
            gestureUpdate(center: location)
            delegate?.pinchUpdated(position: location, scale: scale)
        }
    }
    
    @objc func rotate(_ rotationGestureRecognizer: UIRotationGestureRecognizer) -> Void {
        let locationCG = rotationGestureRecognizer.location(in: self)
        let location = simd_float2(Float(locationCG.x), Float(locationCG.y))
        
        switch recognizerRotation.state {
        case .began:
            if allowUpdateTransform() {
                recognizerRotationActive = true
                gestureBegan(center: location)
                startRotation = rotation
                recognizerRotationTouchCount = recognizerRotation.numberOfTouches
                delegate?.rotateBegan(position: location)
            }
            break
        case .changed:
            recognizerRotationActive = true
            if recognizerRotationTouchCount != recognizerRotation.numberOfTouches {
                if recognizerRotation.numberOfTouches > recognizerRotationTouchCount {
                    recognizerRotationTouchCount = recognizerRotation.numberOfTouches
                    gestureBegan(center: location)
                    delegate?.rotateBegan(position: location)
                }
                else {
                    // If the user lifted a finger, cancel everything to prevent dramatic hops.
                    delegate?.rotateEnded(position: location, rotation: rotation)
                    delegate?.pinchEnded(position: location, scale: scale)
                    delegate?.panEnded(position: location)
                    cancelAllGestureRecognizers()
                }
            }
            break
        default:
            // If the gesture finished, cancel everything to prevent dramatic hops.
            delegate?.rotateEnded(position: location, rotation: rotation)
            delegate?.pinchEnded(position: location, scale: scale)
            delegate?.panEnded(position: location)
            cancelAllGestureRecognizers()
            break
        }
        
        if allowUpdateTransform() {
            rotation = startRotation + Float(recognizerRotation.rotation)
            gestureUpdate(center: location)
            delegate?.rotateUpdated(position: location, rotation: rotation)
        }
    }
    
    func allowUpdateTransform() -> Bool {
        if gestureCancelTimer > 0 {
            return false
        }
        return true
    }
    
    func gestureBegan(center: simd_float2) {
        point = center
        recognizerPinch.scale = 1.0
        recognizerRotation.rotation = 0.0
        recognizerPan.setTranslation(CGPoint.zero, in: self)
        startScale = scale
        startRotation = rotation
    }
    
    func gestureUpdate(center: simd_float2) {
        self.point = center
    }
    
    func cancelAllGestureRecognizers() {
        gestureCancelTimer = 3
        
        recognizerPan.isEnabled = false
        recognizerPinch.isEnabled = false
        recognizerRotation.isEnabled = false
        
        recognizerPanActive = false
        recognizerPinchActive = false
        recognizerRotationActive = false
        
        rotation = 0.0
        scale = 1.0
    }
}

extension GestureView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureCancelTimer > 0 {
            return false
        }
        return true
    }
 }

