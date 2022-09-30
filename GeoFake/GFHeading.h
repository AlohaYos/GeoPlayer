//
//  GFHeading.h
//  GeoFake
//
//  Created by Yos Hashimoto on 2013/12/28.
//  Copyright (c) 2013年 Newton Japan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GFHeading : CLHeading

@property(readwrite, nonatomic) CLLocationDirection magneticHeading;
@property(readwrite, nonatomic) CLLocationDirection trueHeading;
@property(readwrite, nonatomic) CLLocationDirection headingAccuracy;
@property(readwrite, nonatomic) CLHeadingComponentValue x;
@property(readwrite, nonatomic) CLHeadingComponentValue y;
@property(readwrite, nonatomic) CLHeadingComponentValue z;
@property(readwrite, nonatomic) NSDate *timestamp;

@end
