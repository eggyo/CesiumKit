//
//  DepthPlane.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 16/11/2015.
//  Copyright © 2015 Test Toast. All rights reserved.
//

import Foundation

class DepthPlane {
    
    /**
    * @private
    */
    private var _rs: RenderState? = nil
    private var _attributes: [VertexAttributes]? = nil
    private var _pipeline: RenderPipeline? = nil
    private var _va: VertexArray? = nil
    private var _command: DrawCommand? = nil
    private var _mode: SceneMode = .Scene3D
    
    private func computeDepthQuad(ellipsoid: Ellipsoid, frameState: FrameState) -> [Float] {
        let radii = ellipsoid.radii
        let p = frameState.camera!.positionWC
        
        // Find the corresponding position in the scaled space of the ellipsoid.
        let q = ellipsoid.oneOverRadii.multiply(p)
        
        let qMagnitude = q.magnitude
        let qUnit = q.normalize()
        
        // Determine the east and north directions at q.
        let eUnit = Cartesian3.unitZ.cross(q).normalize()
        let nUnit = qUnit.cross(eUnit).normalize()
        
        // Determine the radius of the 'limb' of the ellipsoid.
        let wMagnitude = sqrt(q.magnitudeSquared - 1.0)
        
        // Compute the center and offsets.
        let center = qUnit.multiply(scalar: 1.0 / qMagnitude)
        let scalar = wMagnitude / qMagnitude
        let eastOffset = eUnit.multiply(scalar: scalar)
        let northOffset = nUnit.multiply(scalar: scalar)
        
        var depthQuad = [Float](repeating: 0.0, count: 12)
        // A conservative measure for the longitudes would be to use the min/max longitudes of the bounding frustum.
        let upperLeft = center
            .add(northOffset)
            .subtract(eastOffset)
        radii.multiply(upperLeft).pack(array: &depthQuad, startingIndex: 0)
        
        let lowerLeft = center
            .subtract(northOffset)
            .subtract(eastOffset)
        radii.multiply(lowerLeft).pack(array: &depthQuad, startingIndex: 3)
        
        let upperRight = center
            .add(northOffset)
            .add(eastOffset)
        radii.multiply(upperRight).pack(array: &depthQuad, startingIndex: 6)
        
        let lowerRight = center
            .subtract(northOffset)
            .add(eastOffset)
        radii.multiply(lowerRight).pack(array: &depthQuad, startingIndex: 9)
        
        return depthQuad
    }
    
    func update (frameState: FrameState) {
        _mode = frameState.mode
        
        if frameState.mode != .Scene3D {
            return
        }
        
        let ellipsoid = frameState.mapProjection.ellipsoid
        let context = frameState.context!
        
        if _command == nil {
            _rs = RenderState( // Write depth, not color
                device: context.device,
                cullFace: .back,
                depthTest: RenderState.DepthTest(
                    enabled: true,
                    function: .Always
                )
            )
            // position
            _attributes = [VertexAttributes(
                buffer: nil,
                bufferIndex: VertexDescriptorFirstBufferOffset,
                index: 0,
                format: .Float3,
                offset: 0,
                size: strideof(Float) * 3,
                normalize: false
                )]
            _pipeline = RenderPipeline.fromCache(
                context: context,
                vertexShaderSource: ShaderSource(sources: [Shaders["DepthPlaneVS"]!]),
                fragmentShaderSource: ShaderSource(sources: [Shaders["DepthPlaneFS"]!]),
                vertexDescriptor: VertexDescriptor(attributes: _attributes!),
                colorMask: ColorMask(
                    red: false,
                    green: false,
                    blue: false,
                    alpha: false
                ),
                depthStencil: context.depthTexture
            )
            _command = DrawCommand(
                boundingVolume: BoundingSphere(
                    center: Cartesian3.zero,
                    radius: ellipsoid.maximumRadius),
                renderState: _rs,
                renderPipeline: _pipeline,
                pass: .Opaque,
                owner: self
            )
        }
        // update depth plane
        let depthQuad = computeDepthQuad(ellipsoid: ellipsoid, frameState: frameState)
        
        // depth plane
        if _va == nil {
            let geometry = Geometry(
                attributes: GeometryAttributes(
                    position: GeometryAttribute(
                        componentDatatype : .Float32,
                        componentsPerAttribute: 3,
                        values: Buffer(
                            device: context.device,
                            array: depthQuad,
                            componentDatatype: .Float32,
                            sizeInBytes: depthQuad.sizeInBytes,
                            label: "DepthPlaneGeometry"
                        )
                    )
                    
                ),
                indices : [0, 1, 2, 2, 1, 3],
                primitiveType : .triangle
            )
            
            _va = VertexArray(
                fromGeometry: geometry,
                context : context,
                attributeLocations: ["position": 0]
            )
            _command!.vertexArray = _va
        } else {
            _va!.attributes[0].buffer?.copyFrom(array: depthQuad, length: depthQuad.sizeInBytes)
        }
    }
    
    func execute (context: Context, renderPass: RenderPass, frustumUniformBuffer: Buffer? = nil) {
        if _mode == SceneMode.Scene3D {
            _command?.execute(in: context, renderPass: renderPass, frustumUniformBuffer: frustumUniformBuffer)
        }
    }

}