
#import "BuyContentTableCellController.h"

@implementation BuyContentTableCellController

@synthesize cell;

- (void)didReceiveMemoryWarning {

    [super didReceiveMemoryWarning];
}
- (void)dealloc {
#if 0
	if( cell != nil ){
		[cell release];
		cell = nil;
	}

    [super dealloc];

#endif
}
@end
