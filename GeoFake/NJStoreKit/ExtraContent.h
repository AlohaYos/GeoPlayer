//
//  ExtraContent.h
//  GeishaGuide
//

#import <Foundation/Foundation.h>
#import	"NJStoreKit.h"
#import "BuyContentViewController.h"

@interface ExtraContent : NSObject <NJStoreManagerDeleagte> {
	BuyContentViewController *completeCallbackDelegate;					// コンテンツ情報の取得が完了した際のコールバック先ポインタ
	
	int	itemCount;									// 購入できるコンテンツ数
	int	itemStatus[k_ExtraContentCount];			// -1:未購入、1〜:何番目に購入したか
	NSString *itemID[k_ExtraContentCount];			// ID
	NSString *itemTitle[k_ExtraContentCount];		// タイトル
	NSString *itemDescription[k_ExtraContentCount];	// 説明
	NSString *itemPriceStr[k_ExtraContentCount];	// 現在ロケールでの価格文字列
}

@property (nonatomic, retain)	BuyContentViewController *completeCallbackDelegate;
@property (nonatomic)	int itemCount;

-(id)init;
-(int)getEnabledItemCount;
-(int)getItemIndexInPurchaseOrder:(int)number;
-(int)getItemStatus:(int)index;
-(void)setItemStatus:(int)index status:(int)status;
-(void)setItemStatusNamed:(NSString*)indexStr status:(int)status;
-(void)saveStatus;
-(void)getSavedStatus;
-(NSString *)getContentPrice:(NSString *)contentID;
- (void)getExtraContentInfo;

- (void)canNotMakePayments;
- (void)productPurchaseCompleted:(NSString*)productIdentifier;
- (void)productPurchaseFailed:(SKPaymentTransaction *)transaction;

-(NSString*)getItemID:(int)index;
-(NSString*)getItemTitle:(int)index;
-(NSString*)getItemDescription:(int)index;

@end
