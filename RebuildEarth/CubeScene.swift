//
//  CubeScene.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/12/23.
//

import Foundation
import Metal
import simd

class CubeScene: GraphicsDelegate {
    var graphics: Graphics!
    
    private let positionsFront: [Float] = [-0.5, -0.5, 0.5,
                                            -0.5, 0.5, 0.5,
                                            0.5, -0.5, 0.5,
                                            0.5, -0.5, 0.5,
                                            -0.5, 0.5, 0.5,
                                            0.5, 0.5, 0.5]
        
    private let positionsBack: [Float] = [-0.5, 0.5, -0.5,
                                           -0.5, -0.5, -0.5,
                                           0.5, -0.5, -0.5,
                                           -0.5, 0.5, -0.5,
                                           0.5, -0.5, -0.5,
                                           0.5, 0.5, -0.5]

    private let positionsTop: [Float] = [-0.5, -0.5, -0.5,
                                          -0.5, -0.5, 0.5,
                                          0.5, -0.5, -0.5,
                                          -0.5, -0.5, 0.5,
                                          0.5, -0.5, 0.5,
                                          0.5, -0.5, -0.5]

    private let positionsBottom: [Float] = [-0.5, 0.5, 0.5,
                                             -0.5, 0.5, -0.5,
                                             0.5, 0.5, -0.5,
                                             0.5, 0.5, 0.5,
                                             -0.5, 0.5, 0.5,
                                             0.5, 0.5, -0.5]

    private let positionsRight: [Float] = [0.5, -0.5, -0.5,
                                           0.5, -0.5, 0.5,
                                           0.5, 0.5, -0.5,
                                           0.5, -0.5, 0.5,
                                           0.5, 0.5, 0.5,
                                           0.5, 0.5, -0.5]

    private let positionsLeft: [Float] = [-0.5, -0.5, 0.5,
                                           -0.5, -0.5, -0.5,
                                           -0.5, 0.5, -0.5,
                                           -0.5, 0.5, 0.5,
                                           -0.5, -0.5, 0.5,
                                           -0.5, 0.5, -0.5]
    
    private(set) var positionsBufferFont: MTLBuffer!
    private(set) var positionsBufferBack: MTLBuffer!
    private(set) var positionsBufferTop: MTLBuffer!
    private(set) var positionsBufferBottom: MTLBuffer!
    private(set) var positionsBufferRight: MTLBuffer!
    private(set) var positionsBufferLeft: MTLBuffer!
    
    private(set) var uniformFragmentFront = UniformsShapeFragment()
    private(set) var uniformFragmentBack = UniformsShapeFragment()
    private(set) var uniformFragmentTop = UniformsShapeFragment()
    private(set) var uniformFragmentBottom = UniformsShapeFragment()
    private(set) var uniformFragmentRight = UniformsShapeFragment()
    private(set) var uniformFragmentLeft = UniformsShapeFragment()
    
    private(set) var uniformFragmentFrontBuffer: MTLBuffer!
    private(set) var uniformFragmentBackBuffer: MTLBuffer!
    private(set) var uniformFragmentTopBuffer: MTLBuffer!
    private(set) var uniformFragmentBottomBuffer: MTLBuffer!
    private(set) var uniformFragmentRightBuffer: MTLBuffer!
    private(set) var uniformFragmentLeftBuffer: MTLBuffer!
    
    
    private(set) var uniformVertex = UniformsShapeVertex()
    private(set) var uniformVertexBuffer: MTLBuffer!
    
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    
    func update() {
        rotationX -= -2.5
        if rotationX < 0.0 { rotationX += 360.0 }

        rotationY += 1.75
        if rotationY > 360.0 { rotationY -= 360.0 }

        rotationZ += 0.65
        if rotationZ > 360.0 { rotationZ -= 360.0 }
    }
    
