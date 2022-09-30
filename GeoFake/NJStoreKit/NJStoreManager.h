//
//  NJStoreManager.h
//
//  Created by Yos Hashimoto on 10/10/03.
//  Copyright 2010 Newton Japan Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "NJStoreDefine.h"
#import "NJStoreObserver.h"

@class NJStoreManager;


@protocol NJStoreManagerDeleagte
// 購入できないエラーの通知（ペアレントコントロールなど）
- (void)canNotMakePayments;
// 購入できるプロダクトの情報取得完了
- (void)didReceivePurchasableProducts:(SKProductsResponse *)response;
// 購入できるプロダクトの情報取得失敗（指定したプロダクトIDが無いなど）
- (void)failedToReceivePurchasableProducts;
// プロダクトの購入完了
- (void)productPurchaseCompleted:(NSString*)productIdentifier;
// プロダクトの購入失敗
- (void)productPurchaseFailed:(SKPaymentTransaction *)transaction;

@end


@interface NJStoreManager : NSObject<SKProductsRequestDelegate> {

  @private
	NSString		*appID;
//	NSMutableArray	*productToSell;
//	NSMutableArray	*purchasableObjects;
	NJStoreObserver	*storeObserver;	
	id delegate;	// 購入完了を通知するデリゲート
}

@property (nonatomic, retain) NSString			*appID;
//@property (nonatomic, retain) NSMutableArray	*productToSell;
//@property (nonatomic, retain) NSMutableArray	*purchasableObjects;
@property (nonatomic, retain) NJStoreObserver	*storeObserver;
@property (nonatomic, retain) id delegate;


// -- クラスメソッド
+ (NJStoreManager*)sharedManager;

// InAppプロダクトの購入
- (void) buyProduct:(NSString*) productId;

// InAppプロダクトの購入確認
- (BOOL) didBuyFeature:(NSString*)productId;

@end
