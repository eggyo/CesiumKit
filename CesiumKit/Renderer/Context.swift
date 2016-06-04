//
//  Context.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 15/06/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

import Foundation
import MetalKit
import QuartzCore.CAMetalLayer


/**
* @private
*/

class Context {
        
    private var _debug: (
    renderCountThisFrame: Int,
    renderCount: Int
    )
    
    /*var renderQueue: dispatch_queue_t {
    get {
    return view.renderQueue
    }
    }*/

    private let _inflight_semaphore: dispatch_semaphore_t
    
    private (set) var bufferSyncState: BufferSyncState = .zero
    
    private var _lastFrameDrawCommands = Array<[DrawCommand]>(repeating: [DrawCommand](), count: 3
    )
    
    let view: MTKView
    
    internal let device: MTLDevice!
    
    private let _commandQueue: MTLCommandQueue
    
    private var _drawable: CAMetalDrawable! = nil
    private var _commandBuffer: MTLCommandBuffer! = nil
    
    var limits: ContextLimits
        
    private (set) var depthTexture: Bool = true
    
    var allowTextureFilterAnisotropic: Bool = true
    
    var textureFilterAnisotropic: Bool = true
    
    struct glOptions {
        
        var alpha = false
        
        var stencil = false
        
    }
    
    var id: String
    
    var _logShaderCompilation = false
    
    let pipelineCache: PipelineCache!
    
    private var _clearColor: MTLClearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
    
    private var _clearDepth: Double = 0.0
    private var _clearStencil: UInt32 = 0
    
    private var _currentRenderState: RenderState
    private let _defaultRenderState: RenderState
    
    private var _currentPassState: PassState? = nil
    private let _defaultPassState: PassState
    
    private var _passStates = [Pass: PassState]()
    
    var uniformState: UniformState
    private let _automaticUniformBufferProvider: UniformBufferProvider
    
    private var _frustumUniformBufferProviderPool = [UniformBufferProvider]()
    private (set) var wholeFrustumUniformBufferProvider: UniformBufferProvider! = nil
    private (set) var frontFrustumUniformBufferProvider: UniformBufferProvider! = nil

    /**
    * A 1x1 RGBA texture initialized to [255, 255, 255, 255].  This can
    * be used as a placeholder texture while other textures are downloaded.
    * @memberof Context.prototype
    * @type {Texture}
    */
    /*lazy var defaultTexture: Texture = {
    var imageBuffer = Imagebuffer(width: 1, height: 1, arrayBufferView: [255, 255, 255, 255])
    var source = TextureSource.ImageBuffer(imageBuffer)
    //var options = TextureOptions(source: source, width: nil, height: nil, pixelFormat: .RGBA, pixelDatatype: .UnsignedByte, flipY: false, premultiplyAlpha: true)
    return self.createTexture2D(options)
    }()*/
    
    /**
    * A cube map, where each face is a 1x1 RGBA texture initialized to
    * [255, 255, 255, 255].  This can be used as a placeholder cube map while
    * other cube maps are downloaded.
    * @memberof Context.prototype
    * @type {CubeMap}
    */
    //FIXME: cubemap
    /*var _defaultCubeMap: CubeMap?
    var defaultCubeMap: CubeMap {
    get {
    if !_defaultCubeMap {
    this._defaultCubeMap = this.createCubeMap(faces: [CubeMapFaceInfo](count: 6, repeatedValue: CubeMapFaceInfo(width: 1, height : 1, arrayBufferView: [255, 255, 255, 255])))
    }
    return _defaultCubeMap!
    
    }
    }*/
    
    /**
    * A cache of objects tied to this context.  Just before the Context is destroyed,
    * <code>destroy</code> will be invoked on each object in this object literal that has
    * such a method.  This is useful for caching any objects that might otherwise
    * be stored globally, except they're tied to a particular context, and to manage
    * their lifetime.
    *
    * @private
    * @type {Object}
    */
    var cache = [String: Any]()
    
    
    /**
    * The drawingBufferHeight of the underlying GL context.
    * @memberof Context.prototype
    * @type {Number}
    */
    
    var height: Int = 0
    /**
    * The drawingBufferWidth of the underlying GL context.
    * @memberof Context.prototype
    * @type {Number}
    */
    var width: Int = 0
    
    var cachedState: RenderState? = nil
    
    private var _maxFrameTextureUnitIndex = 0
    
    var pickObjects: [AnyObject]
    
    var nextPickColor: [UInt32]
    
