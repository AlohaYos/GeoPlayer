//
//  GpxManager.h
//  GeoFake
//
//  Created by Yos Hashimoto on 2013/12/28.
//  Copyright (c) 2013年 Newton Japan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Gpx.h"

@interface GpxManager : NSObject

@property (nonatomic,strong)	NSMutableArray	*gpxList;

-(void)loadGpxInfo;

@end
