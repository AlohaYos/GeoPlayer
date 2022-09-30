//
//  GeoFakeViewController.m
//  GeoFake
//
//  Created by Yos Hashimoto on 2013/12/26.
//  Copyright (c) 2013年 Newton Japan. All rights reserved.
//

//#define GEOFAKE_DEBUG
#define INAPP_PURCHASE
//#define SET_MOTION_STATUS_IN_RUNKEEPER_DATA
#define AUTO_SAVE_INTERVAL	60

#import "GeoFakeAppDelegate.h"
#import "GeoFakeViewController.h"
#import "GpxListViewController.h"
#import "Gpx.h"
#import "LocateMotion.h"
#import "GFMotionActivity.h"
#import "BuyContentViewController.h"

#ifdef GEOFAKE_DEBUG
#import <GeoFake/GeoFake.h>
#endif

#define kConnectingTimerMax	60

typedef enum {
	runningModeRecording = 0,
	runningModePlayback,
	runningModeManual,
	runningModeSetting,
} GFrunningMode;

//------------------------------------------------------------------------------------

#pragma mark - ColorPolyline class

@interface ColorPolyline : MKPolyline
@property (strong, nonatomic) UIColor	*drawColor;
@end

@implementation ColorPolyline
@end

//------------------------------------------------------------------------------------

#pragma mark - Beacon Annotation

@interface BeaconAnnotation : NSObject <MKAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D	coordinate;
@property (nonatomic, strong) NSString*					title;
@property (nonatomic, strong) NSString*					subtitle;
//@property (nonatomic, strong) NSString*					uuid;
//@property (nonatomic, strong) NSString*					major;
//@property (nonatomic, strong) NSString*					minor;
@property (nonatomic, strong) NSDictionary*				beaconInfo;
@end

@implementation BeaconAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord {
	if( nil != (self = [super  init]) ){
		self.coordinate = coord;
		self.title = @"";
		self.subtitle = @"";
//		self.uuid  = @"";
//		self.major = @"";
//		self.minor = @"";
		self.beaconInfo = nil;
	}
	return self;
}

@end

@interface BeaconAnnotationView : MKAnnotationView
@end

@implementation BeaconAnnotationView
- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString*)reuseIdentifier
{
	self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	if( self ){
		UIImage* image = [UIImage imageNamed:@"beacon"];
		self.frame = CGRectMake(self.frame.origin.x,self.frame.origin.y,image.size.width,image.size.height);
		self.image = image;
	}
	return self;
}
@end

#pragma mark - Center Annotation

@interface CenterAnnotation : NSObject <MKAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@end

@implementation CenterAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord {
	if( nil != (self = [super  init]) ){
		self.coordinate = coord;
	}
	return self;
}

@end

@interface CenterAnnotationView : MKAnnotationView
@end

@implementation CenterAnnotationView
- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString*)reuseIdentifier
{
	self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	if( self ){
		UIImage* image = [UIImage imageNamed:@"target"];
		self.frame = CGRectMake(self.frame.origin.x,self.frame.origin.y,image.size.width,image.size.height);
		self.image = image;
	}
	return self;
}
@end

//------------------------------------------------------------------------------------

#pragma mark - GeoFakeViewController

@interface GeoFakeViewController ()
@property (weak, nonatomic) IBOutlet UIView *overScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

@property (weak, nonatomic) IBOutlet UILabel *scrollRecordLabel;
@property (weak, nonatomic) IBOutlet UILabel *scrollPlaybackLabel;
@property (weak, nonatomic) IBOutlet UILabel *scrollManualLabel;
@property (weak, nonatomic) IBOutlet UILabel *scrollSettingLabel;

@property (weak, nonatomic) IBOutlet UIToolbar *playbackToolbar;
@property (weak, nonatomic) IBOutlet UIToolbar *recordingToolbar;
@property (weak, nonatomic) IBOutlet UIToolbar *manualToolbar;
@property (weak, nonatomic) IBOutlet UILabel *connectLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIImageView *mapCenterImage;
@property (weak, nonatomic) IBOutlet UIImageView *mapCenterPlaybackImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *ffButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rewButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *recButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loadButton;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property (weak, nonatomic) IBOutlet UIView *settingBaseView;
@property (weak, nonatomic) IBOutlet UISwitch *headingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *beaconSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *coreLocationActivitySegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *annotationIntervalSegment;
@property (weak, nonatomic) IBOutlet UISwitch *clientConnectSwitch;

@property (weak, nonatomic) IBOutlet UIView *infoBaseView;
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property (weak, nonatomic) IBOutlet UIView *infoLabelView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UIView *beaconSettingBaseView;
@property (weak, nonatomic) IBOutlet UITextField *beaconUuidText;
@property (weak, nonatomic) IBOutlet UITextField *beaconMajorText;
@property (weak, nonatomic) IBOutlet UITextField *beaconMinorText;
@property (weak, nonatomic) IBOutlet UITextField *beaconNameText;
@property (weak, nonatomic) IBOutlet UISegmentedControl *beaconRadiusSegment;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *beaconAddButton;

@end

@implementation GeoFakeViewController {
	MCPeerID	*_myPeerID;
	MCSession	*_session;
	MCBrowserViewController	*_browserVC;

	CLLocationCoordinate2D _centerLocation;
	CenterAnnotation	*_centerAnnotation;
	
	GpxManager*		_gpxManager;
	Gpx*			_aGpx;
	BOOL			_isPlaying;
	BOOL			_isRecording;
	BOOL			_isSegmentTop;
	BOOL			_isRealTimeScale;
	BOOL			_isSendHeading;
	BOOL			_isClientConnectAvailable;
	int				_runningMode;
	int				_annotationInterval;
	BOOL			_acceptLongTimeRecording;

	CLLocationManager		*_locationManager;
	NSMutableArray			*_locationItems;
	NSMutableArray			*_locationItemsForSaving;
	CMMotionActivityManager *_activityManager;
	CMMotionActivity		*_motionActivity;
	CLHeading				*_currentHeading;
	BOOL					_deferredLocationUpdates;
	NSString				*_lastAnnotation;
	int						connectingTimer;
//	BOOL					isClientConnectGranted;
	
	NSTimer					*_recSaveTimer;

	CBPeripheralManager*	_peripheralManager;
	BOOL					_beaconing;
	NSMutableArray*			_beaconArray;
	NSDictionary*			_currentBeacon;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

//	isClientConnectGranted = NO;

	_myPeerID = [[MCPeerID alloc] initWithDisplayName:@"GeoPlayer"];
	_session = [[MCSession alloc] initWithPeer:_myPeerID];
	_session.delegate = (id<MCSessionDelegate>)self;
	_browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"GeoFake" session:_session];
	_browserVC.delegate = self;
	
	_gpxManager = [GpxManager new];
	
	_isPlaying = NO;
	_isRecording = NO;
	_isSegmentTop = YES;
	_isRealTimeScale = NO;
	_isSendHeading = NO;
	_isClientConnectAvailable = NO;
	_acceptLongTimeRecording = NO;
	_headingSwitch.on = _isSendHeading;
	
	_scrollView.contentSize = CGSizeMake(400, _scrollView.bounds.size.height);
	_scrollView.contentOffset = CGPointMake(80, 0);
	_scrollView.pagingEnabled = YES;

	UISwipeGestureRecognizer *swipeG;
	swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toolbarSwipeRight:)];
	swipeG.direction = UISwipeGestureRecognizerDirectionRight;
	[_overScrollView addGestureRecognizer:swipeG];
	
	swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toolbarSwipeLeft:)];
	swipeG.direction = UISwipeGestureRecognizerDirectionLeft;
	[_overScrollView addGestureRecognizer:swipeG];

	swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toolbarSwipeRight:)];
	swipeG.direction = UISwipeGestureRecognizerDirectionRight;
	[_playbackToolbar addGestureRecognizer:swipeG];
	
	swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toolbarSwipeLeft:)];
	swipeG.direction = UISwipeGestureRecognizerDirectionLeft;
	[_playbackToolbar addGestureRecognizer:swipeG];
	
	swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toolbarSwipeRight:)];
	swipeG.direction = UISwipeGestureRecognizerDirectionRight;
	[_recordingToolbar addGestureRecognizer:swipeG];
	
	swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toolbarSwipeLeft:)];
	swipeG.direction = UISwipeGestureRecognizerDirectionLeft;
	[_recordingToolbar addGestureRecognizer:swipeG];
	
	swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toolbarSwipeRight:)];
	swipeG.direction = UISwipeGestureRecognizerDirectionRight;
	[_manualToolbar addGestureRecognizer:swipeG];
	
	swipeG = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toolbarSwipeLeft:)];
	swipeG.direction = UISwipeGestureRecognizerDirectionLeft;
	[_manualToolbar addGestureRecognizer:swipeG];
	
	[self setModeSwitchTo:runningModePlayback];

	_locationItems = [NSMutableArray array];
	_locationItemsForSaving = [NSMutableArray array];
	_motionActivity = nil;
	_deferredLocationUpdates = NO;
	_lastAnnotation = @"";
	
	_locationManager = [[CLLocationManager alloc] init];
	_locationManager.delegate = self;
	_locationManager.distanceFilter = kCLDistanceFilterNone;
	_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	
	[self showInfoBaseView:NO];