    /**
    * Gets an object representing the currently bound framebuffer.  
    * This represents the associated MTKView's drawable.
    * @type {Object}
    */
    let defaultFramebuffer: Framebuffer
    
    init (view: MTKView) {
        
        self.view = view
        
        device = view.device!
        limits = ContextLimits(device: device)
        
        print("Metal device: " + (device.name ?? "Unknown"))
        #if os(OSX)
            print("- Low power: " + (device.isLowPower ? "Yes" : "No"))
            print("- Headless: " + (device.isHeadless ? "Yes" : "No"))
        #endif
        
        _commandQueue = device.newCommandQueue()
        
        pipelineCache = PipelineCache(device: device)
        id = NSUUID().uuidString
        
        _inflight_semaphore = dispatch_semaphore_create(3)//kInFlightCommandBuffers)
        
        //antialias = true
        
        pickObjects = Array<AnyObject>()
        nextPickColor = Array<UInt32>(repeating: 0, count: 1)
        
        _debug = (0, 0)
        
        let us = UniformState()
        let rs = RenderState(device: device)
        
        _defaultRenderState = rs
        uniformState = us
        _automaticUniformBufferProvider = UniformBufferProvider(device: device, bufferSize: strideof(AutomaticUniformBufferLayout), deallocationBlock: nil)
        _currentRenderState = rs
        defaultFramebuffer = Framebuffer(maximumColorAttachments: 1)
        _defaultPassState = PassState()
        _defaultPassState.context = self
        pipelineCache.context = self

        wholeFrustumUniformBufferProvider = getFrustumUniformBufferProvider()

        /**
        * @example
        * {
        *   webgl : {
        *     alpha : false,
        *     depth : true,
        *     stencil : false,
        *     antialias : true,
        *     premultipliedAlpha : true,
        *     preserveDrawingBuffer : false
        *     failIfMajorPerformanceCaveat : true
        *   },
        *   allowTextureFilterAnisotropic : true
        * }
        */
        //this.options = options;
        //_currentRenderState.apply(_defaultPassState)
        
        width = Int(view.drawableSize.width)
        height = Int(view.drawableSize.height)
    }
    
    /**
    * Creates a compiled MTLSamplerState from a MTLSamplerDescriptor. These should generally be cached.
    */
    func createSamplerState (descriptor: MTLSamplerDescriptor) -> MTLSamplerState {
        return device.newSamplerState(with: descriptor)
    }
    
    func beginFrame() -> Bool {
        
        // Allow the renderer to preflight 3 frames on the CPU (using a semaphore as a guard) and commit them to the GPU.
        // This semaphore will get signaled once the GPU completes a frame's work via addCompletedHandler callback below,
        // signifying the CPU can go ahead and prepare another frame.
        dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER)
        assert(_drawable == nil, "drawable != nil")
        _drawable = view.currentDrawable
        if _drawable == nil {
            print("drawable == nil")
            dispatch_semaphore_signal(_inflight_semaphore)
            return false
        }
        
        self._lastFrameDrawCommands[bufferSyncState.rawValue].removeAll()

        defaultFramebuffer.updateFromDrawable(context: self, drawable: _drawable, depthStencil: depthTexture ? view.depthStencilTexture : nil)
        
        _commandBuffer = _commandQueue.commandBuffer()
        
        _commandBuffer.addCompletedHandler { buffer in
            // Signal the semaphore and allow the CPU to proceed and construct the next frame.
            dispatch_semaphore_signal(self._inflight_semaphore)
        }
        
        let automaticUniformBuffer = _automaticUniformBufferProvider.currentBuffer(index: bufferSyncState)
        uniformState.setAutomaticUniforms(buffer: automaticUniformBuffer)
        automaticUniformBuffer.signalWriteComplete()
        
