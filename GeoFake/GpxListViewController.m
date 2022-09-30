
#import "GpxListViewController.h"
#import "LocateMotion.h"

@interface GpxListViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *tableEditButton;
@property (weak, nonatomic) IBOutlet UIView *tableViewBase;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *mapSpinner;
@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeSpanLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *overTableView;
@end

@implementation GpxListViewController {
	Gpx*	_selectedGpx;
	BOOL	_isListDirty;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(listupGpxName) userInfo:nil repeats:NO];
	[_spinner stopAnimating];
	[_mapSpinner stopAnimating];

	UITapGestureRecognizer* recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideDetail)];
	[_overTableView addGestureRecognizer:recognizer];
	
	_isListDirty = YES;
	_mapView.delegate = self;
}

- (void)viewDidLayoutSubviews {
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonPushed:(id)sender {
	[_delegate closeGpxListPageWithName:@""];
}

- (void)listupGpxName {
	if(_isListDirty) {
		[_spinner startAnimating];
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(listupGpxNameDelayJob) userInfo:nil repeats:NO];
	}
}

- (void)listupGpxNameDelayJob {
	[_gpxManager loadGpxInfo];
	[_tableView reloadData];
	[_spinner stopAnimating];
	_isListDirty = NO;
}

#pragma mark - TableView Job


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_gpxManager.gpxList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	Gpx* aGpx = [_gpxManager.gpxList objectAtIndex:indexPath.row];
	cell.textLabel.text = aGpx.name;
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  GPX %@", [dateFormatter stringFromDate:aGpx.timestamp], (aGpx.version.length>0?aGpx.version:@"version unknown")];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[_spinner startAnimating];
	_selectedGpx = [_gpxManager.gpxList objectAtIndex:indexPath.row];
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(selectDelayJob) userInfo:nil repeats:NO];
}

- (void)selectDelayJob {
	[_delegate closeGpxListPageWithName:_selectedGpx.fileName];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	_selectedGpx = [_gpxManager.gpxList objectAtIndex:indexPath.row];
	[self showDetail];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (IBAction)tableEditButtonPushed:(id)sender {

	[_tableView setEditing:(!_tableView.editing) animated:YES];

	if(_tableView.editing) {
		_tableEditButton.title = @"Done";
	}
	else {
		_tableEditButton.title = @"Edit";
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		// GPXファイルを削除
		_selectedGpx = [_gpxManager.gpxList objectAtIndex:indexPath.row];
		[_selectedGpx deleteGpxData:_selectedGpx.fileName];
		[_gpxManager loadGpxInfo];

        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

    }
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
    }
}

#pragma mark - Detail job

- (void)showDetail {
	[self showDetail:YES];
}

- (void)hideDetail {
	[self showDetail:NO];
}

- (void)showDetail:(BOOL)flag {
	
	[UIView animateWithDuration:0.2f
					 animations:^{
						 CGRect rectTV = _tableViewBase.frame;
						 CGRect rectOV = _overTableView.frame;
						 if(flag==YES) {
							 rectTV.origin.x = 40-320;
							 rectOV.origin.x = 0;
							 _tableView.alpha = 0.7;
							 _overTableView.alpha = 1.0;
						 }
						 else {
							 rectTV.origin.x = 0;
							 rectOV.origin.x = -40;
							 _tableView.alpha = 1.0;
							 _overTableView.alpha = 0.0;
						 }
						 _tableViewBase.frame = rectTV;
						 _overTableView.frame = rectOV;
					 }
					 completion:^(BOOL finished){
						 // after animations
					 }];

	if(flag==YES) {
		_nameText.text = _selectedGpx.name;
		NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
		_timeLabel.text = [dateFormatter stringFromDate:_selectedGpx.timestamp];
		_timeSpanLabel.text = @"";
		[_mapSpinner startAnimating];
		_mapView.alpha = 0.3;
		
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(showDetailDelayJob) userInfo:nil repeats:NO];
	}
	else {
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(listupGpxName) userInfo:nil repeats:NO];
	//	[self listupGpxName];
	}
}

