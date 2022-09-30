//
//  GeoFakeViewController.h
//  GeoFake
//
//  Created by Yos Hashimoto on 2013/12/26.
//  Copyright (c) 2013年 Newton Japan. All rights reserved.
//

#define USE_iBEACON				1

#define kPATH_DOCUMENTS			@"/Documents"
#define kPATH_DATA				@"/data"
#define kBEACON_FILE			@"/beacon_list.plist"

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "NJStoreKit.h"
#import "UIAlertView+Blocks.h"
#import "UIAlertView+Show.h"

@interface GeoFakeViewController : UIViewController <MCBrowserViewControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate, CBPeripheralManagerDelegate, UITextFieldDelegate>

- (void)closeGpxListPageWithName:(NSString*)gpxFileName;
- (void)preparePlaybackFor:(NSString*)gpxFileName;

@end