        return true

    }
    
    func createRenderPass(passState: PassState? = nil) -> RenderPass {
        let passState = passState ?? _defaultPassState
        let pass = RenderPass(context: self, buffer: _commandBuffer, passState: passState, defaultFramebuffer: defaultFramebuffer)
        return pass
    }
    
    func completeRenderPass(pass: RenderPass) {
        pass.complete()
    }
    
    func applyRenderState(pass: RenderPass, renderState: RenderState, passState: PassState) {
        pass.applyRenderState(renderState: renderState)
    }
    
    func createBlitCommandEncoder (completionHandler: MTLCommandBufferHandler? = nil) -> MTLBlitCommandEncoder {
        if let completionHandler = completionHandler {
            _commandBuffer.addCompletedHandler(completionHandler)
        }
        return _commandBuffer.blitCommandEncoder()
    }
    
    func completeBlitPass (encoder: MTLBlitCommandEncoder) {
        encoder.endEncoding()
    }
    
    func getFrustumUniformBufferProvider () -> UniformBufferProvider {
        if _frustumUniformBufferProviderPool.isEmpty {
            return UniformBufferProvider(device: device, bufferSize: strideof(FrustumUniformBufferLayout), deallocationBlock: { provider in
                    self._frustumUniformBufferProviderPool.append(provider)
                }
            )
        }
        return _frustumUniformBufferProviderPool.removeLast()
    }
    
    func returnFrustumUniformBufferProvider (provider: UniformBufferProvider) {
    }
    
    func clear(clearCommand: ClearCommand, passState: PassState? = nil) {
        
        let framebuffer = clearCommand.framebuffer ?? passState?.framebuffer ?? defaultFramebuffer

        let passDescriptor = framebuffer.renderPassDescriptor
        
        let c = clearCommand.color
        let d = clearCommand.depth
        let s = clearCommand.stencil
        
        let colorAttachment = passDescriptor.colorAttachments[0]
        if let c = c {
            colorAttachment.loadAction = .clear
            colorAttachment.storeAction = .store
            colorAttachment.clearColor = MTLClearColorMake(c.red, c.green, c.blue, c.alpha)
        } else {
            colorAttachment.loadAction = .load
            colorAttachment.storeAction = .store
        }
        
        let depthAttachment = passDescriptor.depthAttachment
        if let d = d {
            depthAttachment.loadAction = .clear
            depthAttachment.storeAction = .dontCare
            depthAttachment.clearDepth = d
        }
        
        let stencilAttachment = passDescriptor.stencilAttachment
        if let s = s {
            stencilAttachment.loadAction = .clear
            stencilAttachment.storeAction = .store
            stencilAttachment.clearStencil = s
        }
    }
    
    func draw(command: DrawCommand, renderPass: RenderPass, frustumUniformBuffer: Buffer? = nil) {
        _lastFrameDrawCommands[bufferSyncState.rawValue].append(command)
        beginDraw(command: command, renderPass: renderPass)
        continueDraw(command: command, renderPass: renderPass, frustumUniformBuffer: frustumUniformBuffer)
    }
    
    func beginDraw(command: DrawCommand, renderPass: RenderPass) {
        let rs = command.renderState ?? _defaultRenderState

        let commandEncoder = renderPass.commandEncoder
        
        guard let renderPipeline = command.pipeline else {
            assertionFailure("no render pipeline set")
            return
        }

        commandEncoder.setRenderPipelineState(renderPipeline.state)

        applyRenderState(pass: renderPass, renderState: rs, passState: renderPass.passState)
    }
    
    func continueDraw(command: DrawCommand, renderPass: RenderPass, frustumUniformBuffer: Buffer? = nil) {
        let primitiveType = command.primitiveType
        
        assert(command.vertexArray != nil, "drawCommand.vertexArray is required")
        let va = command.vertexArray!
        var offset = command.offset
        var count = command.count
        
        assert(offset >= 0, "drawCommand.offset must be omitted or greater than or equal to zero")
        assert(count == nil || count! >= 0, "drawCommand.count must be omitted or greater than or equal to zero")
        
        uniformState.model = command.modelMatrix ?? Matrix4.identity
        
        guard let renderPipeline = command.pipeline else {
            assertionFailure("no render pipeline set")
            return
        }
        
        let bufferParams = renderPipeline.setUniforms(command: command, device: device, uniformState: uniformState)
        
        // Don't render unless any textures required are available
        if !bufferParams.texturesValid {
            print("invalid textures")
            return
        }
        let commandEncoder = renderPass.commandEncoder
        
        if let indexBuffer = va.indexBuffer {
            let indexType = va.indexBuffer!.componentDatatype.toMTLIndexType()
            offset *= indexBuffer.componentDatatype.elementSize // offset in vertices to offset in bytes
            let indexCount = count ?? va.numberOfIndices
            
            // automatic uniforms
            commandEncoder.setVertexBuffer(_automaticUniformBufferProvider.currentBuffer(index: bufferSyncState).metalBuffer, offset: 0, at: 0)

            // frustum uniforms
            commandEncoder.setVertexBuffer(frustumUniformBuffer?.metalBuffer, offset: 0, at: 1)

            // manual uniforms
            if let uniformBuffer = command.uniformMap?.uniformBufferProvider?.currentBuffer(index: bufferSyncState) {
                commandEncoder.setVertexBuffer(uniformBuffer.metalBuffer, offset: 0, at: 2)
            }
            
            for attribute in va.attributes {
                if let buffer = attribute.buffer {
                    commandEncoder.setVertexBuffer(buffer.metalBuffer, offset: 0, at: attribute.bufferIndex)
                }
            }
            
            // automatic uniforms
            commandEncoder.setFragmentBuffer(_automaticUniformBufferProvider.currentBuffer(index: bufferSyncState).metalBuffer, offset: 0, at: 0)
            
            // frustum uniforms
            commandEncoder.setFragmentBuffer(frustumUniformBuffer?.metalBuffer, offset: 0, at: 1)
            
            // manual uniforms
            if let uniformBuffer = command.uniformMap?.uniformBufferProvider?.currentBuffer(index: bufferSyncState) {
                commandEncoder.setFragmentBuffer(uniformBuffer.metalBuffer, offset: bufferParams.fragmentOffset, at: 2)
            }
            for (index, texture) in bufferParams.textures.enumerated() {
                commandEncoder.setFragmentTexture(texture.metalTexture, at: index)
                commandEncoder.setFragmentSamplerState(texture.sampler.state, at: index)
            }
            
            commandEncoder.drawIndexedPrimitives(primitiveType, indexCount: indexCount, indexType: indexType, indexBuffer: indexBuffer.metalBuffer, indexBufferOffset: 0)
        } else {
            count = count ?? va.vertexCount
            /*va!._bind()
            glDrawArrays(GLenum(primitiveType.rawValue), GLint(offset), GLsizei(count!))
            va!._unBind()*/
        }
    }
    
    func endFrame () {
        _commandBuffer.present(_drawable)
        _commandBuffer.commit()
        
        _drawable = nil
        defaultFramebuffer.clearDrawable()
        
        _commandBuffer = nil
        /*
        var
        buffers = scratchBackBufferArray;
        if (this.drawBuffers) {
        this._drawBuffers.drawBuffersWEBGL(scratchBackBufferArray);
        }*/
        bufferSyncState = bufferSyncState.advance()
        
        _maxFrameTextureUnitIndex = 0
        _debug.renderCountThisFrame = 0
    }
    /*
    Context.prototype.readPixels = function(readState) {
    var gl = this._gl;
    
    readState = readState || {};
    var x = Math.max(readState.x || 0, 0);
    var y = Math.max(readState.y || 0, 0);
    var width = readState.width || gl.drawingBufferWidth;
    var height = readState.height || gl.drawingBufferHeight;
    var framebuffer = readState.framebuffer;
    
    //>>includeStart('debug', pragmas.debug);
    if (width <= 0) {
    throw new DeveloperError('readState.width must be greater than zero.');
    }
    
    if (height <= 0) {
    throw new DeveloperError('readState.height must be greater than zero.');
    }
    //>>includeEnd('debug');
    
    var pixels = new Uint8Array(4 * width * height);
    
    bindFramebuffer(this, framebuffer);
    
    gl.readPixels(x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
    
    return pixels;
    };*/
    
    private let viewportQuadAttributeLocations = [
        "position" : 0,
        "textureCoordinates": 1
    ]
    
    func getViewportQuadVertexArray () -> VertexArray {
        // Per-context cache for viewport quads
        
        if let vertexArray = cache["viewportQuad_vertexArray"] as? VertexArray {
            return vertexArray
        }
        
        let geometry = Geometry(
            attributes: GeometryAttributes(
                position: GeometryAttribute(
                    componentDatatype: .Float32,
                    componentsPerAttribute: 2,
                    values: Buffer(
                        device: device,
                        array: [
                            -1.0, -1.0,
                            1.0, -1.0,
                            1.0, 1.0,
                            -1.0, 1.0
                        ].map({ Float($0)}),
                        componentDatatype: .Float32,
                        sizeInBytes: 8 * strideof(Float)
                    )
                ), // position
                st: GeometryAttribute(
                    componentDatatype: .Float32,
                    componentsPerAttribute: 2,
                    values: Buffer(
                        device: device,
                        array: [ // Flipped for Metal texture coordinates (top-left  = (0, 0))
                            0.0, 1.0,
                            1.0, 1.0,
                            1.0, 0.0,
                            0.0, 0.0].map({ Float($0)}),
                        componentDatatype: .Float32,
                        sizeInBytes: 8 * strideof(Float)
                    )
                )
            ), // textureCoordinates
            indices: [0, 1, 2, 0, 2, 3]
            )
        
        let vertexArray = VertexArray(
            fromGeometry: geometry,
            context: self,
            attributeLocations: viewportQuadAttributeLocations,
            interleave : true
        )
    
        cache["viewportQuad_vertexArray"] = vertexArray
        
        return vertexArray
    }
    
    func createViewportQuadCommand (fragmentShaderSource fss: ShaderSource, overrides: ViewportQuadOverrides? = nil, depthStencil: Bool = true, blendingState: BlendingState? = nil) -> DrawCommand
    {
        
        let vertexArray = getViewportQuadVertexArray()
        let command = DrawCommand(
            vertexArray: vertexArray,
            uniformMap: overrides?.uniformMap,
            renderState: overrides?.renderState,
            renderPipeline: RenderPipeline.fromCache(
                context: self,
                vertexShaderSource: ShaderSource(sources: [Shaders["ViewportQuadVS"]!]),
                fragmentShaderSource: fss,
                vertexDescriptor: VertexDescriptor(attributes: vertexArray.attributes),
                depthStencil: depthStencil,
                blendingState: blendingState
            ),
            owner: self
        )
        return command
    }

    /*
    Context.prototype.createPickFramebuffer = function() {
    return new PickFramebuffer(this);
    };
    
    /**
    * Gets the object associated with a pick color.
    *
    * @memberof Context
    *
    * @param {Color} pickColor The pick color.
    *
    * @returns {Object} The object associated with the pick color, or undefined if no object is associated with that color.
    *
    * @example
    * var object = context.getObjectByPickColor(pickColor);
    *
    * @see Context#createPickId
    */
    Context.prototype.getObjectByPickColor = function(pickColor) {
    //>>includeStart('debug', pragmas.debug);
    if (!defined(pickColor)) {
    throw new DeveloperError('pickColor is required.');
    }
    //>>includeEnd('debug');
    
    return this._pickObjects[pickColor.toRgba()];
    };
    
    function PickId(pickObjects, key, color) {
    this._pickObjects = pickObjects;
    this.key = key;
    this.color = color;
    }
    
    defineProperties(PickId.prototype, {
    object : {
    get : function() {
    return this._pickObjects[this.key];
    },
    set : function(value) {
    this._pickObjects[this.key] = value;
    }
    }
    });
    
    PickId.prototype.destroy = function() {
    delete this._pickObjects[this.key];
    return undefined;
    };
    
    /**
    * Creates a unique ID associated with the input object for use with color-buffer picking.
    * The ID has an RGBA color value unique to this context.  You must call destroy()
    * on the pick ID when destroying the input object.
    *
    * @memberof Context
    *
    * @param {Object} object The object to associate with the pick ID.
    *
    * @returns {Object} A PickId object with a <code>color</code> property.
    *
    * @exception {RuntimeError} Out of unique Pick IDs.
    *
    * @see Context#getObjectByPickColor
    *
    * @example
    * this._pickId = context.createPickId({
    *   primitive : this,
    *   id : this.id
    * });
    */
    Context.prototype.createPickId = function(object) {
    //>>includeStart('debug', pragmas.debug);
    if (!defined(object)) {
    throw new DeveloperError('object is required.');
    }
    //>>includeEnd('debug');
    
    // the increment and assignment have to be separate statements to
    // actually detect overflow in the Uint32 value
    ++this._nextPickColor[0];
    var key = this._nextPickColor[0];
    if (key === 0) {
    // In case of overflow
    throw new RuntimeError('Out of unique Pick IDs.');
    }
    
    this._pickObjects[key] = object;
    return new PickId(this._pickObjects, key, Color.fromRgba(key));
    };
    
    Context.prototype.isDestroyed = function() {
    return false;
    };
    */
    deinit {
        /*
        // Destroy all objects in the cache that have a destroy method.
        var cache = this.cache;
        for (var property in cache) {
        if (cache.hasOwnProperty(property)) {
        var propertyValue = cache[property];
        if (defined(propertyValue.destroy)) {
        propertyValue.destroy();
        }
        }
        }
        this._shaderCache = this._shaderCache.destroy();
        this._defaultTexture = this._defaultTexture && this._defaultTexture.destroy();
        this._defaultCubeMap = this._defaultCubeMap && this._defaultCubeMap.destroy();
        }
        */
    }
    
    
}
