//
//  TileFactory.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/21/23.
//

import Foundation
import Metal

class TileFactory {
    
    private(set) var textures = [[MTLTexture?]]()
    
    init() {
        
    }
    
    func texture(x: Int, y: Int) -> MTLTexture? {
        guard x >= 0 else { return nil }
        guard x < textures.count else { return nil }
        guard y >= 0 else { return nil }
        guard y < textures[0].count else { return nil }
        return textures[x][y]
    }
    
    var width: Int {
        return textures.count
    }
    
    var height: Int {
        if textures.count > 0 {
            return textures[0].count
        }
        return 0
    }
    
    func load(graphics: Graphics,
              textureGridWidth: Int,
              textureGridHeight: Int,
              baseFileName: String,
              leadingZeroes: Int) {
        
        textures = [[MTLTexture?]](repeating: [MTLTexture?](), count: textureGridWidth)
        for x in 0..<textureGridWidth {
            textures[x].reserveCapacity(textureGridHeight)
            for _ in 0..<textureGridHeight {
                textures[x].append(nil)
            }
        }
        
        
        for y in 0..<textureGridHeight {
            for x in 0..<textureGridWidth {
                let fileName = baseFileName +
                numberString(number: x, leadingZeroes: leadingZeroes) +
                "_" +
                numberString(number: y, leadingZeroes: leadingZeroes) +
                ".png"
                
                textures[x][y] = graphics.loadTexture(fileName: fileName)
            }
        }
    }
    
    func numberString(number: Int, leadingZeroes: Int) -> String {
        return String(format: "%0\(leadingZeroes)d", number)
    }
}


