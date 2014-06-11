//
//  CSProjection.m
//  CesiumKit
//
//  Created by Ryan Walklin on 8/05/14.
//  Copyright (c) 2014 Ryan Walklin. All rights reserved.
//

#import "CSProjection.h"
#import "CSProjection+Private.h"

#import "Ellipsoid.h"


@implementation CSProjection

-(id)initWithEllipsoid:(Ellipsoid *)ellipsoid
{
    self = [super init];
    if (self)
    {
        if (!ellipsoid)
        {
            ellipsoid = [Ellipsoid wgs84Ellipsoid];
        }
        _semimajorAxis = ellipsoid.maximumRadius;
        _oneOverSemimajorAxis = 1.0 / _semimajorAxis;
    }
    return self;
}

/**
 * Converts geodetic ellipsoid coordinates, in radians, to the equivalent Web Mercator
 * X, Y, Z coordinates expressed in meters and returned in a {@link Cartesian3}.  The height
 * is copied unmodified to the Z coordinate.
 *
 * @memberof Projection
 *
 * @param {Cartographic} cartographic The cartographic coordinates in radians.
 * @param {Cartesian3} [result] The instance to which to copy the result, or undefined if a
 *        new instance should be created.
 * @returns {Cartesian3} The equivalent web mercator X, Y, Z coordinates, in meters.
 */
-(Cartesian3 *)project:(CSCartographic *)cartographic3
{
    NSAssert(NO, @"Invalid base class");
    return nil;
}


/**
 * Converts Web Mercator X, Y coordinates, expressed in meters, to a {@link Cartographic}
 * containing geodetic ellipsoid coordinates.  The Z coordinate is copied unmodified to the
 * height.
 *
 * @memberof Projection
 *
 * @param {Cartesian2} cartesian The web mercator coordinates in meters.
 * @param {Cartographic} [result] The instance to which to copy the result, or undefined if a
 *        new instance should be created.
 * @returns {Cartographic} The equivalent cartographic coordinates.
 */
-(CSCartographic *)unproject:(Cartesian3 *)cartesian
{
    NSAssert(NO, @"Invalid base class");
    return nil;
}

@end
