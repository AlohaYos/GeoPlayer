
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface GpxItem : NSObject

@property (nonatomic, strong) NSString*	lat;
@property (nonatomic, strong) NSString*	lon;
@property (nonatomic, strong) NSString*	magvar;
@property (nonatomic, strong) NSString*	ele;
@property (nonatomic, strong) NSString*	time;
@property (nonatomic, strong) NSString*	extensions;

@property (nonatomic, strong) NSDate*				timestamp;

// Location
@property (nonatomic, assign) CLLocationDegrees		latitude;
@property (nonatomic, assign) CLLocationDegrees		longitude;
@property (nonatomic, assign) CLLocationDirection	heading;
@property (nonatomic, assign) CLLocationDistance	altitude;

// Motion Activity
@property (nonatomic, assign) BOOL					stationary;
@property (nonatomic, assign) BOOL					walking;
@property (nonatomic, assign) BOOL					running;
@property (nonatomic, assign) BOOL					automotive;
@property (nonatomic, assign) BOOL					unknown;
@property (nonatomic, assign) CMMotionActivityConfidence	confidence;

@property (nonatomic, assign) BOOL					segmentStart;

@end