#ifdef INAPP_PURCHASE
	connectingTimer = kConnectingTimerMax;
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(generalTimeJob) userInfo:nil repeats:YES];
#endif
	
	[self renameAutoSaveFileToTimestampName];	// 自動保存されているGpxがあれば、リネームする

#if USE_iBEACON==1
	// ビーコン
	_beaconArray = [[NSMutableArray alloc] init];
	[self loadBeaconData];
	_peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
	_beaconing = NO;
#endif
}

- (void)viewDidLayoutSubviews {
	[self loadSettingValue];
	[self getSettingValue];
	_mapCenterImage.frame = _mapView.frame;
	_mapCenterPlaybackImage.frame = _mapView.frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Setting values

- (IBAction)clientConnectSwitchValueChanged:(id)sender {
	_isClientConnectAvailable = _clientConnectSwitch.on;
	_connectButton.hidden = !_isClientConnectAvailable;
}

- (IBAction)beaconSwitchValueChanged:(id)sender {
}

- (void)getSettingValue {
	// ヘディング情報送信On/Off
	_isSendHeading = _headingSwitch.on;
	_isClientConnectAvailable = _clientConnectSwitch.on;
	_connectButton.hidden = !_isClientConnectAvailable;
	
	_beaconAddButton.enabled = _beaconSwitch.on;
	
	// コアロケーション・アクティビティ
	switch (_coreLocationActivitySegment.selectedSegmentIndex) {
		case 0:
		default:
			_locationManager.activityType = CLActivityTypeFitness;
			break;
		case 1:
			_locationManager.activityType = CLActivityTypeAutomotiveNavigation;
			break;
	}
	
	switch (_annotationIntervalSegment.selectedSegmentIndex) {
		case 0:
			_annotationInterval = 5;
			break;
		case 1:
		default:
			_annotationInterval = 10;
			break;
		case 2:
			_annotationInterval = 30;
			break;
		case 3:
			_annotationInterval = INT32_MAX;
			break;
	}
}

- (void)saveSettingValue
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:_coreLocationActivitySegment.selectedSegmentIndex+1 forKey:@"coreLocationActivityType0"];
	[defaults setInteger:_annotationIntervalSegment.selectedSegmentIndex+1 forKey:@"annotationInterval0"];
	[defaults setBool:_headingSwitch.on forKey:@"headingSwitch0"];
	[defaults setBool:_clientConnectSwitch.on forKey:@"clientConnectSwitch0"];
	[defaults setBool:_beaconSwitch.on forKey:@"beaconSwitch0"];
}

- (void)loadSettingValue
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	_coreLocationActivitySegment.selectedSegmentIndex = [defaults integerForKey:@"coreLocationActivityType0"]-1;
	if(_coreLocationActivitySegment.selectedSegmentIndex<0)
		_coreLocationActivitySegment.selectedSegmentIndex = 0;
	
	_annotationIntervalSegment.selectedSegmentIndex = [defaults integerForKey:@"annotationInterval0"]-1;
	if(_annotationIntervalSegment.selectedSegmentIndex<0)
		_annotationIntervalSegment.selectedSegmentIndex = 1;
	
	_headingSwitch.on = [defaults boolForKey:@"headingSwitch0"];
	_clientConnectSwitch.on = [defaults boolForKey:@"clientConnectSwitch0"];
	_beaconSwitch.on = [defaults boolForKey:@"beaconSwitch0"];
}


#pragma mark - Mode change

- (void)toolbarSwipeRight:(UISwipeGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateEnded) {
		
		int index = _scrollView.contentOffset.x / 80;
		index--;
		if(index<0) {
			index = 0;
		}
		else {
			[self setModeSwitchTo:index];
		}
	}
}

- (void)toolbarSwipeLeft:(UISwipeGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateEnded) {
		
		int index = _scrollView.contentOffset.x / 80;
		index++;
		if(index>3) {
			index = 3;
		}
		else {
			[self setModeSwitchTo:index];
		}
	}
}


- (void)setModeSwitchTo:(int)index {
	
	if(_isPlaying) {
		[self playButtonPushed:nil];
	}
	
	if(_isRecording) {
		[self recButtonPushed:nil];
	}

	_runningMode = index;
	
	CGPoint offset = _scrollView.contentOffset;
	offset.x = _runningMode*80;
	[_scrollView setContentOffset:offset animated:YES];
	
	//UIColor*	activeColor = [UIColor colorWithRed:255.0/255.0f green:153.0/255.0f blue:0.0/255.0f alpha:1.0];
	UIColor*	activeColor = [UIColor colorWithRed:255.0/255.0f green:255.0/255.0f blue:255.0/255.0f alpha:1.0];
	UIColor*	inactiveColor = [UIColor colorWithRed:255.0/255.0f green:255.0/255.0f blue:255.0/255.0f alpha:1.0];
	
	CGRect screen = [[UIScreen mainScreen] bounds];
	CGRect recFrame = _recordingToolbar.frame;
	CGRect playFrame = _playbackToolbar.frame;
	CGRect manuFrame = _manualToolbar.frame;
	
	recFrame.origin.y = screen.size.height-recFrame.size.height;
	playFrame.origin.y = screen.size.height-playFrame.size.height;
	manuFrame.origin.y = screen.size.height-manuFrame.size.height;
	
	_recordingToolbar.frame = recFrame;
	_playbackToolbar.frame = playFrame;
	_manualToolbar.frame = manuFrame;
	
	[UIView animateWithDuration:0.3f
					 animations:^{
						 CGRect setupFrame = _settingBaseView.frame;

						 _scrollRecordLabel.textColor = inactiveColor;
						 _scrollPlaybackLabel.textColor = inactiveColor;
						 _scrollManualLabel.textColor = inactiveColor;
						 _scrollSettingLabel.textColor = inactiveColor;
						 
						 _scrollRecordLabel.alpha = 0.4;
						 _scrollPlaybackLabel.alpha = 0.4;
						 _scrollManualLabel.alpha = 0.4;
						 _scrollSettingLabel.alpha = 0.4;
						 
						 _recordingToolbar.alpha = 0.0;
						 _playbackToolbar.alpha = 0.0;
						 _manualToolbar.alpha = 0.0;
						 
						 setupFrame.origin.x = screen.size.width;
						 
						 switch (_runningMode) {
							 case runningModeRecording:
								 _scrollRecordLabel.textColor = activeColor;
								 _scrollRecordLabel.alpha = 1.0;
								 _recordingToolbar.alpha = 1.0;
								 _settingBaseView.alpha = 0.0;
								 break;
							 case runningModePlayback:
								 _scrollPlaybackLabel.textColor = activeColor;
								 _scrollPlaybackLabel.alpha = 1.0;
								 _playbackToolbar.alpha = 1.0;
								 _settingBaseView.alpha = 0.0;
								 break;
							 case runningModeManual:
								 _scrollManualLabel.textColor = activeColor;
								 _scrollManualLabel.alpha = 1.0;
								 _manualToolbar.alpha = 1.0;
								 _settingBaseView.alpha = 0.0;
								 break;
							 case runningModeSetting:
								 _scrollSettingLabel.textColor = activeColor;
								 _scrollSettingLabel.alpha = 1.0;
								 _manualToolbar.alpha = 1.0;
								 _settingBaseView.alpha = 1.0;
								 setupFrame.origin.x = screen.size.width-250;
								 break;
						 }
						 _settingBaseView.frame = setupFrame;
					 }
					 completion:^(BOOL finished){
						 // after animations
					 }];
	
	// 位置情報の取得はRecordingモードだけ
	switch (_runningMode) {
		case runningModeRecording:
#ifdef	GEOFAKE_DEBUG
			[[GeoFake sharedFake] setLocationManager:_locationManager mapView:_mapView];
			[[GeoFake sharedFake] startUpdatingLocation];
			[[GeoFake sharedFake] startUpdatingHeading];
#else
			[_locationManager startUpdatingLocation];
			[_locationManager startUpdatingHeading];
#endif
			if([CMMotionActivityManager isActivityAvailable]) {
				[self startGettingMotionActivity];
			}
			_mapView.showsUserLocation = YES;
			_mapView.userTrackingMode = MKUserTrackingModeFollow;
			break;
		case runningModePlayback:
		case runningModeManual:
		case runningModeSetting:
#ifdef	GEOFAKE_DEBUG
			[[GeoFake sharedFake] setLocationManager:_locationManager mapView:_mapView];
			[[GeoFake sharedFake] stopUpdatingLocation];
			[[GeoFake sharedFake] stopUpdatingHeading];
#else
			[_locationManager stopUpdatingLocation];
			[_locationManager stopUpdatingHeading];
#endif
			if([CMMotionActivityManager isActivityAvailable]) {
				[self stopGettingMotionActivity];
			}
			_mapView.showsUserLocation = NO;
			[_mapView removeOverlays:_mapView.overlays];
			[_mapView removeAnnotations:_mapView.annotations];
			break;
	}

	// 自動再生はPlaybackモードだけ
	switch (_runningMode) {
		case runningModePlayback:
			_progressView.hidden = NO;
			[self displayPlaybackOverlay:YES];
			_isRecording = NO;
			[self renameAutoSaveFileToTimestampName];	// 自動保存されているGpxがあれば、リネームする
			break;
		case runningModeRecording:
			[self displayPlaybackOverlay:NO];
			_progressView.hidden = YES;
			_isPlaying = NO;
			break;
		case runningModeManual:
			[self plotBeacons];
		//	[self showBeaconArea:YES];
			_progressView.hidden = YES;
			_isPlaying = NO;
			_isRecording = NO;
			break;
		case runningModeSetting:
			_progressView.hidden = YES;
			_isPlaying = NO;
			_isRecording = NO;
			break;
	}
	
	// センターカーソル表示
	switch (_runningMode) {
		case runningModeManual:
		case runningModeSetting:
			_mapCenterImage.hidden = NO;
			_mapCenterPlaybackImage.hidden = YES;
			[self showInfoBaseView:NO];
			break;
		case runningModePlayback:
			_mapCenterImage.hidden = YES;
			_mapCenterPlaybackImage.hidden = NO;
			[self showInfoBaseView:_playButton.enabled];
			break;
		case runningModeRecording:
			_mapCenterImage.hidden = YES;
			_mapCenterPlaybackImage.hidden = YES;
			[self showInfoBaseView:NO];
			break;
	}
	
	// Setting --> Manualに移ったら、設定内容を反映する
	if(_runningMode==runningModeManual) {
		[self getSettingValue];
		[self saveSettingValue];
	}
	
	_isClientConnectAvailable= !_connectButton.hidden;

	[self setPlayButtonImage];
	[self setSliderView];
}



