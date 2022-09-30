//
//  NJStoreManager.m
//
//  Created by Yos Hashimoto on 10/10/03.
//  Copyright 2010 Newton Japan Inc. All rights reserved.
//

#import "NJStoreKit.h"

// プライベートメソッド
@interface NJStoreManager ()
- (void) requestProductData:(NSString*)productId;
// クラス内デリゲートメソッド
- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response;
- (void) provideContent: (NSString*) productIdentifier;
- (void) cancelTransaction: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
@end


// インプリメンテーション
@implementation NJStoreManager

@synthesize storeObserver;
@synthesize	delegate;
@synthesize	appID;


static NJStoreManager* _sharedStoreManager; // self

#pragma mark -
#pragma mark Object Life Cycle

+ (NJStoreManager*)sharedManager
{
	@synchronized(self) {
		
        if (_sharedStoreManager == nil) {
            _sharedStoreManager = [[self alloc] init]; // assignment not done here
			_sharedStoreManager.appID = [[NSBundle mainBundle] bundleIdentifier];
			NSLog(@"Purchase check appID=%@", _sharedStoreManager.appID);
			_sharedStoreManager.storeObserver = [[NJStoreObserver alloc] init];
			[[SKPaymentQueue defaultQueue] addTransactionObserver:_sharedStoreManager.storeObserver];
        }
    }
    return _sharedStoreManager;
}

- (void)dealloc {
}


#pragma mark -
#pragma mark パブリックメソッド

- (void) restoreAllPurchase {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) restoreCompleted:(BOOL)isOK {
	[delegate restoreCompleted:isOK];
}

// プロダクトの購入
BOOL proceedToBuyProduct = NO;

- (void) checkProduct:(NSString*) productId
{
	// ペアレンタルコントロールをチェック
	if ([SKPaymentQueue canMakePayments])
	{
		// AppID+プロダクトIDで、プロダクトが販売できる状態かどうかリストアップ
		NSString *prod = productId;
		//NSString *prod = [NSString stringWithFormat:@"%@.%@", appID, productId];
		NSLog(@"Purchase check product ID=%@", prod);
		
		[self requestProductData:prod];
		proceedToBuyProduct = NO;
	}
	else
	{
		// 購入できない
		[delegate canNotMakePayments];
	}
}

-(void)getProductInfoList:(NSArray*)productArray {	// productArrayは文字列の配列 ... @"item001", @"item002", @"item003" ...
	proceedToBuyProduct = NO;

	SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray:productArray]];
	request.delegate = self;
	[request start];
}

- (void) buyProduct:(NSString*) productId
{
#if 1
	[self checkProduct:productId];
	proceedToBuyProduct = YES;
#else
	// ペアレンタルコントロールをチェック
	if ([SKPaymentQueue canMakePayments])
	{
		// AppID+プロダクトIDで、プロダクトが販売できる状態かどうかリストアップ
		NSString *prod = [NSString stringWithFormat:@"%@.%@", appID, productId];
		NSLog(@"Purchase check product ID=%@", prod);

		[self requestProductData:prod];
		proceedToBuyProduct = YES;
	}
	else
	{
		// 購入できない
		[delegate canNotMakePayments];
	}
#endif
}

// InAppプロダクトの購入確認
- (BOOL) didBuyFeature:(NSString*)productId {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	BOOL result = [userDefaults boolForKey:productId]; 
	if(!result) result = NO;
//	if(result == nil) result = NO;
	
	return result;
}


#pragma mark -
#pragma mark プライベートメソッド

// 購入できるアイテムリスト
- (void) requestProductData:(NSString*)productId {
	SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithObjects: productId, nil]];
	request.delegate = self;
	[request start];
}

#pragma mark -
#pragma mark クラス内デリゲート

// 購入できるアイテムリスト
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSLog(@"Purchase check product count=%lu", (unsigned long)[response.products count]);

	if([response.products count] < 1) {
		for(int i=0; i<[response.invalidProductIdentifiers count]; i++) {
			NSString *str = [response.invalidProductIdentifiers objectAtIndex:i];
			NSLog(@"Invalid product=%@", str);
		}
		
		[delegate failedToReceivePurchasableProducts];
		return;
	}
	
	// ToDo: 商品の問い合わせ完了デリゲートを発生させる
	[delegate didReceivePurchasableProducts:response];
	
	// 引き続き購入に移る
	if(proceedToBuyProduct == YES) {
		proceedToBuyProduct = NO;
		SKProduct *product = [response.products objectAtIndex:0];
		NSLog(@"Product:%@, ID:%@",product.localizedTitle, product.productIdentifier);

		SKPayment *payment = [SKPayment paymentWithProduct:product];
		//SKPayment *payment = [SKPayment paymentWithProductIdentifier:[product productIdentifier]];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	}
}

// 購入成功コールバック
-(void) provideContent: (NSString*) productIdentifier
{
	// 購入したアイテムをUserDefaultsに記録する
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:YES forKey:productIdentifier];

	// 購入完了デリゲートを発生させる
	[delegate productPurchaseCompleted:productIdentifier];
	
}

// 購入中断コールバック
- (void) cancelTransaction: (SKPaymentTransaction *)transaction
{
	// 購入失敗デリゲートを発生
	[delegate productPurchaseCanceled:transaction];
	return;
}

// 購入失敗コールバック
- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
	NSLog(@"%@", transaction.error);
	
	// 購入失敗デリゲートを発生
	[delegate productPurchaseFailed:transaction];
	return;
}

#pragma mark -
#pragma mark Singleton Methods

+ (id)allocWithZone:(NSZone *)zone

{	
    @synchronized(self) {
		
        if (_sharedStoreManager == nil) {
			
            _sharedStoreManager = [super allocWithZone:zone];			
            return _sharedStoreManager;  // assignment and return on first allocation
        }
    }
	
    return nil; //on subsequent allocation attempts return nil	
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;	
}

#if 0
- (id)retain
{	
    return self;	
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;	
}
#endif

@end
