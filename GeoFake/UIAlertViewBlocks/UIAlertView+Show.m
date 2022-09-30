
#import "UIAlertView+Show.h"
#import "UIAlertView+Blocks.h"
#import <objc/runtime.h>

@implementation UIAlertView (Show)

static NSString *RI_BUTTON_ASS_KEY = @"com.random-ideas.BUTTONS";

+(void)showWithTitle:(NSString *)inTitle message:(NSString *)inMessage cancelButtonItem:(RIButtonItem *)inCancelButtonItem otherButtonItems:(RIButtonItem *)inOtherButtonItems, ...
{
    NSMutableArray *buttonsArray = [NSMutableArray array];
    
    RIButtonItem *eachItem;
    va_list argumentList;
    if (inOtherButtonItems)
    {
        [buttonsArray addObject: inOtherButtonItems];
        va_start(argumentList, inOtherButtonItems);
        while((eachItem = va_arg(argumentList, RIButtonItem *)))
        {
            [buttonsArray addObject: eachItem];
        }
        va_end(argumentList);
    }
    
    UIAlertView *alert = [[self alloc] initWithTitle:inTitle message:inMessage cancelButtonItem:inCancelButtonItem otherNSMutableArrayButtonItems:buttonsArray];
    [alert show];

}

+(void)showToast:(NSString *)inTitle message:(NSString *)inMessage{
    RIButtonItem *NoActionOkButton = [RIButtonItem NoActionOkItem];
    UIAlertView *alert = [[self alloc] initWithTitle:inTitle message:inMessage cancelButtonItem:NoActionOkButton otherNSMutableArrayButtonItems:nil];
    [alert show];
    
}

-(id)initWithTitle:(NSString *)inTitle message:(NSString *)inMessage cancelButtonItem:(RIButtonItem *)inCancelButtonItem otherNSMutableArrayButtonItems:(NSMutableArray *)inOtherButtonItems
{
    if((self = [self initWithTitle:inTitle message:inMessage delegate:self cancelButtonTitle:inCancelButtonItem.label otherButtonTitles:nil]))
    {
        for(RIButtonItem *item in inOtherButtonItems)
        {
            [self addButtonWithTitle:item.label];
        }
        
        if(inCancelButtonItem){
            [inOtherButtonItems insertObject:inCancelButtonItem atIndex:0];
        }
        
        objc_setAssociatedObject(self, (__bridge const void *)RI_BUTTON_ASS_KEY, inOtherButtonItems, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self setDelegate:self];
    }
    return self;
}

@end