#pragma mark - Multipeer Browser job

- (IBAction)connectButtonPushed:(id)sender {
	[self presentViewController:_browserVC animated:YES completion:nil];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController*)browserViewController {
	[browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
	[browserViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Session job

- (void)sendMessage:(NSString *)message {
    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
	// Reliable（確実）モードで送信　データ消失時に再送信あり、順序あり
	if([_session.connectedPeers count]>0) {
		[_session sendData:messageData toPeers:_session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
		if (error) {
			NSLog(@"Error sending message to peers [%@]", error);
		}
	}
}

#pragma mark - Session delegate

- (void)session:(MCSession*)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
	NSLog(@"Peer [%@] changed state to %d", peerID.displayName, (int)state);
	
	// Viewへのフィードバックを行うために、メインスレッドで処理する
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self checkConnectedPeers];
	});
}

- (void)checkConnectedPeers {
	NSLog(@"peers=%lu", (unsigned long)[_session.connectedPeers count]);
	NSMutableString* str = [[NSMutableString alloc] initWithCapacity:1];
	for(int i=0; i<[_session.connectedPeers count]; i++) {
		[str appendString:@"●"];
	}
	if(str.length==0)
		[str setString:@"×"];
	_connectLabel.text = str;
}

#pragma mark - Location Job

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	_currentHeading = newHeading;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	
	//NSLog(@"updateLocation");
	
	if(_runningMode == runningModeRecording) {
		if(_isRecording) {
			for(CLLocation *loc in locations) {
				// 現在地と現在のアクティビティでオブジェクトを生成
				LocateMotion *lm = [[LocateMotion alloc] initWithLocation:loc heading:_currentHeading activity:_motionActivity];
				lm.segmentStart = _isSegmentTop;
				_isSegmentTop = NO;
				
				if(_locationItems.count > 1) {
					LocateMotion *lastLM = [_locationItems lastObject];
					// 直前のアクティビティと変わっていれば
					if(![lastLM isSameActivity:lm]) {
						[self drawActivity];	// マップ上に描画する
						[self recordingInfoDisplay];
					}
				}
				[_locationItems addObject:lm];	// オブジェクトを追加しておく（描画用）
				[_locationItemsForSaving addObject:lm];	// オブジェクトを追加しておく（ファイル保存用）
			}
			
			if(!_deferredLocationUpdates) {
				CLLocationDistance	distance = 100.0;	// meter
				NSTimeInterval		time = 30.0;		// sec
				[_locationManager allowDeferredLocationUpdatesUntilTraveled:distance timeout:time];
				_deferredLocationUpdates = YES;
			}
		}
	}
}

-(void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
	
	//NSLog(@"deferredUpdates");
	
	_deferredLocationUpdates = NO;
	
	if(_runningMode == runningModeRecording) {
		[self drawActivity];	// マップ上に描画する
		[self recordingInfoDisplay];
	}
}


#pragma mark - Motion Job

- (void)startGettingMotionActivity {
	
	void (^motionHandler)(CMMotionActivity *activity) = ^void(CMMotionActivity *activity){
        dispatch_async(dispatch_get_main_queue(), ^{
			_motionActivity = activity;
        });
	};

#ifdef	GEOFAKE_DEBUG
	[[GeoFake sharedFake] startActivityUpdatesWithHandler:motionHandler];
#else
	if([CMMotionActivityManager isActivityAvailable]) {
		_activityManager = [[CMMotionActivityManager alloc]init];
		[_activityManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:motionHandler];
	}
#endif
}

- (void)stopGettingMotionActivity {
	
#ifdef	GEOFAKE_DEBUG
	[[GeoFake sharedFake] stopActivityUpdates];
#else
    [_activityManager stopActivityUpdates];
#endif
    _activityManager = nil;
}


#pragma mark - Map job

