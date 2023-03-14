//
//  EarthScene.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/21/23.
//

import Foundation
import Metal
import simd

class EarthScene: GraphicsDelegate {
    var graphics: Graphics!
    
    let earth = Earth()
    let earthCamera = Camera()
    
    let earthTileFactory = TileFactory()
    let starsTileFactory = TileFactory()
    
    let stars = Stars()
    let starsCamera = Camera()
    
    
    let dimensionBridge = DimensionBridge()
    let cameraCalibrationTool = CameraCalibrationTool()
    let zoomTable = ZoomTable()
    
    let recyclerShapeQuad2D = RecyclerShapeQuad2D()
    let recyclerShapeQuad3D = RecyclerShapeQuad3D()
    
    var radius: Float = 128.0
    
    weak var gestureView: GestureView?
    
    var previousWidth: Float = 0.0
    var previousHeight: Float = 0.0
    
    lazy var gestureProcessor: GestureProcessor = {
        GestureProcessor(earth: earth,
                         scene: self,
                         dimensionBridge: dimensionBridge)
    }()
    
    func load() {
        
        earthTileFactory.load(graphics: graphics,
                              textureGridWidth: 4,
                              textureGridHeight: 2,
                              baseFileName: "earth_tile_",
                              leadingZeroes: 0)
        
        starsTileFactory.load(graphics: graphics,
                              textureGridWidth: 4,
                              textureGridHeight: 2,
                              baseFileName: "star_tile_",
                              leadingZeroes: 0)
        
        
        
        earthCamera.load(graphics: graphics)
        starsCamera.load(graphics: graphics)
        
        let cameraStartDistance = cameraCalibrationTool.calibrate(graphics: graphics,
                                                                  camera: earthCamera,
                                                                  radius: CameraCalibrationTool.earthRestingRadius(graphics: graphics))
        
        earthCamera.distance = cameraStartDistance
        earthCamera.compute()
        
        
        starsCamera.distance = cameraCalibrationTool.calibrate(graphics: graphics,
                                                               camera: earthCamera,
                                                               radius: CameraCalibrationTool.starsRestingRadius(graphics: graphics))
        starsCamera.compute()
        
        radius = cameraCalibrationTool.estimateRadius(graphics: graphics,
                                                      camera: earthCamera)
        computeZoomValues()
        
        earth.zoom = zoomTable.zoom(distance: cameraStartDistance)
        
        dimensionBridge.load(graphics: graphics,
                             camera: earthCamera)
        
        earth.load(graphics: graphics,
                   tileFactory: earthTileFactory,
                   camera: earthCamera)
        
        stars.load(graphics: graphics,
                   tileFactory: starsTileFactory,
                   camera: starsCamera,
                   earth: earth)
        
        gestureProcessor.load(graphics: graphics)
        
        NotificationCenter.default.addObserver(self, selector: #selector(receive(notification:)),
                                               name: NSNotification.Name("camera.twiddle"),
                                               object: nil)
    }
    
    @objc func receive(notification: Notification) {
        if let dict = notification.object as? [String: Float] {
            if let rp = dict["rp"] {
                earthCamera.rotationPrimary = rp
            }
            if let rs = dict["rs"] {
                earthCamera.rotationSecondary = rs
            }
            
            if let zo = dict["zo"] {
                earthCamera.distance = zoomTable.distance(zoom: zo)
            }
        }
    }
    
    func update() {
        
        if graphics.width != previousWidth || graphics.height != previousHeight {
            previousWidth = graphics.width
            previousHeight = graphics.height
            computeZoomValues()
            
            starsCamera.distance = cameraCalibrationTool.calibrate(graphics: graphics,
                                                                   camera: earthCamera,
                                                                   radius: CameraCalibrationTool.starsRestingRadius(graphics: graphics))
            starsCamera.compute()
        }
        
        earthCamera.distance = zoomTable.distance(zoom: earth.zoom)
        
        radius = cameraCalibrationTool.estimateRadius(graphics: graphics,
                                                      camera: earthCamera)
        
        gestureView?.update()
        gestureProcessor.update()
        
        earthCamera.compute()
        
        dimensionBridge.refresh()
        
        earth.update()
        
        //let _ = dimensionBridge.convert(point: gestureProcessor.center)
    }
    
    func draw3D(renderEncoder: MTLRenderCommandEncoder) {
        
        recyclerShapeQuad3D.reset()
        
        
        graphics.set(depthState: .disabled, renderEncoder: renderEncoder)
        renderEncoder.setCullMode(.front)
        stars.draw3D(graphics: graphics,
                     renderEncoder: renderEncoder)
        
        graphics.set(depthState: .lessThan, renderEncoder: renderEncoder)
        renderEncoder.setCullMode(.back)
        earth.draw3D(graphics: graphics,
                     renderEncoder: renderEncoder)
        
    }
    
    func draw2D(renderEncoder: MTLRenderCommandEncoder) {
        
        /*
        recyclerShapeQuad2D.reset()
        
        earth.draw2D(graphics: graphics,
                     renderEncoder: renderEncoder)
        
        dimensionBridge.drawQuads2D(recyclerShapeQuad2D: recyclerShapeQuad2D,
                                    renderEncoder: renderEncoder)
        dimensionBridge.drawLines2D(recyclerShapeQuad2D: recyclerShapeQuad2D,
                                    renderEncoder: renderEncoder)
        dimensionBridge.drawHits2D(recyclerShapeQuad2D: recyclerShapeQuad2D,
                                   renderEncoder: renderEncoder)
        
        gestureProcessor.draw2D(graphics: graphics,
                                recyclerShapeQuad2D: recyclerShapeQuad2D,
                                renderEncoder: renderEncoder)
        */
        
    }
    
    func computeZoomValues() {
        
        let earthRestingRadius = CameraCalibrationTool.earthRestingRadius(graphics: graphics)

        let minRadius = earthRestingRadius * 0.5
        let maxRadius = earthRestingRadius * 2.5
        
        var distances = [Float](repeating: 0.0, count: ZoomTable.size)
        
        for index in 0..<ZoomTable.size {
            let percent = Float(index) / Float(ZoomTable.size - 1)
            
            let radius = minRadius + (maxRadius - minRadius) * percent
            let distance = cameraCalibrationTool.calibrate(graphics: graphics,
                                                           camera: earthCamera,
                                                           radius: radius)
            distances[index] = distance
        }
        zoomTable.refresh(distances: distances)
    }
}
