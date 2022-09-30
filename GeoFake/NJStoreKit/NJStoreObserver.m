//
//  NJStoreObserver.m
//
//  Created by Yos Hashimoto on 10/10/03.
//  Copyright 2010 Newton Japan Inc. All rights reserved.
//

#import "NJStoreKit.h"

@implementation NJStoreObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				
                [self completeTransaction:transaction];
				
                break;
				
            case SKPaymentTransactionStateFailed:
				
                [self failedTransaction:transaction];
				
                break;
				
            case SKPaymentTransactionStateRestored:
				
                [self restoreTransaction:transaction];
				
            default:
				
                break;
		}			
	}
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{	
    if (transaction.error.code != SKErrorPaymentCancelled)		
    {		
        // トランザクションがエラーになった
		[[NJStoreManager sharedManager] failedTransaction:transaction];	
    }
	else {
        // ユーザーによりキャンセルされた場合
		[[NJStoreManager sharedManager] cancelTransaction:transaction];	
	}
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{		
    [[NJStoreManager sharedManager] provideContent: transaction.payment.productIdentifier];	
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{	
    [[NJStoreManager sharedManager] provideContent: transaction.originalTransaction.payment.productIdentifier];	
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
}


- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
	NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    [[NJStoreManager sharedManager] restoreCompleted:YES];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	NSLog(@"restoreCompletedTransactionsFailedWithError");
    [[NJStoreManager sharedManager] restoreCompleted:NO];
}

@end