- (void)drawActivity {
	if(_locationItems) {
		
		if(_locationItems.count > 1) {
			//NSLog(@"drawActivity");

			// 時刻アノテーションの準備
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			NSString *outputDateFormatterStr= @"HH:mm";
			[dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
			[dateFormatter setDateFormat:outputDateFormatterStr];
			
			CLLocationCoordinate2D coordinates[_locationItems.count];
			for (int index = 0; index < _locationItems.count; index++) {
				LocateMotion *lm = [_locationItems objectAtIndex:index];
				CLLocationCoordinate2D coordinate = lm.location.coordinate;
				coordinates[index] = coordinate;
				
				// アノテーションを追加
				if(_annotationInterval < INT32_MAX) {
					NSString *annStr = [dateFormatter stringForObjectValue:lm.timestamp];
					//	NSString *annStr = [dateFormatter stringForObjectValue:lm.location.timestamp];
					int minute = [[annStr substringFromIndex:3] intValue];
					if(minute%_annotationInterval==0) {	// 5分（または10分、30分）おきにアノテーションを表示
						if(![annStr isEqualToString:_lastAnnotation]) {
							MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
							point.coordinate = coordinate;	// 緯度経度
							point.title = annStr;			// 通過時刻
							
							[_mapView addAnnotation:point];	// 地図にアノテーションを追加
							[_mapView selectAnnotation:point animated:YES];
							_lastAnnotation = annStr;
						}
					}
				}
			}
			
			// 移動軌跡を描く
			ColorPolyline *polyLine = [ColorPolyline polylineWithCoordinates:coordinates count:_locationItems.count];
			LocateMotion* lm0 = [_locationItems lastObject];
			polyLine.drawColor = [self getActivityColor:lm0.activity];
			[_mapView addOverlay:polyLine level:MKOverlayLevelAboveRoads];
			
			for (int index = 0; index < _locationItems.count-1; index++) {
				[_locationItems removeObjectAtIndex:0];
			}
		}
	}
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay {
	
	if ([overlay isKindOfClass:[ColorPolyline class]]) {
		ColorPolyline *polyline = (ColorPolyline*)overlay;
		
		MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
		renderer.strokeColor = polyline.drawColor;
		renderer.lineWidth = 5.0;
		
		return (MKOverlayRenderer*)renderer;
	}

	if ([overlay isKindOfClass:[MKCircle class]]) {
		MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle*)overlay];
		
		renderer.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
		renderer.lineWidth = 1.0;
		renderer.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.2];
		
		return (MKOverlayRenderer*)renderer;
	}
	
	return nil;
}

- (UIColor *)getActivityColor:(CMMotionActivity*)activity {

	if(activity.walking)	return [UIColor colorWithRed:1.0 green:204.0f/255.0f blue:102.0f/255.0f alpha:0.7];
	if(activity.running)	return [UIColor colorWithRed:1.0 green:102.0f/255.0f blue:102.0f/255.0f alpha:0.7];
	if(activity.automotive)	return [UIColor colorWithRed:0.0 green:128.0f/255.0f blue:128.0f/255.0f alpha:0.7];
	if(activity.stationary)	return [UIColor colorWithRed:0.0 green:102.0f/255.0f blue:204.0f/255.0f alpha:0.7];
	
	return [UIColor grayColor];
}

#pragma mark - Map delegate

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	if ([annotation isKindOfClass:[MKUserLocation class]])
		return nil;

	if ([annotation isKindOfClass:[BeaconAnnotation class]]) {
		BeaconAnnotation* beacon = annotation;
	//	NSLog(@"viewForAnnotation[%@]", [beacon.beaconInfo valueForKey:@"minor"]);
		MKAnnotationView *annotationView;
		annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:@"beaconAnnotation"];
		if(!annotationView) {
			annotationView = [[BeaconAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"beaconAnnotation"];
			annotationView.canShowCallout = YES;
			annotationView.draggable = YES;
			annotationView.enabled = YES;
		}
		
    //	UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 32, 32)];
	//	imgView.image = [UIImage imageNamed:@"beacon"];
	//	annotationView.leftCalloutAccessoryView = imgView;
		annotationView.contentMode = UIViewContentModeScaleAspectFill;
        annotationView.image = [UIImage imageNamed:@"beacon"];
		annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		return annotationView;
	}

	if(_runningMode!=runningModeRecording) {
		if ([annotation isKindOfClass:[CenterAnnotation class]]) {
			MKAnnotationView* annotationView = [_mapView  dequeueReusableAnnotationViewWithIdentifier:@"CenterAnnotation"];
			if( annotationView ){
				annotationView.annotation = annotation;
			}
			else{
				annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CenterAnnotation"];
			}
			annotationView.image = [UIImage imageNamed:@"target"];
			return annotationView;
		}
	}
	
	return nil;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

	double heading = (_headingSwitch.on?_mapView.camera.heading:0.0);
	if(_runningMode==runningModeManual) {
		NSString *loc = [NSString stringWithFormat:@"{Location},%f,%f,%f", _mapView.centerCoordinate.latitude, _mapView.centerCoordinate.longitude, heading];
		//NSString *loc = [NSString stringWithFormat:@"{Location},%f,%f,%f", _mapView.region.center.latitude, _mapView.region.center.longitude, heading];
		[self sendMessage:loc];
		
		NSLog(@"%@", loc);
	}
	
#if USE_iBEACON==1
	[self checkBeaconArea];
#endif
}

#pragma mark - Recording job

- (IBAction)recButtonPushed:(id)sender {
	_isRecording = !_isRecording;
	
	if(_isRecording) {
		_isSegmentTop = YES;
		_recButton.image = [UIImage imageNamed:@"stop"];
		_recButton.tintColor = [UIColor whiteColor];
		[_locationItems removeAllObjects];
		[self clearInfoDisplay];
		[self showInfoBaseView:NO];
		
		if(_recSaveTimer==nil) {
			_recSaveTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SAVE_INTERVAL target:self selector:@selector(saveRecordedDataAutomatically) userInfo:nil repeats:YES];
		}
	}
	else {
		[self drawActivity];
		[_locationItems removeAllObjects];	// オーバーレイは繋げずに別の線にする

		_isSegmentTop = NO;
		_recButton.image = [UIImage imageNamed:@"rec"];
		_recButton.tintColor = [UIColor redColor];
		[self saveRecordedDataAutomatically];

		if(_recSaveTimer) {
			[_recSaveTimer invalidate];
			_recSaveTimer = nil;
		}
	}
}


- (void)renameAutoSaveFileToTimestampName {
	[_locationItemsForSaving removeAllObjects];
	[[Gpx new] renameAutoSaveFileToTimestampName];	// 自動保存されているGpxがあれば、リネームする
}

- (void)saveRecordedDataAutomatically {
	
	if(_locationItemsForSaving.count>0) {
		NSLog(@"Auto save");
		[self saveRecordedDataSub:AUTO_SAVE_NAME];
	}
}

- (void)saveRecordedDataSub:(NSString*)fname {
	
	Gpx* aGpx = [[Gpx alloc] init];
	
	for(int i=0; i< _locationItemsForSaving.count; i++) {
		LocateMotion* lm = [_locationItemsForSaving objectAtIndex:i];
		GpxItem* gi = [[GpxItem alloc] init];
		
		gi.latitude = lm.location.coordinate.latitude;
		gi.longitude = lm.location.coordinate.longitude;
		gi.heading = lm.heading.magneticHeading;
		gi.altitude = lm.location.altitude;
		gi.timestamp = lm.location.timestamp;
		
		gi.stationary = lm.activity.stationary;
		gi.walking = lm.activity.walking;
		gi.running = lm.activity.running;
		gi.automotive = lm.activity.automotive;
		gi.unknown = lm.activity.unknown;
		gi.confidence = lm.activity.confidence;
		
		gi.segmentStart = lm.segmentStart;
		
		[aGpx.items addObject:gi];
	}
	
	[aGpx saveGpxData:fname];
	[self saveAnimeJob];
}

- (void)saveAnimeJob {
}

#pragma mark - Playback job

- (void)setPlayButtonImage {
	if(_isPlaying) {
		_playButton.image = [UIImage imageNamed:@"pause"];
	}
	else {
		_playButton.image = [UIImage imageNamed:@"play"];
	}
}

- (IBAction)playButtonPushed:(id)sender {
	_isRealTimeScale = YES;

	_isPlaying = !_isPlaying;

	[self setPlayButtonImage];
	[self playbackTimerJob];
}

- (IBAction)ffButtonPushed:(id)sender {
	_isRealTimeScale = NO;
	_isPlaying = YES;

	[self setPlayButtonImage];
	[self playbackTimerJob];
}

- (IBAction)rewButtonPushed:(id)sender {

	if(_isRealTimeScale == YES) {
		_aGpx.currentIndex -= 10;
	}
	else {
		_aGpx.currentIndex -= 20;
	}
	
	if(_aGpx.currentIndex < 0)
		_aGpx.currentIndex = 0;

	// プログレスバー
	double progress = _aGpx.currentIndex;
	progress /= [_aGpx.items count];
	_progressView.progress = progress;
	
	// プログレススライダー
	_progressSlider.value = progress;
	
	[self playbackTimerJobSub];
}

- (IBAction)pauseButtonPushed:(id)sender {
	_isPlaying = NO;
	
	_playButton.enabled = YES;
	_ffButton.enabled = YES;
	_rewButton.enabled = YES;
	[self showInfoBaseView:YES];
}

