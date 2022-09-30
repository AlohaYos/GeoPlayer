
#import <Foundation/Foundation.h>

typedef void(^actionType)(void);

@interface RIButtonItem : NSObject
{
    NSString *label;
    void (^action)();
}
@property (retain, nonatomic) NSString *label;
@property (copy, nonatomic) void (^action)();
+(id)item;
+(id)itemWithLabel:(NSString *)inLabel;
+(id)itemWithLabel:(NSString *)inLabel withAction:(actionType) action;
+(id)itemWithLabel:(NSString *)inLabel withDelegate:(id)delegate withSelector:(SEL) selector;
@end

