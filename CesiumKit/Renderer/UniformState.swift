//
//  UniformState.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 22/06/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

import Foundation
import simd

struct AutomaticUniformBufferLayout {
    var czm_a_viewRotation = float3x3()
    var czm_a_temeToPseudoFixed = float3x3()
    var czm_a_sunDirectionEC = float3()
    var czm_a_sunDirectionWC = float3()
    var czm_a_moonDirectionEC = float3()
    var czm_a_viewerPositionWC = float3()
    var czm_a_morphTime = Float()
    var czm_a_fogDensity = Float()
    var czm_a_frameNumber = Float()
    var czm_a_pass = Float()
}

struct FrustumUniformBufferLayout {
    var czm_f_viewportOrthographic = float4x4()
    var czm_f_viewportTransformation = float4x4()
    var czm_f_projection = float4x4()
    var czm_f_inverseProjection = float4x4()
    var czm_f_view = float4x4()
    var czm_f_modelView = float4x4()
    var czm_f_modelView3D = float4x4()
    var czm_f_inverseModelView = float4x4()
    var czm_f_modelViewProjection = float4x4()
    var czm_f_viewport = float4()
    var czm_f_normal = float3x3()
    var czm_f_normal3D = float3x3()
    var czm_f_entireFrustum = float2()
}

class UniformState {
    
    /**
     * @type {Texture}
     */
    var globeDepthTexture: Texture? = nil
    
    /**
    * @private
    */
    private var _viewport = Cartesian4()
    private var _viewportDirty = false
    private var _viewportOrthographicMatrix = Matrix4.identity
    private var _viewportTransformation = Matrix4.identity
    
    private var _model = Matrix4.identity
    private var _view = Matrix4.identity
    private var _inverseView = Matrix4.identity
    private var _projection = Matrix4.identity
    private var _infiniteProjection = Matrix4.identity
    
    private var _entireFrustum = Cartesian2()
    private var _currentFrustum = Cartesian2()
    private var _frustumPlanes = Cartesian4()
    
    /**
    * @memberof UniformState.prototype
    * @type {FrameState}
    * @readonly
    */
    var frameState: FrameState! = nil
    
    private var _temeToPseudoFixed = Matrix3(fromMatrix4: Matrix4.identity)
    
    // Derived members
    private var _view3DDirty = true
    private var _view3D = Matrix4()
    
    private var _inverseView3DDirty = true
    private var _inverseView3D = Matrix4()
    
    private var _inverseModelDirty = true
    private var _inverseModel = Matrix4()
    
    private var _inverseTransposeModelDirty = true
    private var _inverseTransposeModel = Matrix3()
    
    private var _viewRotation = Matrix3()
    private var _inverseViewRotation = Matrix3()
    
    private var _viewRotation3D = Matrix3()
    private var _inverseViewRotation3D = Matrix3()
    
    private var _inverseProjectionDirty = true
    private var _inverseProjection = Matrix4()
    
    private var _inverseProjectionOITDirty = true
    private var _inverseProjectionOIT = Matrix4()
    
    private var _modelViewDirty = true
    private var _modelView = Matrix4()
    
    private var _modelView3DDirty = true
    private var _modelView3D = Matrix4()
    
    private var _modelViewRelativeToEyeDirty = true
    private var _modelViewRelativeToEye = Matrix4()
    
    private var _inverseModelViewDirty = true
    private var _inverseModelView = Matrix4()
    
    private var _inverseModelView3DDirty = true
    private var _inverseModelView3D = Matrix4()
    
    private var _viewProjectionDirty = true
    private var _viewProjection = Matrix4()
    
    private var _inverseViewProjectionDirty = true
    private var _inverseViewProjection = Matrix4()
    
    private var _modelViewProjectionDirty = true
    private var _modelViewProjection = Matrix4()
    
    private var _inverseModelViewProjectionDirty = true
    private var _inverseModelViewProjection = Matrix4()
    
    private var _modelViewProjectionRelativeToEyeDirty = true
    private var _modelViewProjectionRelativeToEye = Matrix4()
    
    private var _modelViewInfiniteProjectionDirty = true
    private var _modelViewInfiniteProjection = Matrix4()
    
    private var _normalDirty = true
    private var _normal = Matrix3()
    
    private var _normal3DDirty = true
    private var _normal3D = Matrix3()
    
