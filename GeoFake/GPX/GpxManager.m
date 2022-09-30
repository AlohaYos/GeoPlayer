//
//  GpxManager.m
//  GeoFake
//
//  Created by Yos Hashimoto on 2013/12/28.
//  Copyright (c) 2013年 Newton Japan. All rights reserved.
//

#import "GpxManager.h"

@implementation GpxManager

- (id)init {
	self = [super init];
	
	_gpxList = [[NSMutableArray alloc] initWithCapacity:1];

	return self;
}

// すべてのBook情報を取り込む
-(void)loadGpxInfo {

	[_gpxList removeAllObjects];

    //ドキュメントフォルダの場所を取得
	NSString* folderPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	
    //ファイル一覧の取得
    NSError *error;
    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error];
	//NSLog(@"arr = %@", arr);
	
    for(NSString *item in arr){
        if([item isEqualToString:@".DS_Store"] == YES) continue;
		if([item hasSuffix:@".gpx"] == YES) {
			
			NSString* fileName = [item stringByReplacingOccurrencesOfString:@".gpx" withString:@""];
			Gpx* aGpx = [[Gpx alloc] init];
			[aGpx loadGpxMeta:fileName];
			[_gpxList addObject:aGpx];
			
			//NSString* fileName = [item stringByReplacingOccurrencesOfString:@".gpx" withString:@""];
			//[_gpxList addObject:fileName];
		}
    }
	
	// name順に並び替え
    [_gpxList sortUsingComparator:
	 ^(Gpx *item1, Gpx *item2) {
		 return [item1.name compare:item2.name];
	 }];

}



@end
