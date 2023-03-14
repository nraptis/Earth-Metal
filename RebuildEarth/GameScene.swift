//
//  GameScene.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/10/23.
//

import Foundation
import Metal
import simd

class GameScene: GraphicsDelegate {
    var graphics: Graphics!
    
    func update() {
        
    }
    
    var diamond: MTLTexture?
    var diamondSprite = Sprite2D()
    
    
    
    func load() {
        diamond = graphics.loadTexture(fileName: "diamond.png")
        diamondSprite.load(graphics: graphics, fileName: "diamond.png")
    }
    
    let recyclerShapeTriangle3D = RecyclerShapeTriangle3D()
    let recyclerShapeQuad3D = RecyclerShapeQuad3D()
    
    func draw3D(renderEncoder: MTLRenderCommandEncoder) {
        
        drawQuad3DTest(renderEncoder: renderEncoder)
        drawTriangle3DTest(renderEncoder: renderEncoder)
        
        drawSprites3D(renderEncoder: renderEncoder)
        
        drawShapeNode3DTest(renderEncoder: renderEncoder)
        
        drawShapeNodeColored3DTest(renderEncoder: renderEncoder)
        
        testDrawIndexedSprite3D(renderEncoder: renderEncoder)
        
        testDrawIndexedSpriteColored3D(renderEncoder: renderEncoder)
        
    }
    
