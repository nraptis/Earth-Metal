//
//  Earth.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/21/23.
//

import Foundation
import Metal
import simd

class Earth {
    
    static let tileCountV = 40
    static let tileCountH = 40
    
    let rcy = RecyclerShapeQuad3D()
    
    let sphere = UnitPointSphere()
    var camera: Camera!
    private(set) var faces = [[Face]]()
    
    private var uniformVertex = UniformsSpriteNodeIndexedVertex()
    private var uniformFragment = UniformsSpriteNodeIndexedFragment()

    private var uniformVertexBuffer: MTLBuffer!
    private var uniformFragmentBuffer: MTLBuffer!
    
    var yawBase: Float = 0.0
    var pitchBase: Float = 0.0
    var rollBase: Float = 0.0
    
    var yawModify: Float = 0.0
    var pitchModify: Float = 0.0
    var rollModify: Float = 0.0
    
    var yawRotate: Float = 0.0
    var pitchRotate: Float = 0.0
    var rollRotate: Float = 0.0
    
    var zoom: Float = 3.0
    
    func load(graphics: Graphics, tileFactory: TileFactory, camera: Camera) {
        self.camera = camera
        sphere.load(tileCountH: Self.tileCountH, tileCountV: Self.tileCountV)
        
        guard tileFactory.textures.count > 0 else {
            print("invalid grid")
            return
        }

        guard tileFactory.textures[0].count > 0 else {
            print("invalid grid")
            return
        }

        let textureGridWidth = tileFactory.width
        let textureGridHeight = tileFactory.height

        guard textureGridWidth > 0 else {
            print("textureGridWidth: \(textureGridWidth), illegal")
            return
        }

        guard textureGridHeight > 0 else {
            print("textureGridHeight: \(textureGridHeight), illegal")
            return
        }

        guard (Self.tileCountH % textureGridWidth) == 0 else {
            print("tile count h: \(Self.tileCountH) not compatable with textureGridWidth: \(textureGridWidth)")
            return
        }

        guard (Self.tileCountV % textureGridHeight) == 0 else {
            print("tile count v: \(Self.tileCountV) not compatable with textureGridHeight: \(textureGridHeight)")
            return
        }

        let textureCountH = Self.tileCountH / textureGridWidth
        let textureCountV = Self.tileCountV / textureGridHeight
        
        faces = [[Face]](repeating: [Face](), count: Self.tileCountH)
        for x in 0..<Self.tileCountH {
            faces[x].reserveCapacity(Self.tileCountV)
            for _ in 0..<Self.tileCountV {
                faces[x].append(Face())
            }
        }
        
        var indexV = 0
        var textureIndexV = 0
        var textureStepV = 0
        while indexV < Self.tileCountV {
            
            let textureV_Start = Float(textureStepV) / Float(textureCountV)
            let textureV_End = Float(textureStepV + 1) / Float(textureCountV)
            
            var indexH = 0
            var textureIndexH = 0
            var textureStepH = 0
            while indexH < Self.tileCountH {
                
                guard let texture = tileFactory.texture(x: textureIndexH,
                                                        y: textureIndexV) else {
                    print("Could not pull texture (\(textureIndexH), \(textureIndexV)) from factory (\(tileFactory.width) x \(tileFactory.height))")
                    return
                }
                
                let textureU_Start = Float(textureStepH) / Float(textureCountH)
                let textureU_End = Float(textureStepH + 1) / Float(textureCountH)
                
                let face = faces[indexH][indexV]
                
                face.load(graphics: graphics,
                          indexH: indexH,
                          indexV: indexV,
                          sphere: sphere,
                          texture: texture,
                          textureU_Start: textureU_Start,
                          textureU_End: textureU_End,
                          textureV_Start: textureV_Start,
                          textureV_End: textureV_End)
                
                textureStepH += 1
                if textureStepH == textureCountH {
                    textureIndexH += 1
                    textureStepH = 0
                }
                indexH += 1
            }
            
            indexV += 1
            textureStepV += 1
            if textureStepV == textureCountV {
                textureIndexV += 1
                textureStepV = 0
            }
        }
        
        uniformVertexBuffer = graphics.buffer(uniform: uniformVertex)
        uniformFragmentBuffer = graphics.buffer(uniform: uniformFragment)
    }
    
    func update() {
        
    }
    
    func draw3D(graphics: Graphics,
                renderEncoder: MTLRenderCommandEncoder) {
        
        
        graphics.set(pipelineState: .spriteNodeIndexed3DNoBlending, renderEncoder: renderEncoder)
        graphics.set(samplerState: .linearClamp, renderEncoder: renderEncoder)
        
        uniformVertex.projectionMatrix = camera.projection
        uniformVertex.modelViewMatrix = transformMatrix()
        
        graphics.write(buffer: uniformVertexBuffer, uniform: uniformVertex)
        graphics.write(buffer: uniformFragmentBuffer, uniform: uniformFragment)
        
        graphics.setVertexUniformsBuffer(uniformVertexBuffer, renderEncoder: renderEncoder)
        graphics.setFragmentUniformsBuffer(uniformFragmentBuffer, renderEncoder: renderEncoder)
        
        for x in 0..<Self.tileCountH {
            for y in 0..<Self.tileCountV {
                faces[x][y].draw3D(graphics: graphics,
                                   renderEncoder: renderEncoder)
            }
        }
         
    }
    
    func draw2D(graphics: Graphics,
                renderEncoder: MTLRenderCommandEncoder) {
        
    }
    
    func transformMatrix() -> matrix_float4x4 {
        
        var quatLHS = simd_quatf()
        quatLHS.makeEulerRadians(yaw: yawBase, pitch: pitchBase, roll: rollBase)
        
        var quatMHS = simd_quatf()
        quatMHS.makeEulerRadians(yaw: yawModify, pitch: pitchModify, roll: rollModify)
        
        var quatRHS = simd_quatf()
        quatRHS.makeEulerRadians(yaw: yawRotate, pitch: pitchRotate, roll: rollRotate)
        
        let quat = quatLHS * quatMHS * quatRHS
        
        return matrix_float4x4(quat)
    }
    
}
