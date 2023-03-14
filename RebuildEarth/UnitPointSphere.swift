//
//  UnitPointSphere.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/21/23.
//

import Foundation
import simd

class UnitPointSphere {
    
    private(set) var points = [[simd_float3]]()
    private(set) var angleH = [[Float]]()
    private(set) var angleV = [[Float]]()
    
    private(set) var tileCountH = 0
    private(set) var tileCountV = 0
    
    init() {
        
    }
    
    func load(tileCountH: Int, tileCountV: Int,
              startRotationH: Float = 0.0,
              endRotationH: Float = Float.pi * 2.0,
              startRotationV: Float = 0.0,
              endRotationV: Float = Float.pi) {
        
        if (tileCountH == self.tileCountH) && (tileCountV == self.tileCountV) {
            return
        }

        self.tileCountH = tileCountH
        self.tileCountV = tileCountV
        
        points = [[simd_float3]](repeating: [simd_float3](), count: tileCountH + 1)
        angleH = [[Float]](repeating: [Float](), count: tileCountH + 1)
        angleV = [[Float]](repeating: [Float](), count: tileCountH + 1)
        for x in 0...tileCountH {
            points[x].reserveCapacity(tileCountV + 1)
            angleH[x].reserveCapacity(tileCountV + 1)
            angleV[x].reserveCapacity(tileCountV + 1)
            for _ in 0...tileCountV {
                points[x].append(simd_float3(0.0, 1.0, 0.0))
                angleH[x].append(0.0)
                angleV[x].append(0.0)
            }
        }
        
        var indexV = 0
        while indexV <= tileCountV {
            let percentV = (Float(indexV) / Float(tileCountV))
            let _angleV = startRotationV + (endRotationV - startRotationV) * percentV
            
            var indexH = 0
            while indexH <= tileCountH {
                let percentH = (Float(indexH) / Float(tileCountH))
                let _angleH = startRotationH + (endRotationH - startRotationH) * percentH
                
                angleH[indexH][indexV] = _angleH
                angleV[indexH][indexV] = _angleV
                
                var point = simd_float3(0.0, 1.0, 0.0)
                point = Math.rotateX(float3: point, radians: _angleV)
                point = Math.rotateY(float3: point, radians: _angleH)
                
                points[indexH][indexV] = point
                
                indexH += 1
            }
            indexV += 1
        }
    }
}
