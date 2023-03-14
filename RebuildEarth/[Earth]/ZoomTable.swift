//
//  ZoomTable.swift
//  RebuildEarth
//
//  Created by Nicky Taylor on 2/22/23.
//

import Foundation

class ZoomTable {
    
    static let size = 12
    
    static let minZoomUndershoot = Float(0.5)
    static let minZoomHard = Float(1.0)
    static let minZoomSoft = Float(1.5)
    
    static let maxZoomSoft = Float(11.0)
    static let maxZoomHard = Float(12.0)
    static let maxZoomOvershoot = Float(13.0)
    
    private var zooms = [Float](repeating: 0.0, count: ZoomTable.size)
    private var distances = [Float](repeating: 0.0, count: ZoomTable.size)
    
    init() {
        for index in 0..<ZoomTable.size {
            let percent = Float(index) / Float(ZoomTable.size - 1)
            let zoom = Self.minZoomHard + (Self.maxZoomHard - Self.minZoomHard) * percent
            zooms[index] = zoom
        }
    }
    
    func refresh(distances: [Float]) {
        let ceiling = min(distances.count, self.distances.count)
        for index in 0..<ceiling {
            self.distances[index] = distances[index]
        }
    }
    
    func distance(zoom: Float) -> Float {
        
        if zoom <= zooms[0] {
            return distances[0]
        }
        
        var _indexPrevious = 0
        var _zoomPrevious = zooms[0]
        var _index = 1
        while _index < ZoomTable.size {
            let _zoom = zooms[_index]
            if zoom < _zoom {
                var percent = (zoom - _zoomPrevious) / (_zoom - _zoomPrevious)
                if percent < 0.0 { percent = 0.0 }
                if percent > 1.0 { percent = 1.0 }
                return distances[_indexPrevious] + (distances[_index] - distances[_indexPrevious]) * percent
            }
            _zoomPrevious = _zoom
            _indexPrevious = _index
            _index += 1
        }
        return distances[distances.count - 1]
    }
    
    func zoom(distance: Float) -> Float {
        
        if distance >= distances[0] {
            return zooms[0]
        }
        
        var _indexPrevious = 0
        var _distancePrevious = distances[0]
        var _index = 1
        while _index < ZoomTable.size {
            let _distance = distances[_index]
            if distance > _distance {
                var percent = (_distancePrevious - distance) / (_distancePrevious - _distance)
                if percent < 0.0 { percent = 0.0 }
                if percent > 1.0 { percent = 1.0 }
                return zooms[_indexPrevious] + (zooms[_index] - zooms[_indexPrevious]) * percent
            }
            _distancePrevious = _distance
            _indexPrevious = _index
            _index += 1
        }
        return zooms[zooms.count - 1]
    }
}
