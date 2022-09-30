//
//  LocateMotion.m
//  MotionLog
//
//  Created by Yos Hashimoto on 2013/12/07.
//  Copyright (c) 2013年 Newton Japan. All rights reserved.
//

#import "LocateMotion.h"

@implementation LocateMotion

- (id)initWithLocation:(CLLocation*)location heading:(CLHeading *)heading activity:(CMMotionActivity*)activity {

	_location = location;
	_activity = activity;
	
	_heading = [GFHeading alloc];
	_heading.magneticHeading = heading.magneticHeading;
	_heading.trueHeading = heading.trueHeading;
	_heading.headingAccuracy = heading.headingAccuracy;
	_heading.x = heading.x;
	_heading.y = heading.y;
	_heading.z = heading.z;
	_heading.timestamp = [NSDate dateWithTimeInterval:0 sinceDate:heading.timestamp];

	_timestamp = location.timestamp;

	_segmentStart = NO;
	
	return self;
}

- (BOOL)isSameActivity:(LocateMotion*)lm {
	if(
	   (_activity.stationary == lm.activity.stationary) &&
	   (_activity.walking == lm.activity.walking) &&
	   (_activity.running == lm.activity.running) &&
	   (_activity.automotive == lm.activity.automotive) &&
	   (_activity.unknown == lm.activity.unknown)
	   ) {
		return YES;
	}
	
	return NO;
}

@end

