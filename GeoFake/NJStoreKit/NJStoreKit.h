
// 追加コンテンツプロダクトの最大数を設定
#define	NJSM_Product_CountMAX	10
// コンテンツの数についての定数定義
#define	k_NormalContentCount		0						// 通常コンテンツの数（公開中および予備）
#define	k_ExtraContentCount			1						// 追加コンテンツの最大数（課金コンテンツ） 　Item001〜
// item001 : クライアント接続
// Item002 :
// Item003 :
// Item004 :
#define	k_ExtraContentNotBought		-1

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class NJStoreManager;

@interface NJStoreObserver : NSObject<SKPaymentTransactionObserver>
- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
- (void) completeTransaction: (SKPaymentTransaction *)transaction;
- (void) restoreTransaction: (SKPaymentTransaction *)transaction;
@end

@protocol NJStoreManagerDeleagte
- (void)canNotMakePayments;
- (void)didReceivePurchasableProducts:(SKProductsResponse *)response;
- (void)failedToReceivePurchasableProducts;
- (void)productPurchaseCompleted:(NSString*)productIdentifier;
- (void)productPurchaseFailed:(SKPaymentTransaction *)transaction;
- (void)productPurchaseCanceled:(SKPaymentTransaction *)transaction;
@end

@interface NJStoreManager : NSObject<SKProductsRequestDelegate> {
 @private
	NSString		*appID;
	NJStoreObserver	*storeObserver;	
	id delegate;
}

@property (nonatomic, retain) NSString			*appID;
@property (nonatomic, retain) NJStoreObserver	*storeObserver;
@property (nonatomic, retain) id delegate;

+ (NJStoreManager*)sharedManager;
- (void) getProductInfoList:(NSArray*)productArray;
- (void) buyProduct:(NSString*) productId;
- (BOOL) didBuyFeature:(NSString*)productId;
- (void) restoreAllPurchase;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
- (void) cancelTransaction: (SKPaymentTransaction *)transaction;
- (void) provideContent: (NSString*) productIdentifier;
- (void) restoreCompleted:(BOOL)isOK;

@end
