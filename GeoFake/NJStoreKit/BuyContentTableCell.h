
#import <UIKit/UIKit.h>


@interface BuyContentTableCell : UITableViewCell {
	IBOutlet UILabel *title_Label;
	IBOutlet UILabel *description_Label;
	IBOutlet UILabel *price_Label;
	IBOutlet UIImageView *photo;
}

@property (nonatomic, retain) UILabel *title_Label;
@property (nonatomic, retain) UILabel *description_Label;
@property (nonatomic, retain) UILabel *price_Label;
@property (nonatomic, retain) UIImageView *photo;

@end
