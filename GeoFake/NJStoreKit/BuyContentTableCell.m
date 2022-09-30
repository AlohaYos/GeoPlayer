
#import "BuyContentTableCell.h"

@implementation BuyContentTableCell

@synthesize title_Label;
@synthesize description_Label;
@synthesize price_Label;
@synthesize photo;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        // Initialization code
		self.frame = frame;
    }
    return self;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];
}
- (void)dealloc {
#if 0
	[title_Label release];
	[description_Label release];
	[price_Label release];
	[photo release];
    [super dealloc];
#endif
}

@end