- (void)showDetailDelayJob {
	[self drawActivity];
	[_mapSpinner stopAnimating];

	[UIView animateWithDuration:1.0f
		animations:^{
			_mapView.alpha = 1.0;
        }
		completion:^(BOOL finished){
            // after animations
		}];
}

- (void)drawActivity {
	
	[_mapView removeOverlays:_mapView.overlays];

	[_selectedGpx loadGpxData:_selectedGpx.fileName];
	NSArray*	_locationItems = _selectedGpx.items;

	double minLat = 9999.0;
	double minLng = 9999.0;
	double maxLat = -9999.0;
	double maxLng = -9999.0;
	
	if(_locationItems) {
		if(_locationItems.count > 1) {
			CLLocationCoordinate2D coordinates[_locationItems.count];
			int cIndex = 0;
			for (int index = 0; index < _locationItems.count; index++) {
				GpxItem *gi = [_locationItems objectAtIndex:index];
				CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(gi.latitude, gi.longitude);
				coordinates[cIndex] = coordinate;
				cIndex++;

				if(gi.segmentStart) {
					// 移動軌跡を描く
					if(cIndex>1) {
						MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:cIndex-1];
						[_mapView addOverlay:polyLine level:MKOverlayLevelAboveRoads];
						cIndex = 0;
					}
				}
				
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
			MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:cIndex];
			[_mapView addOverlay:polyLine level:MKOverlayLevelAboveRoads];
			
			// マップの表示範囲を設定する
			CLLocationCoordinate2D center = CLLocationCoordinate2DMake((maxLat + minLat) / 2.0, (maxLng + minLng) / 2.0);
			MKCoordinateSpan span = MKCoordinateSpanMake((maxLat - minLat)*1.5, (maxLng - minLng)*1.5);
			MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
			[_mapView setRegion:[_mapView regionThatFits:region] animated:NO];

			// このコースの所要時間を表示する
			GpxItem *gi = [_locationItems objectAtIndex:0];
			NSDate* start = [NSDate dateWithTimeInterval:0 sinceDate:gi.timestamp];
			gi = [_locationItems objectAtIndex:_locationItems.count-1];
			NSDate* goal = [NSDate dateWithTimeInterval:0 sinceDate:gi.timestamp];
			
			int hour, minute, second;
			NSTimeInterval interval = [goal timeIntervalSinceDate:start];
			hour = interval / 3600;
			interval -= hour*3600;
			minute = interval / 60;
			interval -= minute*60;
			second = interval;
			NSString *talk;
			if(hour > 0) {
				talk = [NSString stringWithFormat:@"%d h %d m %d s", hour, minute, second];
			}
			else {
				talk = [NSString stringWithFormat:@"%d m %d s", minute, second];
			}
			_timeSpanLabel.text = talk;
		}
	}
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay {
	
	MKPolyline *polyline = (MKPolyline*)overlay;
	
	MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyline];
	renderer.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
	renderer.lineWidth = 5.0;
	
	return (MKOverlayRenderer*)renderer;
}

- (IBAction)shareButtonPushed:(id)sender {

	[self sendGpxFileByActivityView];
}

- (void)sendGpxFileByActivityView {
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:_selectedGpx.filePath]) {
//		NSURL *fileUrl     = [NSURL fileURLWithPath:_selectedGpx.filePath isDirectory:NO];
		NSArray *activityItems = @[[NSURL fileURLWithPath:_selectedGpx.filePath isDirectory:NO]];
		
		UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
		[self presentViewController:activityVC animated:YES completion:nil];
	}
}

#pragma mark - Name edit

- (IBAction)nameEditEnd:(id)sender {
//	NSLog(@"Edit end");
	if(![_selectedGpx.name isEqualToString:_nameText.text]) {
		_selectedGpx.name = _nameText.text;
		[_selectedGpx saveGpxData:_selectedGpx.fileName];
		_isListDirty = YES;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return [textField resignFirstResponder];
}



@end
