
#import "BuyContentViewController.h"
#import "BuyContentTableCellController.h"
#import "BuyContentTableCell.h"
#import "GeoFakeAppDelegate.h"

@implementation BuyContentViewController
@synthesize tableView;
@synthesize tableViewHeader;
@synthesize tableViewFooter;
@synthesize tableViewHeaderLabel;
@synthesize tableViewFooterLabel;
@synthesize tableViewFooterButton;
@synthesize purchaseShutterView;


#pragma mark Buy Procedure

- (void)buyContent:(NSString*)contentID {
	NSLog(@"Buy content '%@'", contentID);
	NJStoreManager *storeManager = [NJStoreManager sharedManager];
	storeManager.delegate = self;
	[storeManager buyProduct:contentID];
	
	purchaseShutterView.hidden = NO;
}

#pragma mark -
#pragma mark In App Purchase delegate

// 購入できないエラーの通知（ペアレントコントロールなど）
- (void)canNotMakePayments {
	NSLog(@"プロダクト購入不可（ペアレントコントロールなど）");
	[tableView reloadData];
	purchaseShutterView.hidden = YES;
}

// 購入できるプロダクトの情報取得完了
- (void)didReceivePurchasableProducts:(SKProductsResponse *)response {
	NSLog(@"プロダクトリスト取得完了");
}

// 購入できるプロダクトの情報取得失敗（指定したプロダクトIDが無いなど）
- (void)failedToReceivePurchasableProducts {
	NSLog(@"プロダクトリスト取得失敗");
	[tableView reloadData];
	purchaseShutterView.hidden = YES;
}

// プロダクトの購入完了
-(void)productPurchaseCompleted:(NSString*)productIdentifier {
	NSLog(@"プロダクト購入完了");

	// 課金済みにする
	GeoFakeAppDelegate *appDelegate = (GeoFakeAppDelegate *)[[UIApplication sharedApplication] delegate];
	int purchaseCount = [appDelegate.extraContent getEnabledItemCount];
	[appDelegate.extraContent setItemStatusNamed:productIdentifier status:purchaseCount+1];
	
	[tableView reloadData];
	purchaseShutterView.hidden = YES;
}

// プロダクトの購入中断
- (void)productPurchaseCanceled:(SKPaymentTransaction *)transaction {
	NSLog(@"プロダクト購入キャンセル");
	[tableView reloadData];
	purchaseShutterView.hidden = YES;
}

// プロダクトの購入失敗
- (void)productPurchaseFailed:(SKPaymentTransaction *)transaction {
	NSLog(@"プロダクト購入失敗");
	[tableView reloadData];
	purchaseShutterView.hidden = YES;
}


#pragma mark Restore Procedure

- (IBAction)restoreButtonTapped:(id)sender {
	NSLog(@"Restore content");

	purchaseShutterView.hidden = NO;

	NJStoreManager *storeManager = [NJStoreManager sharedManager];
	storeManager.delegate = self;
	[storeManager restoreAllPurchase];
}

