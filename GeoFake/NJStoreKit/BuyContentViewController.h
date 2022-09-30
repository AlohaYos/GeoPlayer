
#import <UIKit/UIKit.h>
#import	"NJStoreKit.h"

@interface BuyContentViewController : UIViewController <UITableViewDelegate, NJStoreManagerDeleagte> {
	
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIView *tableViewHeader;
@property (retain, nonatomic) IBOutlet UIView *tableViewFooter;
@property (retain, nonatomic) IBOutlet UILabel *tableViewHeaderLabel;
@property (retain, nonatomic) IBOutlet UILabel *tableViewFooterLabel;
@property (retain, nonatomic) IBOutlet UIButton *tableViewFooterButton;

@property (retain, nonatomic) IBOutlet UIView *purchaseShutterView;

- (IBAction)restoreButtonTapped:(id)sender;
- (void)didReceiveContentsInfo;

@end
