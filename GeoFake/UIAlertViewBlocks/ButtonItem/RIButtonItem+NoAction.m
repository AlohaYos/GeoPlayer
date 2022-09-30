
#import "RIButtonItem+NoAction.h"

@implementation RIButtonItem (NoAction)

+(id) NoActionWitTitelItem:(NSString *)title{
    RIButtonItem *item = [self item];
    item.label = title;
    item.action = ^{};
    return item;
}

+(id) NoActionOkItem{
    RIButtonItem *item = [self item];
    item.label = @"OK";
    item.action = ^{};
    return item;
}


@end