    private var _inverseNormalDirty = true
    private var _inverseNormal = Matrix3()
    
    private var _inverseNormal3DDirty = true
    private var _inverseNormal3D = Matrix3()
    
    private var _encodedCameraPositionMCDirty = true
    private var _encodedCameraPositionMC = EncodedCartesian3()
    private var _cameraPosition = Cartesian3()
    
    private var _sunPositionWC = Cartesian3()
    private var _sunPositionColumbusView = Cartesian3()
    private var _sunDirectionWC = Cartesian3()
    private var _sunDirectionEC = Cartesian3()
    private var _moonDirectionEC = Cartesian3()
    
    private var _mode: SceneMode? = nil
    private var _mapProjection: MapProjection? = nil
    private var _cameraDirection = Cartesian3()
    private var _cameraRight = Cartesian3()
    private var _cameraUp = Cartesian3()
    private var _frustum2DWidth = 0.0
    private var _eyeHeight2D = Cartesian2()
    
    private var _fogDensity: Float = 1.0
    
    private var _pass: Pass = .Compute
    
    /**
    * @memberof UniformState.prototype
    * @type {BoundingRectangle}
    */
    var viewport: Cartesian4 {
        get {
            return _viewport
        }
        set (value) {
            _viewport = value
            _viewportDirty = true
        }
    }

    var viewportOrthographic: Matrix4 {
        cleanViewport()
        return _viewportOrthographicMatrix
    }
    
    var viewportTransformation: Matrix4 {
        cleanViewport()
        return _viewportTransformation
    }
    
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var model: Matrix4 {
        get {
            return _model
        }
        set (value) {
            
            if _model == value {
                return
            }
            _model = value
            
            _modelView3DDirty = true
            _inverseModelView3DDirty = true
            _inverseModelDirty = true
            _inverseTransposeModelDirty = true
            _modelViewDirty = true
            _inverseModelViewDirty = true
            _viewProjectionDirty = true
            _inverseViewProjectionDirty = true
            _modelViewRelativeToEyeDirty = true
            _inverseModelViewDirty = true
            _modelViewProjectionDirty = true
            _inverseModelViewProjectionDirty = true
            _modelViewProjectionRelativeToEyeDirty = true
            _modelViewInfiniteProjectionDirty = true
            _normalDirty = true
            _inverseNormalDirty = true
            _normal3DDirty = true
            _inverseNormal3DDirty = true
            _encodedCameraPositionMCDirty = true
        }
    }
    /*
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    inverseModel : {
    get : function() {
    if (this._inverseModelDirty) {
    this._inverseModelDirty = false;
    
    Matrix4.inverse(this._model, this._inverseModel);
    }
    
    return this._inverseModel;
    }
    },
    
    /**
    * @memberof UniformState.prototype
    * @private
    */
    inverseTranposeModel : {
    get : function() {
    var m = this._inverseTransposeModel;
    if (this._inverseTransposeModelDirty) {
    this._inverseTransposeModelDirty = false;
    
    Matrix4.getRotation(this.inverseModel, m);
    Matrix3.transpose(m, m);
    }
    
    return m;
    }
    },
    */
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var view: Matrix4 {
        return _view
    }
    