- (void)showInfoBaseView:(BOOL)flag {
	float targetAlpha = -1.0;
	
	if(_infoBaseView.alpha > 0) {
		if(flag==NO) {
			targetAlpha = 0.0;
		}
	}
	else {
		if(flag==YES) {
			targetAlpha = 1.0;
		}
	}

	if(targetAlpha >= 0) {
		[UIView animateWithDuration:0.4f
						 animations:^{
							 _infoBaseView.alpha = targetAlpha;
						 }
						 completion:^(BOOL finished){
						 }];
	}

	if(_playButton.enabled==YES) {
		[self playbackTimerJobSub];
	}
}


- (IBAction)loadGpxFile:(id)sender {	// RecordingモードToolbarでGpxリストアップボタンが押された場合のみ
	if(_isRecording) {
		[self recButtonPushed:nil];
	}
	
	[self renameAutoSaveFileToTimestampName];	// 自動保存されているGpxがあれば、リネームする

	[self performSegueWithIdentifier:@"showGpxListPage" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if(_isPlaying) {
		[self playButtonPushed:nil];
	}

    if ( [[segue identifier] isEqualToString:@"showGpxListPage"] ) {
        GpxListViewController* nextViewController = [segue destinationViewController];
		nextViewController.delegate = self;
        nextViewController.gpxManager = _gpxManager;
    }
}

-(void)closeGpxListPageWithName:(NSString*)gpxFileName {
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[self loadGpxData:gpxFileName];
}


- (void)loadGpxData:(NSString*)fileName {

	if(fileName.length==0)
		return;
	
	_progressView.progress = 0.0;
	_progressSlider.value = 0.0;
	
	if(_aGpx==nil) {
		_aGpx = [[Gpx alloc] init];
	}

	if([_aGpx loadGpxData:fileName]) {
		[self setModeSwitchTo:runningModePlayback];
		[self setDisplayRegion];
		[self displayPlaybackOverlay:YES];
		[self startTimeJob];
	}
}

#pragma mark Timer job

- (void)startTimeJob {
	_playButton.enabled = YES;
	_ffButton.enabled = YES;
	_rewButton.enabled = YES;
	[self showInfoBaseView:YES];
	
	[self playbackTimerJob];
}


- (void)playbackTimerJob {
	
	if(_isPlaying == NO)
		return;
	
	if(_aGpx.currentIndex>=[_aGpx.items count])
		return;
	
	// プログレスバー
	double progress = _aGpx.currentIndex;
	progress /= [_aGpx.items count];
	_progressView.progress = progress;
	
	// プログレススライダー
	_progressSlider.value = progress;
	
	[self playbackTimerJobSub];
	
	GpxItem* aGpxItem = [_aGpx.items objectAtIndex:_aGpx.currentIndex];
	
	// 次の地点までの所要時間を求める（実際に記録されたタイムスタンプで時間差を計算する）
	if(_aGpx.currentIndex<[_aGpx.items count]-1) {
		GpxItem* bGpxItem = [_aGpx.items objectAtIndex:_aGpx.currentIndex+1];

		NSTimeInterval intervalTime;
		intervalTime = 1.0;
		if((aGpxItem.timestamp != nil)&&(bGpxItem.timestamp != nil)) {
			intervalTime = [bGpxItem.timestamp timeIntervalSinceDate:aGpxItem.timestamp];
		}
		
		// 次の地点までの距離を求める
//		CLLocation *start = [[CLLocation alloc] initWithLatitude:aGpxItem.latitude longitude:aGpxItem.longitude];
//		CLLocation *end   = [[CLLocation alloc] initWithLatitude:bGpxItem.latitude longitude:bGpxItem.longitude];
//		CLLocationDistance d = [end distanceFromLocation:start];

#ifdef SET_MOTION_STATUS_IN_RUNKEEPER_DATA
		// 秒速を求める (m/s)
		double ms = d / intervalTime;

		if(ms > 8.0) {
		//	aGpxItem.automotive = YES;
		//	NSLog(@"Automotive");
			aGpxItem.running = YES;
			NSLog(@"Running");
		}
		else if(ms > 1.8) {
			aGpxItem.running = YES;
			NSLog(@"Running");
		}
		else if(ms > 0.8) {
			aGpxItem.walking = YES;
			NSLog(@"Walking");
		}
		else {
			aGpxItem.stationary = YES;
			NSLog(@"Stationary");
		}
		
		aGpxItem.confidence = CMMotionActivityConfidenceMedium;
#endif
		
		if(_isRealTimeScale==NO) {
			intervalTime = 0.5;
			intervalTime = 1.0;
		}
		
		if(bGpxItem.segmentStart) {	// 次のポイントがセグメント先頭なら1秒待って移動する
			_isPlaying = NO;
			[self setPlayButtonImage];
			intervalTime = 0.1;
		}

		_aGpx.currentIndex++;
		[NSTimer scheduledTimerWithTimeInterval:intervalTime target:self selector:@selector(playbackTimerJob) userInfo:nil repeats:NO];
	}
	else {
		_progressView.progress = 1.0;
		_progressSlider.value = 1.0;
		_aGpx.currentIndex = 0;
		_isPlaying = NO;
		[self setPlayButtonImage];
		
#ifdef SET_MOTION_STATUS_IN_RUNKEEPER_DATA
		[_aGpx saveGpxData:@"ModifyData"];
#endif

	}
}

- (void)playbackTimerJobSub {
	GpxItem* aGpxItem = [_aGpx.items objectAtIndex:_aGpx.currentIndex];
	
	double heading = (_headingSwitch.on?aGpxItem.heading:0.0);
	
	NSString *loc = [NSString stringWithFormat:@"{Location},%f,%f,%f", aGpxItem.latitude, aGpxItem.longitude, heading];
	[self sendMessage:loc];
	
	NSString* motion = [NSString stringWithFormat:@"{Motion},%d,%d,%d,%d,%d,%d", aGpxItem.stationary, aGpxItem.walking, aGpxItem.running, aGpxItem.automotive, aGpxItem.unknown, (int)aGpxItem.confidence];
	[self sendMessage:motion];
	
	// マップに現在位置を表示
	if(_runningMode == runningModePlayback) {
		[_mapView setCenterCoordinate:CLLocationCoordinate2DMake(aGpxItem.latitude, aGpxItem.longitude)];
		_mapView.camera.heading = heading;

		[self playbackInfoDisplay];
		[self openPlaybackCallout];
	}
}

- (void)openPlaybackCallout {
	if(_annotationInterval < INT32_MAX) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		NSString *outputDateFormatterStr= @"HH:mm";
		[dateFormatter setTimeZone:[NSTimeZone defaultTimeZone]];
		[dateFormatter setDateFormat:outputDateFormatterStr];
		
		GpxItem* aGpxItem = [_aGpx.items objectAtIndex:_aGpx.currentIndex];
		
		NSString *annStr = [dateFormatter stringForObjectValue:aGpxItem.timestamp];
		int minute = [[annStr substringFromIndex:3] intValue];
		if(minute%_annotationInterval==0) {	// 5分（または10分、30分）おきにアノテーションを表示
			if(![annStr isEqualToString:_lastAnnotation]) {
				
				for(MKPointAnnotation* annotation in _mapView.annotations) {
					if([annotation.title isEqualToString:annStr]) {
						[_mapView selectAnnotation:annotation animated:YES];
						[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(closePlaybackCallout:) userInfo:annotation repeats:NO];
						break;
					}
				}
				_lastAnnotation = annStr;
			}
		}
	}
}

- (void)closePlaybackCallout:(NSTimer*)timer {
	MKPointAnnotation* annotation = timer.userInfo;
	[_mapView deselectAnnotation:annotation animated:YES];
}

- (void)clearInfoDisplay {
	_infoTextView.text = @"";
	_infoLabel.text = @"";
	_infoLabelView.backgroundColor = [UIColor clearColor];

	[self showInfoBaseView:NO];
}

