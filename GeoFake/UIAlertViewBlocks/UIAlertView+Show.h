
#import <UIKit/UIKit.h>
#import "RIButtonItem.h"
#import "RIButtonItem+NoAction.h"

@interface UIAlertView (Show)

+(void)showWithTitle:(NSString *)inTitle message:(NSString *)inMessage cancelButtonItem:(RIButtonItem *)inCancelButtonItem otherButtonItems:(RIButtonItem *)inOtherButtonItems, ... NS_REQUIRES_NIL_TERMINATION;
+(void)showToast:(NSString *)inTitle message:(NSString *)inMessage;

@end