-(void)restoreCompleted:(BOOL)isOK {
	[tableView reloadData];
	purchaseShutterView.hidden = YES;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return k_ExtraContentCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *identifier = @"BuyContentTableCell";
	BuyContentTableCell *cell_ = (BuyContentTableCell *)[tableView_ dequeueReusableCellWithIdentifier:identifier];
	if (cell_ == nil) {
		BuyContentTableCellController *controller = [[BuyContentTableCellController alloc] initWithNibName:identifier bundle:nil];
		cell_ = (BuyContentTableCell *)controller.view;
	}

	GeoFakeAppDelegate *appDelegate = (GeoFakeAppDelegate *)[[UIApplication sharedApplication] delegate];
//	AppData *appData = appDelegate.appData;
	
	[cell_.title_Label setText:[appDelegate.extraContent getItemTitle:(int)indexPath.row]];
	[cell_.description_Label setText:[appDelegate.extraContent getItemDescription:(int)indexPath.row]];
	[cell_.photo setImage:[UIImage imageNamed:[appDelegate.extraContent getItemID:(int)indexPath.row]]];
	cell_.photo.contentMode = UIViewContentModeScaleAspectFit;

	int purchaseOrder = [appDelegate.extraContent getItemStatus:(int)indexPath.row];
	if(purchaseOrder > 0) {
		// 購入済み
		cell_.title_Label.alpha = 0.4;
		cell_.description_Label.alpha = 0.4;
		cell_.photo.alpha = 0.4;
		[cell_.price_Label setText:@"Purchased"];
	}
	else {
		// 未購入
		cell_.title_Label.alpha = 1.0;
		cell_.description_Label.alpha = 1.0;
		cell_.photo.alpha = 1.0;
		[cell_.price_Label setText:[appDelegate.extraContent getContentPrice:[NSString stringWithFormat:@"item%03ld", indexPath.row+k_NormalContentCount+1]]];
		//[cell_.price_Label setText:[appDelegate.extraContent getContentPrice:[NSString stringWithFormat:@"G%03d", indexPath.row+k_NormalContentCount+1]]];
	}

	return cell_;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 90.0;
}

- (void)tableView:(UITableView *)tableView_ didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	GeoFakeAppDelegate *appDelegate = (GeoFakeAppDelegate *)[[UIApplication sharedApplication] delegate];
	int purchaseOrder = [appDelegate.extraContent getItemStatus:(int)indexPath.row];
	if(purchaseOrder < 0) {
		// 追加コンテンツの購入処理　contentID=@"item003"など
		NSString *contentID = [NSString stringWithFormat:@"item%03ld", indexPath.row+k_NormalContentCount+1];
		[self buyContent:contentID];
	}
	else {
		[tableView_ deselectRowAtIndexPath:indexPath animated:NO];
	}
}

#pragma mark - Content information delayed callback

// 追加コンテンツの情報をサーバから遅延受信した際に、テーブルを書き直す
-(void)didReceiveContentsInfo {
	[tableView reloadData];
	GeoFakeAppDelegate *appDelegate = (GeoFakeAppDelegate *)[[UIApplication sharedApplication] delegate];
	appDelegate.extraContent.completeCallbackDelegate = nil;
}

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.title = @"追加アイテムの購入";
//	tableViewHeaderLabel.text = NSLocalizedString( @"BuyContentView_Header", nil );
//	tableViewFooterLabel.text = NSLocalizedString( @"BuyContentView_Footer", nil );
	[tableViewFooterButton setTitle:@"Restore" forState:UIControlStateNormal];
	[tableViewFooterButton setTitle:@"Restore" forState:UIControlStateHighlighted];
	[tableViewFooterButton setTitle:@"Restore" forState:UIControlStateSelected];
	tableView.delegate = self;
//	tableView.dataSource = self;

	GeoFakeAppDelegate *appDelegate = (GeoFakeAppDelegate *)[[UIApplication sharedApplication] delegate];
	if(appDelegate.extraContent.itemCount == 0) {	// まだ追加コンテンツの情報が取得できていなかったら
		// 取得コールバックを自分に向ける
		appDelegate.extraContent.completeCallbackDelegate = self;
	}
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setTableViewHeader:nil];
    [self setTableViewFooter:nil];
	[self setTableViewHeaderLabel:nil];
	[self setTableViewFooterLabel:nil];
	[self setTableViewFooterButton:nil];
	[self setPurchaseShutterView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
#if 0
    [tableView release];
    [tableViewHeader release];
    [tableViewFooter release];
	[tableViewHeaderLabel release];
	[tableViewFooterLabel release];
	[tableViewFooterButton release];
	[purchaseShutterView release];
    [super dealloc];
#endif
}

- (IBAction)donButtonPushed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