- (void)playbackInfoDisplay {

	if(_infoBaseView.alpha == 0.0)
		[self showInfoBaseView:YES];

	GpxItem* aGpxItem = [_aGpx.items objectAtIndex:_aGpx.currentIndex];
	GpxItem* bGpxItem = [_aGpx.items objectAtIndex:0];
	NSTimeInterval intervalTime;
	intervalTime = 0.0;
	if((aGpxItem.timestamp != nil)&&(bGpxItem.timestamp != nil)) {
		intervalTime = [aGpxItem.timestamp timeIntervalSinceDate:bGpxItem.timestamp];
	}
	int h = intervalTime / 3600;
	int m = (intervalTime-(h*3600)) / 60;
	int s = intervalTime - h*3600 - m*60;
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
	_infoTextView.text = [NSString stringWithFormat:@"%@\nElapsed %02dh%02dm%02ds", [dateFormatter stringFromDate:aGpxItem.timestamp], h, m, s];
	_infoTextView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
	//_infoTextView.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:17];
	
	GFMotionActivity* motion = [[GFMotionActivity alloc] init];
	motion.stationary = aGpxItem.stationary;
	motion.walking = aGpxItem.walking;
	motion.running = aGpxItem.running;
	motion.automotive = aGpxItem.automotive;
	motion.confidence = aGpxItem.confidence;
	_infoLabelView.backgroundColor = [self getActivityColor:motion];
	
	_infoLabel.text = [self activityName:motion];
	_infoLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
}

- (void)recordingInfoDisplay {

	if(_infoBaseView.alpha == 0.0)
		[self showInfoBaseView:YES];

	LocateMotion* aLM = [_locationItemsForSaving lastObject];
	LocateMotion* bLM = [_locationItemsForSaving firstObject];

//	GpxItem* aGpxItem = [_aGpx.items objectAtIndex:_aGpx.currentIndex];
//	GpxItem* bGpxItem = [_aGpx.items objectAtIndex:0];

	NSTimeInterval intervalTime;
	intervalTime = 0.0;
	if((aLM.timestamp != nil)&&(bLM.timestamp != nil)) {
		intervalTime = [aLM.timestamp timeIntervalSinceDate:bLM.timestamp];
	}
	int h = intervalTime / 3600;
	int m = (intervalTime-(h*3600)) / 60;
	int s = intervalTime - h*3600 - m*60;
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
	_infoTextView.text = [NSString stringWithFormat:@"%@\nTime %02dh%02dm%02ds", [dateFormatter stringFromDate:aLM.timestamp], h, m, s];
	_infoTextView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
	
	_infoLabelView.backgroundColor = [self getActivityColor:aLM.activity];
	_infoLabel.text = [self activityName:aLM.activity];
	_infoLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];

	// 5時間以上、記録が続いていたらメッセージを出す
	if(_acceptLongTimeRecording==NO) {
		if(h>=5) {
			UILocalNotification *notification = [[UILocalNotification alloc] init];
			notification.alertBody = @"Recording activity more than 5 hours.";
			notification.soundName = UILocalNotificationDefaultSoundName;
			[[UIApplication sharedApplication] cancelAllLocalNotifications];
			[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
			NSLog(@"Long time recording alert");
			_acceptLongTimeRecording = YES;
		}
	}
}

- (NSString*)activityName:(CMMotionActivity*)motion {
	NSString* retStr;
	
	retStr = @"Unknown";
	if(motion.walking)
		retStr = @"Walking";
	if(motion.running)
		retStr = @"Running";
	if(motion.automotive)
		retStr = @"Automotive";
	if(motion.stationary)
		retStr = @"Stop";

	return retStr;
}


- (IBAction)sliderValueChanged:(id)sender {
	
	UISlider* slider = (UISlider*)sender;

	_progressView.progress = slider.value;

	double index = slider.value;
	index *= [_aGpx.items count];
	if(index >= [_aGpx.items count])
		index = [_aGpx.items count]-1;
	_aGpx.currentIndex = index;

	[self playbackTimerJobSub];

	_isPlaying = NO;
	[self setPlayButtonImage];
	
}

- (void)setSliderView {
	
	double alpha = 0.5;
	
	if(_runningMode != runningModePlayback)
		alpha = 0.0;
	if(_isPlaying)
		alpha = 0.0;
	if([_aGpx.items count]==0)
		alpha = 0.0;

	if(_progressSlider.alpha != alpha) {
		[UIView animateWithDuration:0.7f
						 animations:^{
							 _progressSlider.alpha = alpha;
						 }
						 completion:^(BOOL finished){
							 // after animations
						 }];
	}
  }

#pragma mark Display area

- (void)displayPlaybackOverlay:(BOOL)flag {
	
	if(flag == NO) {
		[_mapView removeOverlays:_mapView.overlays];
	}
	else {
		if(_aGpx.items) {
			if(_aGpx.items.count > 1) {
				
				[_mapView removeOverlays:_mapView.overlays];
				[_locationItems removeAllObjects];

				for (int index = 0; index < _aGpx.items.count; index++) {
					GpxItem *gi = [_aGpx.items objectAtIndex:index];
					CLLocation* loc = [[CLLocation alloc] initWithLatitude:gi.latitude longitude:gi.longitude];
					GFHeading* heading = [[GFHeading alloc] init];
					heading.magneticHeading = heading.trueHeading = gi.heading;
					GFMotionActivity* motion = [[GFMotionActivity alloc] init];
					motion.stationary = gi.stationary;
					motion.walking = gi.walking;
					motion.running = gi.running;
					motion.automotive = gi.automotive;
					motion.confidence = gi.confidence;
					LocateMotion *lm = [[LocateMotion alloc] initWithLocation:loc heading:heading activity:motion];
					lm.timestamp = gi.timestamp;

					// セグメント境界（あたらしいアクティビティ群の開始）
					if(gi.segmentStart) {
						[self drawActivity];
						[_locationItems removeAllObjects];	// オーバーレイは繋げずに別の線にする
					}

					if(_locationItems.count > 1) {
						LocateMotion *lastLM = [_locationItems lastObject];
						// 直前のアクティビティと変わっていれば
						if(![lastLM isSameActivity:lm]) {
							[self drawActivity];	// マップ上に描画する
							
							LocateMotion *lastLm = [_locationItems lastObject];
							GFMotionActivity* motion = [[GFMotionActivity alloc] init];
							motion.stationary = lastLm.activity.stationary;
							motion.walking = lastLm.activity.walking;
							motion.running = lastLm.activity.running;
							motion.automotive = lastLm.activity.automotive;
							motion.confidence = lastLm.activity.confidence;
							LocateMotion *newLm = [[LocateMotion alloc] initWithLocation:lastLm.location heading:lastLM.heading activity:motion];
							[_locationItems removeAllObjects];
							[_locationItems addObject:newLm];
						}
					}
					[_locationItems addObject:lm];	// オブジェクトを追加しておく（描画用）
				}
				[self drawActivity];
			}
		}
		// ビーコンを描く
		[self plotBeacons];
	//	[self showBeaconArea:YES];
	}
	
}


- (void)setDisplayRegion {
	double minLat = 9999.0;
	double minLng = 9999.0;
	double maxLat = -9999.0;
	double maxLng = -9999.0;

	if(_aGpx.items) {
		if(_aGpx.items.count > 1) {
			for (int index = 0; index < _aGpx.items.count; index++) {
				GpxItem *gi = [_aGpx.items objectAtIndex:index];
				
				//緯度の最大最小を求める
				if(minLat > gi.latitude)
					minLat = gi.latitude;
				if(gi.latitude > maxLat)
					maxLat = gi.latitude;
				
				//経度の最大最小を求める
				if(minLng > gi.longitude)
					minLng = gi.longitude;
				if(gi.longitude > maxLng)
					maxLng = gi.longitude;
			}
			
			// マップの表示範囲を設定する
			CLLocationCoordinate2D center = CLLocationCoordinate2DMake((maxLat + minLat) / 2.0, (maxLng + minLng) / 2.0);
			MKCoordinateSpan span = MKCoordinateSpanMake((maxLat - minLat)*1.5, (maxLng - minLng)*1.5);
			MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
			[_mapView setRegion:[_mapView regionThatFits:region] animated:YES];
		}
	}
}

#pragma mark - GPX read & launch

- (void)preparePlaybackFor:(NSString*)gpxFileName {

	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(preparePlaybackDelayJobFor:) userInfo:gpxFileName repeats:NO];
}

- (void)preparePlaybackDelayJobFor:(NSTimer*)inTimer {
	NSString* gpxFileName = [inTimer userInfo];
	[self loadGpxData:gpxFileName];
	[self setSliderView];
}

#pragma mark - General Timer job