    /**
    * The 3D view matrix.  In 3D mode, this is identical to {@link UniformState#view},
    * but in 2D and Columbus View it is a synthetic matrix based on the equivalent position
    * of the camera in the 3D world.
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var view3D: Matrix4 {
        updateView3D()
        return _view3D
    }
    
    /**
    * The 3x3 rotation matrix of the current view matrix ({@link UniformState#view}).
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    var viewRotation: Matrix3 {
        updateView3D()
        return _viewRotation
    }
    
    /**
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    var viewRotation3D: Matrix3 {
        let _ = view3D
        return _viewRotation3D
    }
    
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var inverseView: Matrix4 {
        return _inverseView
    }
    
    
    /**
    * the 4x4 inverse-view matrix that transforms from eye to 3D world coordinates.  In 3D mode, this is
    * identical to {@link UniformState#inverseView}, but in 2D and Columbus View it is a synthetic matrix
    * based on the equivalent position of the camera in the 3D world.
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var inverseView3D: Matrix4 {
        updateInverseView3D()
        return _inverseView3D
    }

    /*
    /**
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    inverseViewRotation : {
    get : function() {
    return this._inverseViewRotation;
    }
    },
    
    /**
    * The 3x3 rotation matrix of the current 3D inverse-view matrix ({@link UniformState#inverseView3D}).
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    inverseViewRotation3D : {
    get : function() {
    var inverseView = this.inverseView3D;
    return this._inverseViewRotation3D;
    }
    },
    */
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var projection: Matrix4 {
        get {
            return _projection
        }
        set (value) {
            _projection = value
            _inverseProjectionDirty = true
            _inverseProjectionOITDirty = true
            _viewProjectionDirty = true
            _modelViewProjectionDirty = true
            _modelViewProjectionRelativeToEyeDirty = true
        }
    }

    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var inverseProjection: Matrix4 {
        get {
            cleanInverseProjection()
            return _inverseProjection
        }
    }
    /*
    /**
    * @memberof UniformState.prototype
    * @private
    */
    inverseProjectionOIT : {
    get : function() {
    cleanInverseProjectionOIT(this);
    return this._inverseProjectionOIT;
    }
    },
    */
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var infiniteProjection: Matrix4 {
        get {
            return _infiniteProjection
        }
        set (value) {
            _infiniteProjection = value
            _modelViewInfiniteProjectionDirty = true
        }
    }
    
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var modelView: Matrix4 {
        get {
            cleanModelView()
            return _modelView
        }
    }
    
    /**
    * The 3D model-view matrix.  In 3D mode, this is equivalent to {@link UniformState#modelView}.  In 2D and
    * Columbus View, however, it is a synthetic matrix based on the equivalent position of the camera in the 3D world.
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var modelView3D: Matrix4 {
        get {
            cleanModelView3D()
            return _modelView3D
        }
    }
    /*
    /**
    * Model-view relative to eye matrix.
    *
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    modelViewRelativeToEye : {
    get : function() {
    cleanModelViewRelativeToEye(this);
    return this._modelViewRelativeToEye;
    }
    },
    */
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var inverseModelView: Matrix4 {
        get {
            cleanInverseModelView()
            return _inverseModelView
        }
    }
    
    /**
    * The inverse of the 3D model-view matrix.  In 3D mode, this is equivalent to {@link UniformState#inverseModelView}.
    * In 2D and Columbus View, however, it is a synthetic matrix based on the equivalent position of the camera in the 3D world.
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var inverseModelView3D: Matrix4 {
        get {
            cleanInverseModelView3D()
            return _inverseModelView3D
        }
    }
    
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var viewProjection: Matrix4 {
        cleanViewProjection()
        return _viewProjection
    }
    
    
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var inverseViewProjection: Matrix4 {
        cleanInverseViewProjection()
        return _inverseViewProjection
    }
    
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    var modelViewProjection: Matrix4 {
        cleanModelViewProjection()
        return _modelViewProjection
    }
    
    /*
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    inverseModelViewProjection : {
    get : function() {
    cleanInverseModelViewProjection(this);
    return this._inverseModelViewProjection;
    
    }
    },
    
    /**
    * Model-view-projection relative to eye matrix.
    *
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    modelViewProjectionRelativeToEye : {
    get : function() {
    cleanModelViewProjectionRelativeToEye(this);
    return this._modelViewProjectionRelativeToEye;
    }
    },
    
    /**
    * @memberof UniformState.prototype
    * @type {Matrix4}
    */
    modelViewInfiniteProjection : {
    get : function() {
    cleanModelViewInfiniteProjection(this);
    return this._modelViewInfiniteProjection;
    }
    },
    */
    /**
    * A 3x3 normal transformation matrix that transforms normal vectors in model coordinates to
    * eye coordinates.
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    var normal: Matrix3 {
        cleanNormal()
        return _normal
    }

    /**
    * A 3x3 normal transformation matrix that transforms normal vectors in 3D model
    * coordinates to eye coordinates.  In 3D mode, this is identical to
    * {@link UniformState#normal}, but in 2D and Columbus View it represents the normal transformation
    * matrix as if the camera were at an equivalent location in 3D mode.
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    var normal3D: Matrix3 {
        cleanNormal3D()
        return _normal3D
    }
    
    /*
    /**
    * An inverse 3x3 normal transformation matrix that transforms normal vectors in model coordinates
    * to eye coordinates.
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    inverseNormal : {
    get : function() {
    cleanInverseNormal(this);
    return this._inverseNormal;
    }
    },
    
    /**
    * An inverse 3x3 normal transformation matrix that transforms normal vectors in eye coordinates
    * to 3D model coordinates.  In 3D mode, this is identical to
    * {@link UniformState#inverseNormal}, but in 2D and Columbus View it represents the normal transformation
    * matrix as if the camera were at an equivalent location in 3D mode.
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    inverseNormal3D : {
    get : function() {
    cleanInverseNormal3D(this);
    return this._inverseNormal3D;
    }
    },
    */
    /**
    * The near distance (<code>x</code>) and the far distance (<code>y</code>) of the frustum defined by the camera.
    * This is the largest possible frustum, not an individual frustum used for multi-frustum rendering.
    * @memberof UniformState.prototype
    * @type {Cartesian2}
    */
    var entireFrustum: Cartesian2 {
        return _entireFrustum
    }
    /*
    /**
    * The near distance (<code>x</code>) and the far distance (<code>y</code>) of the frustum defined by the camera.
    * This is the individual frustum used for multi-frustum rendering.
    * @memberof UniformState.prototype
    * @type {Cartesian2}
    */
    currentFrustum : {
    get : function() {
    return this._currentFrustum;
    }
    },
    /**
     The distances to the frustum planes. The top, bottom, left and right distances are
             * the x, y, z, and w components, respectively.
             * @memberof UniformState.prototype
             * @type {Cartesian4}
             */
            frustumPlanes : {
                get : function() {
                    return this._frustumPlanes;
                }
            },
    /**
    * The the height (<code>x</code>) and the height squared (<code>y</code>)
    * in meters of the camera above the 2D world plane. This uniform is only valid
    * when the {@link SceneMode} equal to <code>SCENE2D</code>.
    * @memberof UniformState.prototype
    * @type {Cartesian2}
    */
    eyeHeight2D : {
    get : function() {
    return this._eyeHeight2D;
    }
    },
    