    func drawShapeNodeColored3DTest(renderEncoder: MTLRenderCommandEncoder) {
        
        struct RainbowNode {
            let x: Float
            let y: Float
            let z: Float
            
            let r: Float
            let g: Float
            let b: Float
            let a: Float
        }
        
        var y: Float = 30.0
        let bottom = graphics.height - 60.0
        
        var px = 0
        
        var rsin: Float = Float.pi
        var gsin: Float = Float.pi * 3.0 / 2.0
        var bsin: Float = Float.pi / 2.0
        var asin: Float = Float.pi / 4.0
        
        
        while y < bottom {
            
            var nodes = [RainbowNode]()
            var indices = [Int16]()
            
            var x: Float = 20.0
            
            let right = graphics.width - 30.0
            var index: Int16 = 0
            while x < right {
                
                rsin += Float.pi / 7.0
                gsin += Float.pi / 8.0
                bsin += Float.pi / 6.0
                asin += Float.pi / 4.0
                
                var r = (sinf(rsin) + 1.0) / 2.0
                var g = (sinf(gsin) + 1.0) / 2.0
                var b = (sinf(bsin) + 1.0) / 2.0
                var a = (sinf(asin) + 1.0) / 2.0
                
                r = 0.25 + r * 0.5
                g = 0.15 + g * 0.7
                b = 0.25 + b * 0.5
                a = 0.5 + a * 0.5
                
                
                
                let twiddle = (x / right) * Float.pi * 4.0
                
                let sine = sinf(twiddle)
                
                let node1 = RainbowNode(x: x, y: y + sine * 12.0, z: 0.0, r: r, g: g, b: b, a: a)
                let node2 = RainbowNode(x: x, y: y + sine * 8.0 + 40.0, z: 0.0, r: r, g: g, b: b, a: a)
                
                nodes.append(node1)
                nodes.append(node2)
                
                indices.append(index)
                index += 1
                
                indices.append(index)
                index += 1
                
                x += 20.0
            }
            
            let nodesBuffer = graphics.buffer(array: nodes)
            
            var uniformsVertex = UniformsShapeVertex()
            uniformsVertex.projectionMatrix.ortho(width: graphics.width, height: graphics.height)
            let uniformsVertexBuffer = graphics.buffer(uniform: uniformsVertex)
            
            var uniformsFragment = UniformsShapeFragment()
            uniformsFragment.red = y / bottom
            uniformsFragment.green = 1.0 - (y / bottom)
            uniformsFragment.blue = 0.5
            uniformsFragment.alpha = 0.75
            let uniformsFragmentBuffer = graphics.buffer(uniform: uniformsFragment)
            
            let indexBuffer = graphics.buffer(array: indices)
            
            if px == 0 { graphics.set(pipelineState: .shapeNodeColoredIndexed3DNoBlending, renderEncoder: renderEncoder) }
            if px == 1 { graphics.set(pipelineState: .shapeNodeColoredIndexed3DAlphaBlending, renderEncoder: renderEncoder) }
            if px == 2 { graphics.set(pipelineState: .shapeNodeColoredIndexed3DAdditiveBlending, renderEncoder: renderEncoder) }
            if px == 3 { graphics.set(pipelineState: .shapeNodeColoredIndexed3DPremultipliedBlending, renderEncoder: renderEncoder) }
            
            
            graphics.setFragmentUniformsBuffer(uniformsFragmentBuffer, renderEncoder: renderEncoder)
            
            graphics.setVertexDataBuffer(nodesBuffer, renderEncoder: renderEncoder)
            graphics.setVertexUniformsBuffer(uniformsVertexBuffer, renderEncoder: renderEncoder)
            
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip,
                                                indexCount: indices.count,
                                                indexType: .uint16,
                                                indexBuffer: indexBuffer!,
                                                indexBufferOffset: 0)
            
            y += 70.0
            
            px += 1
            if px == 4 { px = 0 }
        }
    }
    
    
    func drawShapeNode3DTest(renderEncoder: MTLRenderCommandEncoder) {
        
        var y: Float = 60.0
        let bottom = graphics.height - 60.0
        
        var px = 0
        
        while y < bottom {
            
            var positions = [Float]()
            var indices = [Int16]()
            
            var x: Float = 30.0
            
            let right = graphics.width - 30.0
            var index: Int16 = 0
            while x < right {
                
                let twiddle = (x / right) * Float.pi * 4.0
                
                let sine = sinf(twiddle)
                
                positions.append(x)
                positions.append(y + sine * 8.0)
                positions.append(0.0)
                
                positions.append(x)
                positions.append(y + sine * 8.0 + 40.0)
                positions.append(0.0)
                
                indices.append(index)
                index += 1
                
                indices.append(index)
                index += 1
                
                x += 20.0
            }
            
            let positionsBuffer = graphics.buffer(array: positions)
            
            var uniformsVertex = UniformsShapeVertex()
            uniformsVertex.projectionMatrix.ortho(width: graphics.width, height: graphics.height)
            let uniformsVertexBuffer = graphics.buffer(uniform: uniformsVertex)
            
            var uniformsFragment = UniformsShapeFragment()
            uniformsFragment.red = y / bottom
            uniformsFragment.green = 1.0 - (y / bottom)
            uniformsFragment.blue = 0.5
            uniformsFragment.alpha = 0.75
            let uniformsFragmentBuffer = graphics.buffer(uniform: uniformsFragment)
            
            let indexBuffer = graphics.buffer(array: indices)
            
            if px == 0 { graphics.set(pipelineState: .shapeNodeIndexed3DNoBlending, renderEncoder: renderEncoder) }
            if px == 1 { graphics.set(pipelineState: .shapeNodeIndexed3DAlphaBlending, renderEncoder: renderEncoder) }
            if px == 2 { graphics.set(pipelineState: .shapeNodeIndexed3DAdditiveBlending, renderEncoder: renderEncoder) }
            if px == 3 { graphics.set(pipelineState: .shapeNodeIndexed3DPremultipliedBlending, renderEncoder: renderEncoder) }
            
            
            graphics.setFragmentUniformsBuffer(uniformsFragmentBuffer, renderEncoder: renderEncoder)
            
            graphics.setVertexDataBuffer(positionsBuffer, renderEncoder: renderEncoder)
            graphics.setVertexUniformsBuffer(uniformsVertexBuffer, renderEncoder: renderEncoder)
            
            renderEncoder.drawIndexedPrimitives(type: .triangleStrip,
                                                indexCount: indices.count,
                                                indexType: .uint16,
                                                indexBuffer: indexBuffer!,
                                                indexBufferOffset: 0)
            
            y += 70.0
            
            px += 1
            if px == 4 { px = 0 }
        }
    }
    
    func drawSprites3D(renderEncoder: MTLRenderCommandEncoder) {
        
        for xid in 0...1 {
            for yid in 0...1 {
                let startX: Float = xid == 0 ? 0.0 : graphics.width * 0.5
                let endX: Float = startX + graphics.width * 0.5
                
                let startY: Float = yid == 0 ? 0.0 : graphics.height * 0.5
                let endY: Float = startY + graphics.height * 0.5
                
                if xid == 0 {
                    if yid == 0 {
                        graphics.set(pipelineState: .sprite3DNoBlending, renderEncoder: renderEncoder)
                    } else {
                        graphics.set(pipelineState: .sprite3DAlphaBlending, renderEncoder: renderEncoder)
                    }
                } else {
                    if yid == 0 {
                        graphics.set(pipelineState: .sprite3DAdditiveBlending, renderEncoder: renderEncoder)
                    } else {
                        graphics.set(pipelineState: .sprite3DPremultipliedBlending, renderEncoder: renderEncoder)
                    }
                }
                
                let positions: [Float] = [startX, startY, 0.0,
                                          endX, startY, 0.0,
                                          startX, endY, 0.0,
                                          endX, endY, 0.0]
                let positionsBuffer = graphics.buffer(array: positions)
                
                let textureCoords: [Float] = [0.0, 0.0, 2.0, 0.0, 0.0, 2.0, 2.0, 2.0]
                let textureCoordsBuffer = graphics.buffer(array: textureCoords)
                
                var uniformsVertex = UniformsSpriteVertex()
                uniformsVertex.projectionMatrix.ortho(width: graphics.width, height: graphics.height)
                let uniformsVertexBuffer = graphics.buffer(uniform: uniformsVertex)
                
                var uniformsFragment = UniformsSpriteFragment()
                uniformsFragment.red = 0.9
                uniformsFragment.green = 0.6
                uniformsFragment.blue = 0.75
                uniformsFragment.alpha = 0.75
                let uniformsFragmentBuffer = graphics.buffer(uniform: uniformsFragment)
                
                graphics.set(samplerState: .linearRepeat, renderEncoder: renderEncoder)
                
                graphics.setFragmentTexture(diamond, renderEncoder: renderEncoder)
                graphics.setFragmentUniformsBuffer(uniformsFragmentBuffer, renderEncoder: renderEncoder)
                
                graphics.setVertexPositionsBuffer(positionsBuffer, renderEncoder: renderEncoder)
                graphics.setVertexTextureCoordsBuffer(textureCoordsBuffer, renderEncoder: renderEncoder)
                
                graphics.setVertexUniformsBuffer(uniformsVertexBuffer, renderEncoder: renderEncoder)
                
                renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
                
            }
        }
    }
    
    static var q: Float = 0.0
    func drawQuad3DTest(renderEncoder: MTLRenderCommandEncoder) {
        
        recyclerShapeQuad3D.reset()
        
        graphics.set(depthState: .disabled, renderEncoder: renderEncoder)
        
        Self.q += 0.02
        if Self.q >= Float.pi * 2.0 {
            Self.q -= Float.pi * 2.0
        }
        
        var idx = 0
        var x: Float = 25.0
        while x < graphics.width - 100.0 {
            
            if idx == 0 {
                graphics.set(pipelineState: .shape3DNoBlending, renderEncoder: renderEncoder)
            } else if idx == 1 {
                graphics.set(pipelineState: .shape3DAlphaBlending, renderEncoder: renderEncoder)
            } else if idx == 2 {
                graphics.set(pipelineState: .shape3DAdditiveBlending, renderEncoder: renderEncoder)
            } else  {
                graphics.set(pipelineState: .shape3DNoBlending, renderEncoder: renderEncoder)
            }
            
            idx += 1
            if idx == 4 { idx = 0 }
            
            var y: Float = 25.0
            while y < graphics.height - 100.0 {
                
                let centerX = x + 25.0
                let centerY = y + 25.0
                
                var projection = matrix_float4x4()
                projection.ortho(width: graphics.width, height: graphics.height)
                
                var modelView = matrix_float4x4()
                modelView.translation(x: centerX, y: centerY, z: -25.0)
                modelView.rotateY(radians: Self.q + (y / graphics.height) * Float.pi + (x / graphics.width) * Float.pi)
                
                let red = (cosf(Float.pi + (y) / 200.0)) * 0.5
                let green = (cosf((x - Float.pi) / 200.0)) * 0.5
                let blue = (cosf((x + y - Float.pi * 0.5) / 200.0)) * 0.5
                
                recyclerShapeQuad3D.set(red: red, green: green, blue: blue, alpha: 0.75)
                
                recyclerShapeQuad3D.drawQuad(graphics: graphics, renderEncoder: renderEncoder,
                                             projection: projection, modelView: modelView,
                                             x1: -24.0, y1: -24.0, z1: 0.0,
                                             x2: 24.0, y2: -24.0, z2: 0.0,
                                             x3: -24.0, y3: 24.0, z3: 0.0,
                                             x4: 24.0, y4: 24.0, z4: 0.0)
                y += 50.0
            }
            x += 50.0
        }
    }
    
    
    static var f: Float = 0.0
    func drawTriangle3DTest(renderEncoder: MTLRenderCommandEncoder) {
        
        recyclerShapeTriangle3D.reset()
        
        Self.f += 0.01
        if Self.f >= Float.pi * 2.0 {
            Self.f -= Float.pi * 2.0
        }
        graphics.set(depthState: .disabled, renderEncoder: renderEncoder)
        
        var idx = 0
        var x: Float = 50.0
        while x < graphics.width - 100.0 {
            
            if idx == 0 {
                graphics.set(pipelineState: .shape3DNoBlending, renderEncoder: renderEncoder)
            } else if idx == 1 {
                graphics.set(pipelineState: .shape3DAlphaBlending, renderEncoder: renderEncoder)
            } else if idx == 2 {
                graphics.set(pipelineState: .shape3DAdditiveBlending, renderEncoder: renderEncoder)
            } else  {
                graphics.set(pipelineState: .shape3DNoBlending, renderEncoder: renderEncoder)
            }
            
            idx += 1
            if idx == 4 { idx = 0 }
            
            var y: Float = 50.0
            while y < graphics.height - 100.0 {
                
                let centerX = x + 25.0
                let centerY = y + 25.0
                
                var projection = matrix_float4x4()
                projection.ortho(width: graphics.width, height: graphics.height)
                
                var modelView = matrix_float4x4()
                modelView.translation(x: centerX, y: centerY, z: -25.0)
                modelView.rotateX(radians: Self.f + (y / graphics.height) * Float.pi + (x / graphics.width) * Float.pi)
                
                let red = (1.0 + sinf((x + y) / 200.0)) * 0.5
                let green = (1.0 + sinf((x) / 200.0)) * 0.5
                let blue = (1.0 + sinf((y) / 200.0)) * 0.5
                
                recyclerShapeTriangle3D.set(red: red, green: green, blue: blue, alpha: 0.75)
                
                recyclerShapeTriangle3D.drawTriangle(graphics: graphics, renderEncoder: renderEncoder,
                                                     projection: projection, modelView: modelView,
                                                     x1: -22.5, y1: -22.5, z1: 0.0,
                                                     x2: 22.0, y2: -22.5, z2: 0.0,
                                                     x3: 0.0, y3: 22.5, z3: 0.0)
                y += 50.0
            }
            x += 50.0
        }
    }
    
    
    let recyclerShapeTriangle2D = RecyclerShapeTriangle2D()
    let recyclerShapeQuad2D = RecyclerShapeQuad2D()
    let recyclerSprite2D = RecyclerSprite2D()
    
    func draw2D(renderEncoder: MTLRenderCommandEncoder) {
        
        return
        
        recyclerShapeQuad2D.reset()
        
        graphics.set(pipelineState: .shape2DAlphaBlending, renderEncoder: renderEncoder)

        var projection = matrix_float4x4()
        projection.ortho(width: graphics.width, height: graphics.height)

        let modelView = matrix_identity_float4x4
        
        recyclerShapeQuad2D.set(red: 1.0, green: 0.125, blue: 0.125, alpha: 0.65)
        recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                     projection: projection, modelView: modelView,
                                     p1: simd_float2(50.0, 50.0), p2: simd_float2(graphics.width - 50.0, 50.0))

        recyclerShapeQuad2D.set(red: 0.125, green: 1.0, blue: 0.125, alpha: 0.65)
        recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                     projection: projection, modelView: modelView,
                                     p1: simd_float2(graphics.width - 50.0, 50.0), p2: simd_float2(graphics.width - 50.0, graphics.height - 50.0))

        recyclerShapeQuad2D.set(red: 0.125, green: 0.125, blue: 1.0, alpha: 0.65)
        recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                     projection: projection, modelView: modelView,
                                     p1: simd_float2(50.0, 50.0), p2: simd_float2(50.0, graphics.height - 50.0))
        
        recyclerShapeQuad2D.set(red: 0.125, green: 0.5, blue: 0.85, alpha: 0.65)
        recyclerShapeQuad2D.drawLine(graphics: graphics, renderEncoder: renderEncoder,
                                     projection: projection, modelView: modelView,
                                     p1: simd_float2(50.0, graphics.height - 50.0), p2: simd_float2(graphics.width - 50.0, graphics.height - 50.0))
        
        recyclerShapeQuad2D.set(red: 1.0, green: 0.125, blue: 0.125, alpha: 0.65)
        recyclerShapeQuad2D.drawPoint(graphics: graphics, renderEncoder: renderEncoder,
                                      projection: projection, modelView: modelView,
                                      point: simd_float2(50.0, 50.0))


        recyclerShapeQuad2D.set(red: 0.125, green: 1.0, blue: 0.125, alpha: 0.65)
        recyclerShapeQuad2D.drawPoint(graphics: graphics, renderEncoder: renderEncoder,
                                      projection: projection, modelView: modelView,
                                      point: simd_float2(graphics.width - 50.0, 50.0))

        recyclerShapeQuad2D.set(red: 0.125, green: 0.125, blue: 1.0, alpha: 0.65)
        recyclerShapeQuad2D.drawPoint(graphics: graphics, renderEncoder: renderEncoder,
                                      projection: projection, modelView: modelView,
                                      point: simd_float2(graphics.width - 50.0, graphics.height - 50.0))

        recyclerShapeQuad2D.set(red: 0.125, green: 0.5, blue: 0.85, alpha: 0.65)
        recyclerShapeQuad2D.drawPoint(graphics: graphics, renderEncoder: renderEncoder,
                                      projection: projection, modelView: modelView,
                                      point: simd_float2(50.0, graphics.height - 50.0))
    }
    
    func testDrawIndexedSprite3D(renderEncoder: MTLRenderCommandEncoder) {
        
        struct SpriteNode {
            let x: Float
            let y: Float
            let z: Float
            let u: Float
            let v: Float
        }
        
        var uniformsVertex = UniformsShapeNodeIndexedVertex()
        uniformsVertex.projectionMatrix.ortho(width: graphics.width, height: graphics.height)
        let uniformsVertexBuffer = graphics.buffer(uniform: uniformsVertex)
        
        var uniformsFragment = UniformsShapeNodeIndexedFragment()
        uniformsFragment.red = 0.85
        uniformsFragment.alpha = 0.75
        let uniformsFragmentBuffer = graphics.buffer(uniform: uniformsFragment)
        
        let radiusInner = graphics.width * 0.10
        let radiusOuter = graphics.width * 0.30
        
        for loop in 0..<4 {
            
            graphics.set(pipelineState: .spriteNodeIndexed3DNoBlending, renderEncoder: renderEncoder)
            if loop == 1 { graphics.set(pipelineState: .spriteNodeIndexed3DAlphaBlending, renderEncoder: renderEncoder) }
            if loop == 2 { graphics.set(pipelineState: .spriteNodeIndexed3DAdditiveBlending, renderEncoder: renderEncoder) }
            if loop == 3 { graphics.set(pipelineState: .spriteNodeIndexed3DPremultipliedBlending, renderEncoder: renderEncoder) }
            
            let centerX = graphics.width * 0.30
            let centerY = graphics.height * 0.125 + (Float(loop) / 4) * graphics.height + 20.0
            
            var nodes = [SpriteNode]()
            var indices = [Int16]()
            
            let count = 12
            
            for index in 0..<count {
                let percent = Float(index) / Float(count - 1)
                let angle = percent * Float.pi * 2.0 + Float.pi
                
                let dir = Math.vector2D(radians: angle)
                
                let node1 = SpriteNode(x: centerX + dir.x * radiusInner, y: centerY + dir.y * radiusInner, z: 0.0, u: percent, v: 0.0)
                let node2 = SpriteNode(x: centerX + dir.x * radiusOuter, y: centerY + dir.y * radiusOuter, z: 0.0, u: percent, v: 1.0)
                
                nodes.append(node1)
                nodes.append(node2)
            }
            
            var back1: Int16 = 0
            var back2: Int16 = 1
            
            for i in 1..<count {
                
                let cur1: Int16 = Int16(i * 2)
                let cur2: Int16 = cur1 + 1
                
                // triangle 1
                indices.append(back1)
                indices.append(cur1)
                indices.append(back2)
                
                // triangle 2
                indices.append(back2)
                indices.append(cur2)
                indices.append(cur1)
                
                back1 = cur1
                back2 = cur2
            }
            
            let dataBuffer = graphics.buffer(array: nodes)
            
            guard let indexBuffer = graphics.buffer(array: indices) else {
                return
            }
            
            graphics.setVertexUniformsBuffer(uniformsVertexBuffer, renderEncoder: renderEncoder)
            graphics.setFragmentUniformsBuffer(uniformsFragmentBuffer, renderEncoder: renderEncoder)
            
            graphics.setVertexDataBuffer(dataBuffer, renderEncoder: renderEncoder)
            
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: indices.count,
                                                indexType: .uint16,
                                                indexBuffer: indexBuffer,
                                                indexBufferOffset: 0)
        }
    }
    
    
    func testDrawIndexedSpriteColored3D(renderEncoder: MTLRenderCommandEncoder) {
        
        struct RainbowSpriteNode {
            let x: Float
            let y: Float
            let z: Float
            let u: Float
            let v: Float
            
            let r: Float
            let g: Float
            let b: Float
            let a: Float
        }
        
        var uniformsVertex = UniformsShapeNodeIndexedVertex()
        uniformsVertex.projectionMatrix.ortho(width: graphics.width, height: graphics.height)
        let uniformsVertexBuffer = graphics.buffer(uniform: uniformsVertex)
        
        var uniformsFragment = UniformsShapeNodeIndexedFragment()
        uniformsFragment.red = 0.85
        uniformsFragment.alpha = 0.75
        let uniformsFragmentBuffer = graphics.buffer(uniform: uniformsFragment)
        
        let radiusInner = graphics.width * 0.10
        let radiusOuter = graphics.width * 0.30
        
        var r_sine = Float.pi
        var g_sine = Float.pi * 3.0
        var b_sine = Float.pi * 2.0 / 3.0
        var a_sine = Float.pi / 2.0
        
        
        for loop in 0..<4 {
            
            graphics.set(pipelineState: .spriteNodeColoredIndexed3DNoBlending, renderEncoder: renderEncoder)
            if loop == 1 { graphics.set(pipelineState: .spriteNodeColoredIndexed3DAlphaBlending, renderEncoder: renderEncoder) }
            if loop == 2 { graphics.set(pipelineState: .spriteNodeColoredIndexed3DAdditiveBlending, renderEncoder: renderEncoder) }
            if loop == 3 { graphics.set(pipelineState: .spriteNodeColoredIndexed3DPremultipliedBlending, renderEncoder: renderEncoder) }
            
            let centerX = graphics.width * 0.70
            let centerY = graphics.height * 0.125 + (Float(loop) / 4) * graphics.height + 20.0
            
            var nodes = [RainbowSpriteNode]()
            var indices = [Int16]()
            
            let count = 64
            
            for index in 0..<count {
                
                r_sine += Float.pi / 4.0
                g_sine += Float.pi / 8.0
                b_sine += Float.pi / 12.0
                a_sine += Float.pi / 16.0
                
                var r = (sinf(r_sine) + 1.0) / 2.0
                var g = (sinf(g_sine) + 1.0) / 2.0
                var b = (sinf(b_sine) + 1.0) / 2.0
                var a = (sinf(a_sine) + 1.0) / 2.0
                
                r = 0.5 + r * 0.5
                g = 0.15 + g * 0.7
                b = 0.15 + b * 0.7
                a = 0.5 + a * 0.5
                
                let percent = Float(index) / Float(count - 1)
                let angle = percent * Float.pi * 2.0 + Float.pi
                
                let dir = Math.vector2D(radians: angle)
                
                let node1 = RainbowSpriteNode(x: centerX + dir.x * radiusInner, y: centerY + dir.y * radiusInner, z: 0.0, u: percent, v: 0.0, r: r, g: g, b: b, a: a)
                let node2 = RainbowSpriteNode(x: centerX + dir.x * radiusOuter, y: centerY + dir.y * radiusOuter, z: 0.0, u: percent, v: 1.0, r: r, g: g, b: b, a: a)
                
                nodes.append(node1)
                nodes.append(node2)
            }
            
            var back1: Int16 = 0
            var back2: Int16 = 1
            
            for i in 1..<count {
                
                let cur1: Int16 = Int16(i * 2)
                let cur2: Int16 = cur1 + 1
                
                // triangle 1
                indices.append(back1)
                indices.append(cur1)
                indices.append(back2)
                
                // triangle 2
                indices.append(back2)
                indices.append(cur2)
                indices.append(cur1)
                
                back1 = cur1
                back2 = cur2
            }
            
            let dataBuffer = graphics.buffer(array: nodes)
            
            guard let indexBuffer = graphics.buffer(array: indices) else {
                return
            }
            
            graphics.setVertexUniformsBuffer(uniformsVertexBuffer, renderEncoder: renderEncoder)
            graphics.setFragmentUniformsBuffer(uniformsFragmentBuffer, renderEncoder: renderEncoder)
            
            graphics.setVertexDataBuffer(dataBuffer, renderEncoder: renderEncoder)
            
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                indexCount: indices.count,
                                                indexType: .uint16,
                                                indexBuffer: indexBuffer,
                                                indexBufferOffset: 0)
            
        }
    }
}
