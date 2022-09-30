
#import "GpxItem.h"

@implementation GpxItem

-(id)init {
	self =  [super init];

	_stationary = NO;
	_walking = NO;
	_running = NO;
	_automotive = NO;
	_unknown = NO;
	_confidence = CMMotionActivityConfidenceLow;

	_segmentStart = NO;
	
	return self;
}

@end