    /**
    * The sun position in 3D world coordinates at the current scene time.
    * @memberof UniformState.prototype
    * @type {Cartesian3}
    */
    sunPositionWC : {
    get : function() {
    return this._sunPositionWC;
    }
    },
    
    /**
    * The sun position in 2D world coordinates at the current scene time.
    * @memberof UniformState.prototype
    * @type {Cartesian3}
    */
    sunPositionColumbusView : {
    get : function(){
    return this._sunPositionColumbusView;
    }
    },
    */
    
    /**
    * A normalized vector to the sun in 3D world coordinates at the current scene time.  Even in 2D or
    * Columbus View mode, this returns the position of the sun in the 3D scene.
    * @memberof UniformState.prototype
    * @type {Cartesian3}
    */
    var sunDirectionWC: Cartesian3 {
        return _sunDirectionWC
    }
    
    /**
    * A normalized vector to the sun in eye coordinates at the current scene time.  In 3D mode, this
    * returns the actual vector from the camera position to the sun position.  In 2D and Columbus View, it returns
    * the vector from the equivalent 3D camera position to the position of the sun in the 3D scene.
    * @memberof UniformState.prototype
    * @type {Cartesian3}
    */
    var sunDirectionEC: Cartesian3 {
        return _sunDirectionEC
    }
    
    /**
    * A normalized vector to the moon in eye coordinates at the current scene time.  In 3D mode, this
    * returns the actual vector from the camera position to the moon position.  In 2D and Columbus View, it returns
    * the vector from the equivalent 3D camera position to the position of the moon in the 3D scene.
    * @memberof UniformState.prototype
    * @type {Cartesian3}
    */
    var moonDirectionEC: Cartesian3 {
        get {
            return _moonDirectionEC
        }
    }

    /*
    /**
    * The high bits of the camera position.
    * @memberof UniformState.prototype
    * @type {Cartesian3}
    */
    encodedCameraPositionMCHigh : {
    get : function() {
    cleanEncodedCameraPositionMC(this);
    return this._encodedCameraPositionMC.high;
    }
    },
    
    /**
    * The low bits of the camera position.
    * @memberof UniformState.prototype
    * @type {Cartesian3}
    */
    encodedCameraPositionMCLow : {
    get : function() {
    cleanEncodedCameraPositionMC(this);
    return this._encodedCameraPositionMC.low;
    }
    },
    */
    /**
    * A 3x3 matrix that transforms from True Equator Mean Equinox (TEME) axes to the
    * pseudo-fixed axes at the Scene's current time.
    * @memberof UniformState.prototype
    * @type {Matrix3}
    */
    var temeToPseudoFixedMatrix: Matrix3 {
        return _temeToPseudoFixed
    }
    
