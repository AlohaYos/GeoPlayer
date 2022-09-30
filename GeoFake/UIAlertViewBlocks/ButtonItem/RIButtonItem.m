
#import "RIButtonItem.h"

@implementation RIButtonItem
@synthesize label;
@synthesize action;


+(id)item
{
    return [self new];
}

+(id)itemWithLabel:(NSString *)inLabel
{
    RIButtonItem *newItem = [self item];
    [newItem setLabel:inLabel];
    return newItem;
}

+(id)itemWithLabel:(NSString *)inLabel withAction:(actionType) action
{
    RIButtonItem *newItem = [self item];
    [newItem setLabel:inLabel];
    [newItem setAction:action];
    
    return newItem;
}

+(id)itemWithLabel:(NSString *)inLabel withDelegate:(id)delegate withSelector:(SEL) selector
{
    RIButtonItem *newItem = [self item];
    [newItem setLabel:inLabel];
    
    actionType action = ^{
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [delegate performSelector:selector];
        #pragma clang diagnostic pop
    };
    newItem.action = action;
    
    return newItem;
}

@end

