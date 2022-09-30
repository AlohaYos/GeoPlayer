
#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface GFMotionActivity : CMMotionActivity
@property(readwrite, nonatomic) BOOL stationary;
@property(readwrite, nonatomic) BOOL walking;
@property(readwrite, nonatomic) BOOL running;
@property(readwrite, nonatomic) BOOL automotive;
@property(readwrite, nonatomic) BOOL unknown;
@property(readwrite, nonatomic) CMMotionActivityConfidence confidence;
@property(readwrite, nonatomic) NSDate *startDate;
@end


