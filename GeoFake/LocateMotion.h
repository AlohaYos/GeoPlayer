//
//  LocateMotion.h
//  MotionLog
//
//  Created by Yos Hashimoto on 2013/12/07.
//  Copyright (c) 2013年 Newton Japan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "GFHeading.h"

@interface LocateMotion : NSObject

@property (nonatomic, strong)	CLLocation*			location;
@property (nonatomic, strong)	GFHeading*			heading;
@property (nonatomic, strong)	CMMotionActivity*	activity;
@property (nonatomic, strong)	NSDate*				timestamp;
@property (nonatomic, assign)	BOOL				segmentStart;

- (id)initWithLocation:(CLLocation*)location heading:(CLHeading*)heading activity:(CMMotionActivity*)activity;
- (BOOL)isSameActivity:(LocateMotion*)anotherLocateMotion;

@end
