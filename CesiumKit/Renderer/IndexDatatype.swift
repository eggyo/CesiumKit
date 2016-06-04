//
//  IndexDatatype.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 20/09/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

import Metal

/**
* Constants for WebGL index datatypes.  These corresponds to the
* <code>type</code> parameter of {@link http://www.khronos.org/opengles/sdk/docs/man/xhtml/glDrawElements.xml|drawElements}.
*
* @namespace
* @alias IndexDatatype
*/
enum IndexDatatype: UInt {
    case UnsignedShort
    case UnsignedInt

    var metalIndexType: MTLIndexType {
        return MTLIndexType(rawValue: self.rawValue)!
    }
    
    /**
    * Returns the size, in bytes, of the corresponding datatype.
    *
    * @param {IndexDatatype} indexDatatype The index datatype to get the size of.
    * @returns {Number} The size in bytes.
    *
    * @example
    * // Returns 2
    * var size = Cesium.IndexDatatype.getSizeInBytes(Cesium.IndexDatatype.UNSIGNED_SHORT);
    */
    var elementSize: Int {
        switch (self) {
        case .UnsignedShort:
            return sizeof(UInt16)
        case .UnsignedInt:
            return sizeof(UInt32)
        }
    }
    
    static func createIntegerIndexArrayFrom (data: NSData, numberOfVertices: Int, byteOffset: Int, length: Int) -> [Int] {
        if numberOfVertices > Math.SixtyFourKilobytes {
            return data.getUInt32Array(byteOffset, elementCount: length).map { Int($0) }
        } else {
            return data.getUInt16Array(byteOffset, elementCount: length).map { Int($0) }
        }
    }
}