    func load() {
        
        uniformFragmentFront.set(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        uniformFragmentBack.set(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.5)
        uniformFragmentTop.set(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5)
        uniformFragmentBottom.set(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.5)
        uniformFragmentRight.set(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.5)
        uniformFragmentLeft.set(red: 1.0, green: 1.0, blue: 0.0, alpha: 0.5)
        
        self.positionsBufferFont = graphics.buffer(array: positionsFront)
        self.positionsBufferBack = graphics.buffer(array: positionsBack)
        self.positionsBufferTop = graphics.buffer(array: positionsTop)
        self.positionsBufferBottom = graphics.buffer(array: positionsBottom)
        self.positionsBufferRight = graphics.buffer(array: positionsRight)
        self.positionsBufferLeft = graphics.buffer(array: positionsLeft)
        
        self.uniformFragmentFrontBuffer = graphics.buffer(uniform: uniformFragmentFront)
        self.uniformFragmentBackBuffer = graphics.buffer(uniform: uniformFragmentBack)
        self.uniformFragmentTopBuffer = graphics.buffer(uniform: uniformFragmentTop)
        self.uniformFragmentBottomBuffer = graphics.buffer(uniform: uniformFragmentBottom)
        self.uniformFragmentRightBuffer = graphics.buffer(uniform: uniformFragmentRight)
        self.uniformFragmentLeftBuffer = graphics.buffer(uniform: uniformFragmentLeft)
        
        self.uniformVertexBuffer = graphics.buffer(uniform: uniformVertex)
    }
    
    func draw3D(renderEncoder: MTLRenderCommandEncoder) {
        
        graphics.set(pipelineState: .shape3DNoBlending, renderEncoder: renderEncoder)
        graphics.set(depthState: .lessThan, renderEncoder: renderEncoder)
        
        
        
        let aspect = graphics.width / graphics.height

        var perspective = matrix_float4x4()
        perspective.perspective(fovy: Float.pi * 0.125, aspect: aspect, nearZ: 0.01, farZ: 255.0)

        var lookAt = matrix_float4x4()
        lookAt.lookAt(eyeX: 0.0, eyeY: 0.0, eyeZ: 10.0,
                      centerX: 0.0, centerY: 0.0, centerZ: 0.0,
                      upX: 0.0, upY: 1.0, upZ: 0.0)

         
        uniformVertex.projectionMatrix = simd_mul(perspective, lookAt)
        
        uniformVertex.modelViewMatrix = matrix_identity_float4x4
        uniformVertex.modelViewMatrix.rotateX(degrees: rotationX)
        uniformVertex.modelViewMatrix.rotateY(degrees: rotationY)
        uniformVertex.modelViewMatrix.rotateZ(degrees: rotationZ)

        graphics.write(buffer: uniformVertexBuffer, uniform: uniformVertex)
        
        /*
        
        
        
        */
        
        //uniformVertex.modelViewMatrix = matrix_identity_float4x4
        //uniformVertex.modelViewMatrix.rotateX(degrees: rotationX)
        //uniformVertex.modelViewMatrix.rotateY(degrees: rotationY)
        //uniformVertex.modelViewMatrix.rotateZ(degrees: rotationZ)
        
        
        
        
        
        

        graphics.setVertexUniformsBuffer(uniformVertexBuffer, renderEncoder: renderEncoder)

        graphics.setFragmentUniformsBuffer(uniformFragmentFrontBuffer, renderEncoder: renderEncoder)
        graphics.setVertexPositionsBuffer(positionsBufferFont, renderEncoder: renderEncoder)
        renderEncoder
          .drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)

        graphics.setFragmentUniformsBuffer(uniformFragmentBackBuffer, renderEncoder: renderEncoder)
        graphics.setVertexPositionsBuffer(positionsBufferBack, renderEncoder: renderEncoder)
        renderEncoder
          .drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)

        graphics.setFragmentUniformsBuffer(uniformFragmentTopBuffer, renderEncoder: renderEncoder)
        graphics.setVertexPositionsBuffer(positionsBufferTop, renderEncoder: renderEncoder)
        renderEncoder
          .drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)

        graphics.setFragmentUniformsBuffer(uniformFragmentBottomBuffer, renderEncoder: renderEncoder)
        graphics.setVertexPositionsBuffer(positionsBufferBottom, renderEncoder: renderEncoder)
        renderEncoder
          .drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)

        graphics.setFragmentUniformsBuffer(uniformFragmentRightBuffer, renderEncoder: renderEncoder)
        graphics.setVertexPositionsBuffer(positionsBufferRight, renderEncoder: renderEncoder)
        renderEncoder
          .drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)

        graphics.setFragmentUniformsBuffer(uniformFragmentLeftBuffer, renderEncoder: renderEncoder)
        graphics.setVertexPositionsBuffer(positionsBufferLeft, renderEncoder: renderEncoder)
        renderEncoder
          .drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: 1)
        
        
    }
    
    func draw2D(renderEncoder: MTLRenderCommandEncoder) {
        
    }
    
}