- (void)generalTimeJob {
	
#ifndef INAPP_PURCHASE
	return;
#endif

	if([self isItemPurchased:@"item001"]==YES) {	// クライアントコネクトの課金アイテムID
		_connectButton.enabled = YES;
	}

	if([_session.connectedPeers count]>0) {
		connectingTimer--;
		if(connectingTimer>0) {
			NSLog(@"connectingTimer=%d", connectingTimer);
		}
		else {
		}

		if(connectingTimer==0) {
			if([self isItemPurchased:@"item001"]==NO) {	// クライアントコネクトの課金アイテムID
				NSLog(@"connect time out");
				[_session disconnect];
				_connectButton.enabled = NO;

				[self purchaseJob];
			}
		}
	}
}

#pragma mark - InApp purchase

- (IBAction)purchaseListButtonPushed:(id)sender {
	[self purchaseJob];
}

- (void)purchaseJob {
	BuyContentViewController *detailViewController = [[BuyContentViewController alloc] initWithNibName:@"BuyContentViewController" bundle:nil];
	[self presentViewController:detailViewController animated:YES completion:nil];
}

- (BOOL)isItemPurchased:(NSString*)itemID {
	
	BOOL result = NO;
	
	GeoFakeAppDelegate *appDelegate = (GeoFakeAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	for(int i=0; i < appDelegate.extraContent.itemCount; i++) {
		NSString* itemID = [appDelegate.extraContent getItemID:i];
		if([itemID isEqualToString:itemID]) {
			int purchaseOrder = [appDelegate.extraContent getItemStatus:i];
			if(purchaseOrder > 0) {
				result = YES;
			}
		}
	}
	
	return result;
}


- (IBAction)visitWebButtonPushed:(id)sender {
	NSURL *url = [NSURL URLWithString:@"http:/newtonjapan.com/GeoPlayer"];
	[[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Beacon job

- (void)checkBeaconArea {

	CLLocation* mapCenter = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
	
	BOOL isBeaconNearby = NO;
	
	for(NSMutableDictionary* beacon in _beaconArray) {
		NSString* _uuid  = [beacon objectForKey:@"uuid"];
		NSString* _major = [beacon objectForKey:@"major"];
		NSString* _minor = [beacon objectForKey:@"minor"];
		NSString* _lat   = [beacon objectForKey:@"latitude"];
		NSString* _long  = [beacon objectForKey:@"longitude"];
		NSString* _rad   = [beacon objectForKey:@"radius"];
		
		CLLocation* beaconLoc = [[CLLocation alloc] initWithLatitude:[_lat doubleValue] longitude:[_long doubleValue]];
		//CLLocation* beaconLoc = [[CLLocation alloc] initWithLatitude:21.259053 longitude:-157.797982];	// トライアングルパーク
		//CLLocation* beaconLoc = [[CLLocation alloc] initWithLatitude:36.525993 longitude:136.614368];	// 白山町信号
		CLLocationDistance d = [mapCenter distanceFromLocation:beaconLoc];

		// ビーコン範囲内ならビーコン発信
		if(d < [_rad intValue]) {
			[self beaconing:_uuid major:[_major intValue] minor:[_minor intValue] flag:YES];
			isBeaconNearby = YES;
			break;
		}
	}

	// どのビーコンも範囲内になければ停止
	if(isBeaconNearby==NO) {
		[self beaconing:@"" major:0 minor:0 flag:NO];
	}
}

-(void)beaconing:(NSString*)_uuid major:(int)_major minor:(int)_minor flag:(BOOL)flag
{
	
	NSDictionary *peripheralData;
	
	switch (flag) {
		case YES:
			if(_beaconing==NO) {
				NSUUID		*uuid = [[NSUUID alloc] initWithUUIDString:_uuid];
				CLBeaconRegion *region = [[CLBeaconRegion alloc]
										  initWithProximityUUID:uuid
										  major:_major
										  minor:_minor
										  identifier:[uuid UUIDString]];
				peripheralData = [region peripheralDataWithMeasuredPower:nil];
				[_peripheralManager startAdvertising:peripheralData];
				[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
				NSLog(@"iBeacon start");
			}
			break;
		case NO:
			if(_beaconing==YES) {
				[_peripheralManager stopAdvertising];
				[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
				NSLog(@"iBeacon stop");
			}
			break;
	}
	
	_beaconing = flag;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
}

- (NSString*)beaconListFilePath {
	NSString* path = [self dataDirPath];
	path = [path stringByAppendingPathComponent:kBEACON_FILE];
	return path;
}

- (void)addBeacon:(NSMutableDictionary*)beaconDict {
	
	[self showBeaconArea:NO];

	if(_beaconArray==nil) {
		_beaconArray = [[NSMutableArray alloc] init];
	}
	[_beaconArray insertObject:beaconDict atIndex:0];
	[self saveBeaconData];
	[self plotBeacons];
//	[self showBeaconArea:YES];
}

- (void)removeBeacon:(NSDictionary*)beaconDict {
	
	[self showBeaconArea:NO];

	NSString* number = [beaconDict objectForKey:@"number"];
	
	for(NSMutableDictionary* beacon in _beaconArray) {
		NSString* _number  = [beacon objectForKey:@"number"];

		if([number intValue] == [_number intValue]) {
			[_beaconArray removeObject:beacon];
			[self saveBeaconData];
			[self plotBeacons];
		//	[self showBeaconArea:YES];
			break;
		}
	}
}

- (void)loadBeaconData {
	
	NSString* path = [self beaconListFilePath];

	[_beaconArray removeAllObjects];

	if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
	//	path = [[NSBundle mainBundle] pathForResource:@"beacon_list" ofType:@"plist"];
	}
	
	_beaconArray = [NSMutableArray arrayWithContentsOfFile:path];
}

- (void)saveBeaconData {
	
	[_beaconArray writeToFile:[self beaconListFilePath] atomically:YES];
}

- (void)plotBeacons {
	
	id <MKAnnotation> annotation;
	
	for(annotation in _mapView.annotations) {
		if ([annotation isKindOfClass:[BeaconAnnotation class]]) {
			[_mapView removeAnnotation:annotation];
		}
	}
	
	if(_beaconSwitch.on==NO)
		return;
	
	for(NSMutableDictionary* beacon in _beaconArray) {
		NSString* _uuid  = [beacon objectForKey:@"uuid"];
		NSString* _major = [beacon objectForKey:@"major"];
		NSString* _minor = [beacon objectForKey:@"minor"];
		NSString* _lat   = [beacon objectForKey:@"latitude"];
		NSString* _long  = [beacon objectForKey:@"longitude"];
		NSString* _name  = [beacon objectForKey:@"name"];
		NSString* _number  = [beacon objectForKey:@"number"];
		if(_number.length == 0) {
			[beacon setValue:[NSString stringWithFormat:@"%d", [self getNewBeaconNo]] forKeyPath:@"number"];
		}

		BeaconAnnotation *point = [[BeaconAnnotation alloc] init];
		point.beaconInfo = beacon;
		point.coordinate = CLLocationCoordinate2DMake([_lat doubleValue], [_long doubleValue]);

		if([_name length] <= 0) {
			point.title = [NSString stringWithFormat:@"Major:%@, Minor:%@", _major, _minor];
			point.subtitle = [NSString stringWithFormat:@"UUID:%@", _uuid];
		}
		else {
			point.title = _name;
			point.subtitle = [NSString stringWithFormat:@"Major:%@, Minor:%@, UUID:%@", _major, _minor, _uuid];
		}
		
		[_mapView addAnnotation:point];
		
	}
	
	[self showBeaconArea:YES];
}

- (void)showBeaconArea:(BOOL)flag {

	if(flag == YES) {
		for(NSMutableDictionary* beacon in _beaconArray) {
			NSString* _lat   = [beacon objectForKey:@"latitude"];
			NSString* _long  = [beacon objectForKey:@"longitude"];
			NSString* _rad   = [beacon objectForKey:@"radius"];
			
			CLLocationCoordinate2D beaconLocation = CLLocationCoordinate2DMake([_lat doubleValue], [_long doubleValue]);
			MKCircle *_fenceRange1 = [MKCircle circleWithCenterCoordinate:beaconLocation radius:[_rad intValue]];
			
			[_mapView addOverlay:_fenceRange1 level:MKOverlayLevelAboveRoads];
		}
	}
	else {
		for (id<MKOverlay> overlayToRemove in _mapView.overlays) {
			if ([overlayToRemove isKindOfClass:[MKCircle class]]) {
				[_mapView removeOverlay:overlayToRemove];
			}
		}
	}

}


- (NSString*)dataDirPath {
	
	NSString* tempDir = NSHomeDirectory();
	tempDir = [tempDir stringByAppendingPathComponent:kPATH_DOCUMENTS];
	tempDir = [tempDir stringByAppendingPathComponent:kPATH_DATA];
	[[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
	
	return tempDir;
}

- (void)mapView:(MKMapView *)mapView  annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
	BeaconAnnotationView* beaconView = (BeaconAnnotationView*)annotationView;
	BeaconAnnotation* beacon = beaconView.annotation;

	//NSLog(@"beacon[%@]", [beacon.beaconInfo valueForKey:@"minor"]);
	
    if (newState == MKAnnotationViewDragStateEnding) {
        CLLocationCoordinate2D droppedAt = beaconView.annotation.coordinate;
        //NSLog(@"dropped at %f,%f", droppedAt.latitude, droppedAt.longitude);
		
		[beacon.beaconInfo setValue:[NSString stringWithFormat:@"%f", droppedAt.latitude] forKey:@"latitude"];
		[beacon.beaconInfo setValue:[NSString stringWithFormat:@"%f", droppedAt.longitude] forKey:@"longitude"];
		[self saveBeaconData];
	}

	if (newState == MKAnnotationViewDragStateStarting) {
		beaconView.dragState = MKAnnotationViewDragStateDragging;
		
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[self showBeaconArea:NO];
		});
	}
	else if (newState == MKAnnotationViewDragStateEnding || newState == MKAnnotationViewDragStateCanceling) {
		//NSLog(@"beacon drag end[%@]", [beacon.beaconInfo valueForKey:@"minor"]);
		beaconView.dragState = MKAnnotationViewDragStateNone;
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[self showBeaconArea:YES];
		});
	}
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView calloutAccessoryControlTapped:(UIControl *)control
{
	BeaconAnnotation* bAnn = annotationView.annotation;
	
	_currentBeacon = bAnn.beaconInfo;
	[self showBeaconSetting:YES];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)annotationView
{
	[self showBeaconSetting:NO];
}

- (void)showBeaconSetting:(BOOL)flag {
	
	CGRect rect = _beaconSettingBaseView.frame;
	switch(flag) {
		case YES:
		{
			rect.origin.y = 0;
			_beaconUuidText.text  = [_currentBeacon valueForKey:@"uuid"];
			_beaconMajorText.text = [_currentBeacon valueForKey:@"major"];
			_beaconMinorText.text = [_currentBeacon valueForKey:@"minor"];
			_beaconNameText.text = [_currentBeacon valueForKey:@"name"];
			NSString* radiusStr  = [_currentBeacon valueForKey:@"radius"];
			
			int index;
			switch ([radiusStr intValue]) {
				case 5:
					index = 0;
					break;
				case 10:
				default:
					index = 1;
					break;
				case 15:
					index = 2;
					break;
				case 20:
					index = 3;
					break;
			}
			_beaconRadiusSegment.selectedSegmentIndex = index;
		}
			break;
		case NO:
			rect.origin.y = -200;
			[_beaconUuidText resignFirstResponder];
			[_beaconMajorText resignFirstResponder];
			[_beaconMinorText resignFirstResponder];
			[_beaconNameText resignFirstResponder];

			[_currentBeacon setValue:_beaconUuidText.text forKey:@"uuid"];
			[_currentBeacon setValue:_beaconMajorText.text forKey:@"major"];
			[_currentBeacon setValue:_beaconMinorText.text forKey:@"minor"];
			[_currentBeacon setValue:_beaconNameText.text forKey:@"name"];

			int radius;
			switch (_beaconRadiusSegment.selectedSegmentIndex) {
				case 0:
					radius = 5;
					break;
				case 1:
				default:
					radius = 10;
					break;
				case 2:
					radius = 15;
					break;
				case 3:
					radius = 20;
					break;
			}
			[_currentBeacon setValue:[NSString stringWithFormat:@"%d", radius] forKey:@"radius"];
			break;
	}

	[UIView animateWithDuration:0.3f
					 animations:^{
						 _beaconSettingBaseView.frame = rect;
					 }
					 completion:^(BOOL finished){
						 // after animations
					 }];
}

- (IBAction)beaconSettingCloseButtonPushed:(id)sender {

	[self showBeaconSetting:NO];
	[self saveBeaconData];

	[self showBeaconArea:NO];
	[self plotBeacons];
//	[self showBeaconArea:YES];
	_currentBeacon = nil;
}


- (IBAction)beaconAddButtonPushed:(id)sender {
	
	NSMutableDictionary* beaconDict = [[NSMutableDictionary alloc] initWithCapacity:1];
	[beaconDict setValue:[NSString stringWithFormat:@"%d", [self getNewBeaconNo]] forKeyPath:@"number"];
	[beaconDict setValue:@"-" forKey:@"uuid"];
	[beaconDict setValue:@"-" forKey:@"major"];
	[beaconDict setValue:@"-" forKey:@"minor"];
	[beaconDict setValue:@"" forKey:@"name"];
	[beaconDict setValue:[NSString stringWithFormat:@"%f", _mapView.centerCoordinate.latitude] forKey:@"latitude"];
	[beaconDict setValue:[NSString stringWithFormat:@"%f", _mapView.centerCoordinate.longitude] forKey:@"longitude"];

	[self addBeacon:beaconDict];
	
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(addBeaconDelayJob) userInfo:nil repeats:NO];
}

- (void)addBeaconDelayJob {
	
//	[_mapView setSelectedAnnotations:_beaconArray];
	_currentBeacon = [_beaconArray firstObject];
	[self showBeaconSetting:YES];
}

- (IBAction)beaconRemoveButtonPushed:(id)sender {
	[self removeBeacon:_currentBeacon];

	BeaconAnnotation* bAnn = [_mapView.selectedAnnotations firstObject];
	[_mapView deselectAnnotation:bAnn animated:NO];
}


// iPhone用　キーボードを閉じる
- (BOOL)textFieldShouldReturn:(UITextField *)sender {
	
    [sender resignFirstResponder];
	
	if(sender == _beaconUuidText) {
		[self checkHex:sender.text];
	}
	if(sender == _beaconMajorText) {
		[self checkNumbers:sender.text];
	}
	if(sender == _beaconMinorText) {
		[self checkNumbers:sender.text];
	}
	
    return TRUE;
}

- (BOOL)checkNumbers:(NSString*)checkStr {
	NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:checkStr];
	NSCharacterSet *digitCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
	if ([digitCharacterSet isSupersetOfSet:stringCharacterSet]) {
		//NSLog(@"数字のみ");
		int num = [checkStr intValue];
		if (0<=num&&num<=65535) {
			//NSLog(@"0...65535のみ");
			return YES;
		}
		return NO;
	}
	else {
		[UIAlertView showWithTitle:@"Number check"
						   message:@"Only numbers are available (0-65535)"
				  cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" withAction:^{  }]
				  otherButtonItems:nil];
		//NSLog(@"数字以外の文字が存在");
		return NO;
	}
}

- (BOOL)checkHex:(NSString*)checkStr {
	NSCharacterSet *stringCharacterSet = [NSCharacterSet characterSetWithCharactersInString:checkStr];
	NSCharacterSet *digitCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF-"];
	if ([digitCharacterSet isSupersetOfSet:stringCharacterSet]) {
		//NSLog(@"HEXのみ");
		return YES;
	}
	else {
		[UIAlertView showWithTitle:@"UUID check"
						   message:@"Only HEX charactors are available"
				  cancelButtonItem:[RIButtonItem itemWithLabel:@"OK" withAction:^{  }]
				  otherButtonItems:nil];
		//NSLog(@"HEX以外の文字が存在");
		return NO;
	}
}

- (int)getNewBeaconNo {

	for(int newNumber=1; newNumber<32000; newNumber++) {
		BOOL	numberExist = NO;
		for(NSMutableDictionary* beacon in _beaconArray) {
			NSString* _number  = [beacon objectForKey:@"number"];
			if([_number intValue] == newNumber) {
				numberExist = YES;
				break;
			}
		}
		if(numberExist == NO) {
			return newNumber;
		}
	}
	
	return -1;
}

@end




