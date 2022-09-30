//
//  GeoFakeAppDelegate.m
//  GeoFake
//
//  Created by Yos Hashimoto on 2013/12/26.
//  Copyright (c) 2013年 Newton Japan. All rights reserved.
//

#import "GeoFakeAppDelegate.h"

@implementation GeoFakeAppDelegate

@synthesize extraContent;

static NSString* downloadGpxFileName;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[application setIdleTimerDisabled:YES];
	
	if(!extraContent) {
		extraContent = [[ExtraContent alloc] init];
	}

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url_ sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	NSLog(@"Open URL:\t%@\n" "From source:\t%@\n" "With annotation:%@", url_, sourceApplication, annotation);

	NSString* orgPath  = url_.absoluteString;

	// Safariからの起動
	if([sourceApplication isEqualToString:@"com.apple.mobilesafari"]) {
	//	NSString *absoluteString = [url_ absoluteString];		// geoplay://newtonjapan.com/GeoPlayer/GpxFile/JobsToApple.gpx
		NSString *resourceSpecifier = [url_ resourceSpecifier];	// //newtonjapan.com/GeoPlayer/GpxFile/JobsToApple.gpx
		downloadGpxFileName = [resourceSpecifier stringByReplacingOccurrencesOfString:@"//newtonjapan.com/GeoPlayer/GpxFile/" withString:@""];	// JobsToApple.gpx

		if([resourceSpecifier hasSuffix:@".gpx"]) {
			NSString* downloadBookUrlString = [NSString stringWithFormat:@"http:%@", resourceSpecifier];
			[self loadImageFromRemote:downloadBookUrlString];
			return YES;
		}
	}

	// GPXファイルの取込み処理
	if([[orgPath lowercaseString] hasSuffix:@".gpx"]) {
		NSString* srcPath = [[orgPath stringByReplacingOccurrencesOfString:@"file:///private" withString:@""] stringByRemovingPercentEncoding];
		NSString* dirPath = [NSString stringWithFormat:@"%@/", [srcPath stringByDeletingLastPathComponent]];
		NSString* fileName = [srcPath stringByReplacingOccurrencesOfString:dirPath withString:@""];
		
		NSString* documentPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
		NSString* distPath=[documentPath stringByAppendingPathComponent:fileName];

		for(int i=0; i<10-1; i++) {
			if([[NSFileManager defaultManager] fileExistsAtPath:distPath]) {
				distPath = [distPath stringByReplacingOccurrencesOfString:@".gpx" withString:@"_.gpx"];
			}
			else {
				break;
			}
		}

		NSError *error;
		[[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:distPath error:&error];
		
		NSString* inboxPath = [srcPath stringByReplacingOccurrencesOfString:fileName withString:@""];
		[[NSFileManager defaultManager] removeItemAtPath:inboxPath error:&error];
		
		#pragma clang diagnostic ignored "-Wundeclared-selector"
		UIViewController* vc = self.window.rootViewController;
		if([vc respondsToSelector:@selector(preparePlaybackFor:)]) {
			NSString* gpxName = [fileName stringByReplacingOccurrencesOfString:@".gpx" withString:@""];
			[vc performSelector:@selector(preparePlaybackFor:) withObject:gpxName];
		}
	}
	
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

	
// HTTP からファイルをロード
- (void)loadImageFromRemote:(NSString*)fileUrlString
{
	// 読み込むファイルの URL を作成
	NSURL *url = [NSURL URLWithString:fileUrlString];
	
	// 別のスレッドでファイル読み込みをキューに加える
	NSOperationQueue *queue = [NSOperationQueue new];
	NSInvocationOperation *operation = [[NSInvocationOperation alloc]
										initWithTarget:self
										selector:@selector(loadImage:)
										object:url];
	[queue addOperation:operation];
}
	
	// 別スレッドでファイルを読み込む
- (void)loadImage:(NSURL *)url
{
	NSData* gpxData = [[NSData alloc] initWithContentsOfURL:url];
	
	// 読み込んだらメインスレッドのメソッドを実行
	[self performSelectorOnMainThread:@selector(saveGpx:) withObject:gpxData waitUntilDone:NO];
}
	
	// ローカルにデータを保存
- (void)saveGpx:(NSData *)data
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:downloadGpxFileName];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	BOOL success = [fileManager fileExistsAtPath:dataPath];
	if (success) {
		data = [NSData dataWithContentsOfFile:dataPath];
	} else {
		[data writeToFile:dataPath atomically:YES];
	}
	
	#pragma clang diagnostic ignored "-Wundeclared-selector"
	UIViewController* vc = self.window.rootViewController;
	if([vc respondsToSelector:@selector(preparePlaybackFor:)]) {
		NSString* gpxName = [downloadGpxFileName stringByReplacingOccurrencesOfString:@".gpx" withString:@""];
		[vc performSelector:@selector(preparePlaybackFor:) withObject:gpxName];
	}
}
	
@end
