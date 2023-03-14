//
//  Face.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/21/23.
//


import Foundation
import Metal
import simd

class Face {
    
    private(set) var texture: MTLTexture?
    
    private(set) var textureU_Start: Float = 0.0
    private(set) var textureU_End: Float = 1.0
    private(set) var textureV_Start: Float = 0.0
    private(set) var textureV_End: Float = 1.0
    
    var vertices: [Float] = [Float](repeating: 0.0, count: 5 * 4)
    var indices: [UInt16] = [0, 1, 2, 2, 1, 3]
    
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    
    func load(graphics: Graphics,
              indexH: Int,
              indexV: Int,
              sphere: UnitPointSphere,
              texture: MTLTexture,
              textureU_Start: Float,
              textureU_End: Float,
              textureV_Start: Float,
              textureV_End: Float) {

        self.texture = texture
        self.textureU_Start = textureU_Start
        self.textureU_End = textureU_End
        self.textureV_Start = textureV_Start
        self.textureV_End = textureV_End
        
        let point1 = sphere.points[indexH][indexV]
        let point2 = sphere.points[indexH + 1][indexV]
        let point3 = sphere.points[indexH][indexV + 1]
        let point4 = sphere.points[indexH + 1][indexV + 1]
        
        setVertex1(x: point1.x, y: point1.y, z: point1.z, u: textureU_Start, v: textureV_Start)
        setVertex2(x: point2.x, y: point2.y, z: point2.z, u: textureU_End, v: textureV_Start)
        setVertex3(x: point3.x, y: point3.y, z: point3.z, u: textureU_Start, v: textureV_End)
        setVertex4(x: point4.x, y: point4.y, z: point4.z, u: textureU_End, v: textureV_End)
        
        vertexBuffer = graphics.buffer(array: vertices)
        indexBuffer = graphics.buffer(array: indices)
    }
    
    private func setVertex1(x: Float, y: Float, z: Float, u: Float, v: Float) {
        let offset = 0
        vertices[offset + 0] = x
        vertices[offset + 1] = y
        vertices[offset + 2] = z
        vertices[offset + 3] = u
        vertices[offset + 4] = v
    }
    
    private func setVertex2(x: Float, y: Float, z: Float, u: Float, v: Float) {
        let offset = 5
        vertices[offset + 0] = x
        vertices[offset + 1] = y
        vertices[offset + 2] = z
        vertices[offset + 3] = u
        vertices[offset + 4] = v
    }
    
    private func setVertex3(x: Float, y: Float, z: Float, u: Float, v: Float) {
        let offset = 10
        vertices[offset + 0] = x
        vertices[offset + 1] = y
        vertices[offset + 2] = z
        vertices[offset + 3] = u
        vertices[offset + 4] = v
    }
    
    private func setVertex4(x: Float, y: Float, z: Float, u: Float, v: Float) {
        let offset = 15
        vertices[offset + 0] = x
        vertices[offset + 1] = y
        vertices[offset + 2] = z
        vertices[offset + 3] = u
        vertices[offset + 4] = v
    }
    
    func draw3D(graphics: Graphics,
                renderEncoder: MTLRenderCommandEncoder) {

        graphics.setVertexDataBuffer(vertexBuffer, renderEncoder: renderEncoder)
        graphics.setFragmentTexture(texture, renderEncoder: renderEncoder)

        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: indices.count,
                                            indexType: .uint16,
                                            indexBuffer: indexBuffer,
                                            indexBufferOffset: 0)
    }
    
}
