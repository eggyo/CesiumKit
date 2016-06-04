//
//  Imagery.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 16/08/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

import Foundation

/**
* Stores details about a tile of imagery.
*
* @alias Imagery
* @private
*/
class Imagery {
    
    unowned var imageryLayer: ImageryLayer

    var level: Int
    
    var x: Int
    
    var y: Int
    
    var parent: Imagery? = nil
    
    var rectangle: Rectangle? = nil
    
    var image: CGImage? = nil
    
    var imageUrl: String? = nil
    
    var state: ImageryState = .Unloaded
    
    var texture: Texture? = nil
    
    var reprojectCommand: DrawCommand? = nil
    
    var credits = [Credit]()
    
    private var _referenceCount: Int = 0
    
    init(imageryLayer: ImageryLayer, level: Int, x: Int, y: Int, rectangle: Rectangle? = nil) {
        
        self.imageryLayer = imageryLayer
        self.level = level
        self.x = x
        self.y = y
        
        if (level != 0) {
            let parentX = x / 2 | 0
            let parentY = y / 2 | 0
            let parentLevel = level - 1
            parent = imageryLayer.getImageryFromCache(level: parentLevel, x: parentX, y: parentY)
        }
        
        if rectangle == nil && imageryLayer.imageryProvider.ready {
            let tilingScheme = imageryLayer.imageryProvider.tilingScheme
            self.rectangle = tilingScheme.tileXYToRectangle(x: x, y: y, level: level)
        } else {
            self.rectangle = rectangle
        }
    }

    class func createPlaceholder(imageryLayer: ImageryLayer) -> Imagery {
        let result = Imagery(imageryLayer: imageryLayer, level: 0, x: 0, y: 0)
        result.addReference()
        result.state = .PlaceHolder
        return result
    }
    
    func addReference() {
        _referenceCount += 1
    }
    
    func releaseReference() -> Int {
        _referenceCount -= 1
        
        if _referenceCount == 0 {
            imageryLayer.removeImageryFromCache(self)
            
            if parent != nil {
                parent!.releaseReference()
            }
            return 0
        }
        return _referenceCount
    }
    
    func processStateMachine (frameState frameState: inout FrameState) {
        if (state == .Unloaded) {
            state = .Transitioning
            imageryLayer.requestImagery(self)
        }
        if (state == .Received) {
            state = .Transitioning
            imageryLayer.createTexture(frameState: frameState, imagery: self)
        }
        if (state == .TextureLoaded) {
            state = .Transitioning
            imageryLayer.reprojectTexture(frameState: &frameState, imagery: self)
        }
        if (state == .Reprojected) {
            state = .Transitioning
            imageryLayer.generateMipmaps(frameState: &frameState, imagery: self)
        }
    }
    
}
