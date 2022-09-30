//
//  NJStoreObserver.m
//
//  Created by Yos Hashimoto on 10/10/03.
//  Copyright 2010 Newton Japan Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface NJStoreObserver : NSObject<SKPaymentTransactionObserver> {

}


- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;
- (void) completeTransaction: (SKPaymentTransaction *)transaction;
- (void) restoreTransaction: (SKPaymentTransaction *)transaction;

@end
