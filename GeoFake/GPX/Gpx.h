
#import <Foundation/Foundation.h>
#import "GpxItem.h"
#import "GPXCommon.h"
#import "KML.h"
#import <libxml/tree.h>

#define AUTO_SAVE_NAME		@"AutoSave"

@interface Gpx : NSObject

@property (strong, nonatomic)	NSString*		version;
@property (strong, nonatomic)	NSString*		filePath;
@property (strong, nonatomic)	NSString*		fileName;
@property (strong, nonatomic)	NSString*		name;
@property (strong, nonatomic)	NSDate*			timestamp;
@property (assign, nonatomic)	int				currentIndex;
@property (strong, nonatomic)	NSMutableArray*	items;			// GpxItem array


- (id)init;
- (BOOL)loadGpxMeta:(NSString*)fileName;
- (BOOL)loadGpxData:(NSString*)fileName;
- (BOOL)saveGpxData:(NSString*)fileName;
- (BOOL)deleteGpxData:(NSString*)fileName;
- (void)renameAutoSaveFileToTimestampName;

@end
