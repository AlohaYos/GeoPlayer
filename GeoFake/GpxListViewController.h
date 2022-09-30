
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "GpxManager.h"
#import "GeoFakeViewController.h"

@interface GpxListViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic,weak)		GeoFakeViewController*	delegate;
@property (nonatomic,weak)		GpxManager*				gpxManager;

@end
