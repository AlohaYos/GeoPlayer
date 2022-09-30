//
//  ExtraContent.m
//  GeishaGuide
//

#import "ExtraContent.h"

@implementation ExtraContent

@synthesize itemCount;
@synthesize completeCallbackDelegate;

-(id)init {
	completeCallbackDelegate = nil;
	[self getSavedStatus];
	[self getExtraContentInfo];
	return self;
}

-(NSString*)getItemID:(int)index {
	if(index < k_ExtraContentCount)
		return itemID[index];
	
	return @"";
}

-(NSString*)getItemTitle:(int)index {
	if(index < k_ExtraContentCount)
		return itemTitle[index];
	
	return @"";
}

-(NSString*)getItemDescription:(int)index {
	if(index < k_ExtraContentCount)
		return itemDescription[index];
	
	return @"";
}


#pragma mark -
#pragma mark 追加コンテンツ情報の取得

-(NSString *)getContentPrice:(NSString *)contentID {
	for(int i=0; i < itemCount; i++) {
		if([contentID isEqualToString:itemID[i]]) {
			return itemPriceStr[i];
		}
	}
	return @"---";	// 価格が取得できなかった
}

- (void)getExtraContentInfo {
	NJStoreManager *storeManager = [NJStoreManager sharedManager];
	storeManager.delegate = self;
	NSMutableArray *contentList = [[NSMutableArray alloc] initWithCapacity:1];
	for(int i=0; i<k_ExtraContentCount; i++) {
		NSString *strTmp = [NSString stringWithFormat:@"item%03d", i+k_NormalContentCount+1];
		//NSString *strTmp = [NSString stringWithFormat:@"G%03d", i+k_NormalContentCount+1];
		[contentList addObject:strTmp];
	}
	itemCount = 0;
	[storeManager getProductInfoList:contentList];
}

// 購入できるプロダクトの情報取得完了
- (void)didReceivePurchasableProducts:(SKProductsResponse *)response {
	NSLog(@"プロダクトリスト取得完了");
	SKProduct *product;
	for(int i=0;i<[response.products count];i++)
	{
		product = [response.products objectAtIndex:i];
		
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
		[numberFormatter setLocale:product.priceLocale];
		NSString *formattedString = [numberFormatter stringFromNumber:product.price];
		
		itemID[i] = [product.productIdentifier copy];
		itemTitle[i] = [product.localizedTitle copy];
		itemDescription[i] = [product.localizedDescription copy];
		itemPriceStr[i] = [formattedString copy];

		NSLog(@"Product:%@, Price:%@, ID:%@ (%@)",itemTitle[i], itemPriceStr[i], itemID[i], itemDescription[i]);
	}
	itemCount = (int)[response.products count];
	
	if(completeCallbackDelegate)
		[completeCallbackDelegate didReceiveContentsInfo];
}

// 購入できるプロダクトの情報取得失敗（指定したプロダクトIDが無いなど）
- (void)failedToReceivePurchasableProducts {
	NSLog(@"プロダクトリスト取得失敗");
}

- (void)canNotMakePayments {
	
}

- (void)productPurchaseCompleted:(NSString*)productIdentifier {
	
}

- (void)productPurchaseFailed:(SKPaymentTransaction *)transaction {
	
}

- (void)productPurchaseCanceled:(SKPaymentTransaction *)transaction {
	
}



#pragma mark -
#pragma mark 購入状況の取得

// 購入数を得る
-(int)getEnabledItemCount {
	
	int result = 0;
	for(int i=0; i<k_ExtraContentCount; i++) {
		if(itemStatus[i] > 0)
			result++;
	}
	return result;
}

// 購入順を得る（number番目に購入されたitemのindexを返す
-(int)getItemIndexInPurchaseOrder:(int)number {

	if([self getEnabledItemCount] == 0) return -1;		// 何も購入されていない
	if([self getEnabledItemCount] < number) return -1;	// 購入数の上限を超えた値を指定している
	
	for(int i=0; i<k_ExtraContentCount; i++) {
		if(itemStatus[i] == number)
			return i;
	}
	return -1;
}

// 追加コンテンツの購入状況を得る
-(int)getItemStatus:(int)index {
	int retValue = k_ExtraContentNotBought;
	
	if((index>=0)&&(index<k_ExtraContentCount)) {
		retValue = itemStatus[index];
	}

	return retValue;
}

-(void)getSavedStatus {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	for(int i=0; i<k_ExtraContentCount; i++) {
		NSInteger intTmp = [defs integerForKey:[NSString stringWithFormat:@"_3_itemStatusItem%03d", i+k_NormalContentCount+1]];
		//NSInteger intTmp = [defs integerForKey:[NSString stringWithFormat:@"_3_itemStatusG%03d", i+k_NormalContentCount+1]];
		if(intTmp <= 0) intTmp = -1;	// 初期設定
		itemStatus[i] = (int)intTmp;
	}
	
	// ##### Debug #####
//	itemStatus[5] = 1;	// G008
//	itemStatus[4] = 2;	// G007
//	itemStatus[0] = -1;	// G003を未購入にする
	
}

#pragma mark -
#pragma mark 購入状況の保存

// 追加コンテンツの購入状況を記録する
-(void)setItemStatus:(int)index status:(int)status {
	if((index>=0)&&(index<k_ExtraContentCount)) {
		itemStatus[index] = status;
		[self saveStatus];
	}
}

// indexStr==@"item003" など
-(void)setItemStatusNamed:(NSString *)indexStr status:(int)status {
	
	NSString* numStr = [indexStr stringByReplacingOccurrencesOfString:@"item" withString:@""];
	//NSString* numStr = [indexStr stringByReplacingOccurrencesOfString:@"G" withString:@""];
	int index = [numStr	intValue] - k_NormalContentCount-1;
	if(itemStatus[index] < 0) {	// すでに購入済みの場合には状態を変えない（リストアでのダブり購入を防ぐため）
		[self setItemStatus:index status:status];
	}
}

-(void)saveStatus {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	for(int i=0; i<k_ExtraContentCount; i++) {
		[defs setInteger:itemStatus[i] forKey:[NSString stringWithFormat:@"_3_itemStatusItem%03d", i+k_NormalContentCount+1]];
		//[defs setInteger:itemStatus[i] forKey:[NSString stringWithFormat:@"_3_itemStatusG%03d", i+k_NormalContentCount+1]];
	}
}

@end