    /*
    /**
    * Gets the scaling factor for transforming from the canvas
    * pixel space to canvas coordinate space.
    * @memberof UniformState.prototype
    * @type {Number}
    */
    resolutionScale : {
    get : function() {
    return this._resolutionScale;
    }
    }
    });
    */
    
    var fogDensity: Float {
        return _fogDensity
    }
    
    /**
     * @memberof UniformState.prototype
     * @type {Pass}
     */
    var pass: Float {
        return Float(_pass.rawValue)
    }
    
    func setView(matrix: Matrix4) {
        _view = matrix
        _viewRotation = _view.rotation
        
        _view3DDirty = true
        _inverseView3DDirty = true
        _modelViewDirty = true
        _modelView3DDirty = true
        _modelViewRelativeToEyeDirty = true
        _inverseModelViewDirty = true
        _inverseModelView3DDirty = true
        _viewProjectionDirty = true
        _modelViewProjectionDirty = true
        _modelViewProjectionRelativeToEyeDirty = true
        _modelViewInfiniteProjectionDirty = true
        _normalDirty = true
        _inverseNormalDirty = true
        _normal3DDirty = true
        _inverseNormal3DDirty = true
    }
    
    func setInverseView(matrix: Matrix4) {
        _inverseView = matrix
        _inverseViewRotation = matrix.rotation
    }
    
    func setCamera(_ camera: Camera) {
        _cameraPosition = camera.positionWC
        _cameraDirection = camera.directionWC
        _cameraRight = camera.rightWC
        _cameraUp = camera.upWC
        _encodedCameraPositionMCDirty = true
    }
    
    //var transformMatrix = new Matrix3();
    //var sunCartographicScratch = new Cartographic();
    func setSunAndMoonDirections(frameState: FrameState) {

        var transformMatrix = Matrix3()
        if Transforms.computeIcrfToFixedMatrix(date: frameState.time) == nil {
            transformMatrix = Transforms.computeTemeToPseudoFixedMatrix(date: frameState.time)
        }
        
        _sunPositionWC = transformMatrix.multiply(vector: Simon1994PlanetaryPositions.sharedInstance.computeSunPositionInEarthInertialFrame(date: frameState.time))
        
        _sunDirectionWC = _sunPositionWC.normalize()
        
        _sunDirectionEC = viewRotation3D.multiply(vector: _sunPositionWC).normalize()
        
        _moonDirectionEC = transformMatrix.multiply(vector: Simon1994PlanetaryPositions.sharedInstance.computeMoonPositionInEarthInertialFrame(date: frameState.time)).normalize()
        //_moonDirectionEC = position
        /*Matrix3.multiplyByVector(transformMatrix, position, position);
        Matrix3.multiplyByVector(uniformState.viewRotation3D, position, position);
        Cartesian3.normalize(position, position);
        
        var projection = frameState.mapProjection;
        var ellipsoid = projection.ellipsoid;
        var sunCartographic = ellipsoid.cartesianToCartographic(uniformState._sunPositionWC, sunCartographicScratch);
        projection.project(sunCartographic, uniformState._sunPositionColumbusView)*/
    }
    
    func updatePass (_ pass: Pass) {
        _pass = pass
    }
    
    /**
    * Synchronizes the frustum's state with the uniform state.  This is called
    * by the {@link Scene} when rendering to ensure that automatic GLSL uniforms
    * are set to the right value.
    *
    * @param {Object} frustum The frustum to synchronize with.
    */
    func updateFrustum (_ frustum: Frustum) {
        var frustum = frustum
        projection = frustum.projectionMatrix
        if frustum.infiniteProjectionMatrix != nil {
            infiniteProjection = frustum.infiniteProjectionMatrix!
        }
        _currentFrustum.x = frustum.near
        _currentFrustum.y = frustum.far
    
        if frustum.top != Double.nan {
            frustum = (frustum as! PerspectiveFrustum)._offCenterFrustum
        }
        
        _frustumPlanes.x = frustum.top
        _frustumPlanes.y = frustum.bottom
        _frustumPlanes.z = frustum.left
        _frustumPlanes.w = frustum.right
    }
    
    /**
    * Synchronizes frame state with the uniform state.  This is called
    * by the {@link Scene} when rendering to ensure that automatic GLSL uniforms
    * are set to the right value.
    *
    * @param {FrameState} frameState The frameState to synchronize with.
    */
    func update(context: Context, frameState: FrameState) {
        
        self.frameState = frameState
        _mode = self.frameState.mode
        _mapProjection = self.frameState.mapProjection

        let camera = frameState.camera!
        
        setView(matrix: camera.viewMatrix)
        setInverseView(matrix: camera.inverseViewMatrix)
        setCamera(camera)
        
        if self.frameState.mode == SceneMode.Scene2D {
            _frustum2DWidth = camera.frustum.right - camera.frustum.left
            _eyeHeight2D.x = _frustum2DWidth * 0.5
            _eyeHeight2D.y = _eyeHeight2D.x * _eyeHeight2D.x
        } else {
            _frustum2DWidth = 0.0
            _eyeHeight2D.x = 0.0
            _eyeHeight2D.y = 0.0
        }
        
        //FIXME: setSunAndMoonDirections
        setSunAndMoonDirections(frameState: self.frameState)
        
        _entireFrustum.x = camera.frustum.near
        _entireFrustum.y = camera.frustum.far
        updateFrustum(camera.frustum)
        
        _fogDensity = Float(frameState.fog.density)
        
        _temeToPseudoFixed = Transforms.computeTemeToPseudoFixedMatrix(date: self.frameState.time!)
    }
    
    func setAutomaticUniforms (buffer: Buffer) {
        var layout = AutomaticUniformBufferLayout()
        
        layout.czm_a_viewRotation = viewRotation.floatRepresentation
        layout.czm_a_temeToPseudoFixed = temeToPseudoFixedMatrix.floatRepresentation
        layout.czm_a_sunDirectionEC = sunDirectionEC.floatRepresentation
        layout.czm_a_sunDirectionWC = sunDirectionWC.floatRepresentation
        layout.czm_a_moonDirectionEC = moonDirectionEC.floatRepresentation
        layout.czm_a_viewerPositionWC = inverseView.translation.floatRepresentation
        layout.czm_a_morphTime = Float(frameState.morphTime)
        layout.czm_a_fogDensity = fogDensity
        layout.czm_a_frameNumber = Float(frameState.frameNumber)
        layout.czm_a_pass = pass
        
        memcpy(buffer.data, &layout, sizeof(AutomaticUniformBufferLayout))
        
    }
    
    func setFrustumUniforms (buffer: Buffer) {

        var layout = FrustumUniformBufferLayout()
        
        layout.czm_f_viewportOrthographic = viewportOrthographic.floatRepresentation
        layout.czm_f_viewportTransformation = viewportTransformation.floatRepresentation
        layout.czm_f_projection = projection.floatRepresentation
        layout.czm_f_inverseProjection = inverseProjection.floatRepresentation
        layout.czm_f_view = view.floatRepresentation
        layout.czm_f_modelView = modelView.floatRepresentation
        layout.czm_f_modelView3D = modelView3D.floatRepresentation
        layout.czm_f_inverseModelView = inverseModelView.floatRepresentation
        layout.czm_f_modelViewProjection = modelViewProjection.floatRepresentation
        layout.czm_f_viewport = viewport.floatRepresentation
        layout.czm_f_normal = normal.floatRepresentation
        layout.czm_f_normal3D = normal3D.floatRepresentation
        layout.czm_f_entireFrustum = entireFrustum.floatRepresentation
        memcpy(buffer.data, &layout, sizeof(FrustumUniformBufferLayout))
    }
    
    func cleanViewport() {
        if _viewportDirty {
            _viewportOrthographicMatrix = Matrix4.computeOrthographicOffCenter(left: _viewport.x, right: _viewport.x + _viewport.width, bottom: _viewport.y, top: _viewport.y + _viewport.height)
            _viewportTransformation = Matrix4.computeViewportTransformation(viewport: _viewport)
            _viewportDirty = false
        }
    }
    
    func cleanInverseProjection() {
        if _inverseProjectionDirty {
            _inverseProjectionDirty = false
            
            _inverseProjection = _projection.inverse
        }
    }
    /*
    function cleanInverseProjectionOIT(uniformState) {
    if (uniformState._inverseProjectionOITDirty) {
    uniformState._inverseProjectionOITDirty = false;
    
    if (uniformState._mode !== SceneMode.SCENE2D && uniformState._mode !== SceneMode.MORPHING) {
    Matrix4.inverse(uniformState._projection, uniformState._inverseProjectionOIT);
    } else {
    Matrix4.clone(Matrix4.IDENTITY, uniformState._inverseProjectionOIT);
    }
    }
    }
    */
    // Derived
    func cleanModelView() {
        if _modelViewDirty {
            _modelViewDirty = false
            _modelView = _view.multiply(_model)
        }
    }
    
    func cleanModelView3D() {
        if _modelView3DDirty {
            _modelView3DDirty = false
            _modelView3D = view3D.multiply(_model)
        }
    }
    
    func cleanInverseModelView() {
        if _inverseModelViewDirty {
            _inverseModelViewDirty = false
            _inverseModelView = modelView.inverse
        }
    }
    
    func cleanInverseModelView3D() {
        if _inverseModelView3DDirty {
            _inverseModelView3DDirty = false
            _inverseModelView3D = modelView3D.inverse
        }
    }
    
    func cleanViewProjection() {
        if (_viewProjectionDirty) {
            _viewProjectionDirty = false
            _viewProjection = _projection.multiply(_view)
        }
    }
    
    func cleanInverseViewProjection() {
        if (_inverseViewProjectionDirty) {
            _inverseViewProjectionDirty = false
            _inverseViewProjection = viewProjection.inverse
        }
    }
    
    func cleanModelViewProjection() {
        if _modelViewProjectionDirty {
            _modelViewProjectionDirty = false
            _modelViewProjection = _projection.multiply(modelView)
        }
    }
    /*
    function cleanModelViewRelativeToEye(uniformState) {
    if (uniformState._modelViewRelativeToEyeDirty) {
    uniformState._modelViewRelativeToEyeDirty = false;
    
    var mv = uniformState.modelView;
    var mvRte = uniformState._modelViewRelativeToEye;
    mvRte[0] = mv[0];
    mvRte[1] = mv[1];
    mvRte[2] = mv[2];
    mvRte[3] = mv[3];
    mvRte[4] = mv[4];
    mvRte[5] = mv[5];
    mvRte[6] = mv[6];
    mvRte[7] = mv[7];
    mvRte[8] = mv[8];
    mvRte[9] = mv[9];
    mvRte[10] = mv[10];
    mvRte[11] = mv[11];
    mvRte[12] = 0.0;
    mvRte[13] = 0.0;
    mvRte[14] = 0.0;
    mvRte[15] = mv[15];
    }
    }
    
    function cleanInverseModelViewProjection(uniformState) {
    if (uniformState._inverseModelViewProjectionDirty) {
    uniformState._inverseModelViewProjectionDirty = false;
    
    Matrix4.inverse(uniformState.modelViewProjection, uniformState._inverseModelViewProjection);
    }
    }
    
    function cleanModelViewProjectionRelativeToEye(uniformState) {
    if (uniformState._modelViewProjectionRelativeToEyeDirty) {
    uniformState._modelViewProjectionRelativeToEyeDirty = false;
    
    Matrix4.multiply(uniformState._projection, uniformState.modelViewRelativeToEye, uniformState._modelViewProjectionRelativeToEye);
    }
    }
    
    function cleanModelViewInfiniteProjection(uniformState) {
    if (uniformState._modelViewInfiniteProjectionDirty) {
    uniformState._modelViewInfiniteProjectionDirty = false;
    
    Matrix4.multiply(uniformState._infiniteProjection, uniformState.modelView, uniformState._modelViewInfiniteProjection);
    }
    }
    */
    func cleanNormal() {
        if (_normalDirty) {
            _normalDirty = false
            _normal = inverseModelView.rotation.transpose
        }
    }

    func cleanNormal3D() {
        if _normal3DDirty {
            _normal3DDirty = false;
            _normal3D = inverseModelView3D.rotation.transpose
        }
    }
    /*
    function cleanInverseNormal(uniformState) {
    if (uniformState._inverseNormalDirty) {
    uniformState._inverseNormalDirty = false;
    
    Matrix4.getRotation(uniformState.inverseModelView, uniformState._inverseNormal);
    }
    }
    
    function cleanInverseNormal3D(uniformState) {
    if (uniformState._inverseNormal3DDirty) {
    uniformState._inverseNormal3DDirty = false;
    
    Matrix4.getRotation(uniformState.inverseModelView3D, uniformState._inverseNormal3D);
    }
    }
    
    var cameraPositionMC = new Cartesian3();
    
    function cleanEncodedCameraPositionMC(uniformState) {
    if (uniformState._encodedCameraPositionMCDirty) {
    uniformState._encodedCameraPositionMCDirty = false;
    
    Matrix4.multiplyByPoint(uniformState.inverseModel, uniformState._cameraPosition, cameraPositionMC);
    EncodedCartesian3.fromCartesian(cameraPositionMC, uniformState._encodedCameraPositionMC);
    }
    }
    
    var view2Dto3DPScratch = new Cartesian3();
    var view2Dto3DRScratch = new Cartesian3();
    var view2Dto3DUScratch = new Cartesian3();
    var view2Dto3DDScratch = new Cartesian3();
    var view2Dto3DCartographicScratch = new Cartographic();
    var view2Dto3DCartesian3Scratch = new Cartesian3();
    var view2Dto3DMatrix4Scratch = new Matrix4();
    */
    func view2Dto3D(position2D: Cartesian3, direction2D: Cartesian3, right2D: Cartesian3, up2D: Cartesian3, frustum2DWidth: Double, mode: SceneMode, projection: MapProjection) -> Matrix4 {
        
        // The camera position and directions are expressed in the 2D coordinate system where the Y axis is to the East,
        // the Z axis is to the North, and the X axis is out of the map.  Express them instead in the ENU axes where
        // X is to the East, Y is to the North, and Z is out of the local horizontal plane.
        var p = Cartesian3(x: position2D.y, y: position2D.z, z: position2D.x)
        
        var r = Cartesian3(x: right2D.y, y: right2D.z, z: right2D.x)
        
        var u = Cartesian3(x: up2D.y, y: up2D.z, z: up2D.x)
        
        var d = Cartesian3(x: direction2D.y, y: direction2D.z, z: direction2D.x)
        
        // In 2D, the camera height is always 12.7 million meters.
        // The apparent height is equal to half the frustum width.
        if mode == .Scene2D {
            p.z = frustum2DWidth * 0.5
        }
        
        // Compute the equivalent camera position in the real (3D) world.
        // In 2D and Columbus View, the camera can travel outside the projection, and when it does so
        // there's not really any corresponding location in the real world.  So clamp the unprojected
        // longitude and latitude to their valid ranges.
        var cartographic = projection.unproject(cartesian: p)
        cartographic.longitude = Math.clamp(cartographic.longitude, min: -M_PI, max: M_PI)
        cartographic.latitude = Math.clamp(cartographic.latitude, min: -M_PI_2, max: M_PI_2)
        let position3D = projection.ellipsoid.cartographicToCartesian(cartographic)
        
        // Compute the rotation from the local ENU at the real world camera position to the fixed axes.
        let enuToFixed = Transforms.eastNorthUpToFixedFrame(origin: position3D, ellipsoid: projection.ellipsoid)
        
        // Transform each camera direction to the fixed axes.
        r = enuToFixed.multiply(pointAsVector: r)
        u = enuToFixed.multiply(pointAsVector: u)
        d = enuToFixed.multiply(pointAsVector: d)
        
        // Compute the view matrix based on the new fixed-frame camera position and directions.
        return Matrix4(
            r.x, u.x, -d.x, 0.0,
            r.y, u.y, -d.y, 0.0,
            r.z, u.z, -d.z, 0.0,
            -r.dot(position3D), -u.dot(position3D), d.dot(position3D), 1.0)
    }
    
    private func updateView3D () {
        if _view3DDirty {
            if _mode == .Scene3D {
                _view3D = _view
            } else {
                _view3D = view2Dto3D(position2D: _cameraPosition, direction2D: _cameraDirection, right2D: _cameraRight, up2D: _cameraUp, frustum2DWidth: _frustum2DWidth, mode: _mode!, projection: _mapProjection!)
            }
            _viewRotation3D = _view3D.rotation
            _view3DDirty = false
        }
    }
    
    private func updateInverseView3D () {
        if _inverseView3DDirty {
            _inverseView3D = view3D.inverse
            _inverseViewRotation3D = _inverseView3D.rotation
            _inverseView3DDirty = false
        }
    }

}